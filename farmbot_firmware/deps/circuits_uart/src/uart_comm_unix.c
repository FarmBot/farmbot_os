/*
 *  Copyright 2016 Frank Hunleth
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#if defined(__linux__) || defined(__APPLE__)
#include "uart_comm.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/file.h>
#include <time.h>
#include <poll.h>

#ifdef __linux__
#include <linux/serial.h>
#define termios asmtermios
#include <asm/termbits.h>
#undef  termios
#include <asm/ioctls.h>
#endif

#include <termios.h>

#ifdef __APPLE__
#include <IOKit/serial/ioss.h>
#endif

#include "util.h"

struct uart {
    // UART file handle
    int fd;

    // Read handling
    bool active_mode_enabled;

    // Write buffering
    const uint8_t *write_data;
    off_t write_offset;
    size_t write_len;
    uint64_t write_completion_deadline;

    // Read buffer
    bool read_pending;
    uint8_t read_buffer[4096];
    uint64_t read_completion_deadline;

    // Callbacks
    uart_write_completed_callback write_completed;
    uart_read_completed_callback read_completed;
    uart_notify_read notify_read;
};

static const char *last_error = "ok";

const char *uart_last_error()
{
    return last_error;
}

static void record_last_error(int err)
{
    // Convert the last error to an appropriate
    // Erlang atom.
    switch(err) {
    case 0:
        last_error = "ok";
        break;
    case ENOENT:
        last_error = "enoent";
        break;
    case EBADF:
        last_error = "ebadf";
        break;
    case EPERM:
        last_error = "eperm";
        break;
    case EACCES:
        last_error = "eacces";
        break;
    case EAGAIN:
        last_error = "eagain";
        break;
    case ECANCELED:
        last_error = "ecanceled";
        break;
    case EIO:
        last_error = "eio";
        break;
    case EINTR:
        last_error = "eintr";
        break;
    case ENOTTY:
        last_error = "enotty";
        break;
    case EINVAL:
    default:
        debug("Got unexpected error: %d (%s)", err, strerror(err));
        last_error = "einval";
        break;
    }
}

static void record_errno()
{
    record_last_error(errno);
}

static int to_baudrate_constant(int speed)
{
    switch (speed) {
    case 0: return B0;
    case 50: return B50;
    case 75: return B75;
    case 110: return B110;
    case 134: return B134;
    case 150: return B150;
    case 200: return B200;
    case 300: return B300;
    case 600: return B600;
    case 1200: return B1200;
    case 1800: return B1800;
    case 2400: return B2400;
    case 4800: return B4800;
    case 9600: return B9600;
    case 19200: return B19200;
    case 38400: return B38400;
    case 57600: return B57600;
    case 115200: return B115200;
    case 230400: return B230400;
#if defined(__linux__)
    case 460800: return B460800;
    case 500000: return B500000;
    case 576000: return B576000;
    case 921600: return B921600;
    case 1000000: return B1000000;
    case 1152000: return B1152000;
    case 1500000: return B1500000;
    case 2000000: return B2000000;
    case 2500000: return B2500000;
    case 3000000: return B3000000;
    case 3500000: return B3500000;
    case 4000000: return B4000000;
#endif
    default:
        return -1;
    }
}

static int is_custom_speed(int speed)
{
    return to_baudrate_constant(speed) < 0;
}

static int to_databits_constant(int bits)
{
    switch (bits) {
    default:
    case 8: return CS8;
    case 7: return CS7;
    case 6: return CS6;
    case 5: return CS5;
    }
}

static int set_custom_speed(int fd, int speed)
{
#if defined(__linux__)
    struct termios2 serinfo;
    memset(&serinfo, 0, sizeof(serinfo));
    if (ioctl(fd, TCGETS2, &serinfo) < 0)
        return -1;

    serinfo.c_cflag &= ~CBAUD;
    serinfo.c_cflag |= BOTHER;
    serinfo.c_ispeed = speed;
    serinfo.c_ospeed = speed;

    return ioctl(fd, TCSETS2, &serinfo);

#elif defined(__APPLE__)
    // Custom baud rates supported on Tiger and beyond
    // NOTE: Apple appears to be picky. Once setting this, calling
    //       tcsetattr() even with unchanged arguments seems to fail.
    speed_t sio_speed = speed;
    return ioctl(fd,  IOSSIOSPEED, &sio_speed);
#else
    return -1;
#endif
}

static int clear_custom_speed(int fd)
{
#if defined(__linux__)
    struct serial_struct serinfo;
    memset(&serinfo, 0, sizeof(serinfo));
    if (ioctl(fd, TIOCGSERIAL, &serinfo) < 0)
        return -1;

    if (serinfo.flags & ASYNC_SPD_CUST) {
        // If a custom speed had been enabled, clear it out
        serinfo.flags &= ~ASYNC_SPD_MASK;
        serinfo.custom_divisor = 0;

        return ioctl(fd, TIOCSSERIAL, &serinfo);
    }

    return 0;
#elif defined(__APPLE__)
    (void) fd;

    // See comment when setting custom speed. I can't find documentation for this case.
    return -1;
#else
    return -1;
#endif
}


/**
 * @brief Configure the speed, data bits, stop bits and parity for the port
 *
 * @param fd
 * @param config
 * @return <0 on error
 */
static int uart_config_line(int fd, const struct uart_config *config)
{
    struct termios options;
    tcgetattr(fd, &options);

    // Set up the speed
    int baud_constant = to_baudrate_constant(config->speed);
    if (baud_constant >= 0) {
        // Use "known" baudrate
        cfsetispeed(&options, baud_constant);
        cfsetospeed(&options, baud_constant);

        // Clear out any custom speed settings just in case...
        clear_custom_speed(fd);
    } else {
        // Use custom baudrate

#if defined(__linux__)
        // Linux lets you set custom baudrates for the B38400 option
        cfsetispeed(&options, B38400);
        cfsetospeed(&options, B38400);
#endif

        // Custom speed options that don't involve tcsetattr() are
        // done later.
    }

    // Specify data bits
    options.c_cflag &= ~CSIZE;
    options.c_cflag |= to_databits_constant(config->data_bits);

    // Specify stop bits
    if (config->stop_bits == 2)
        options.c_cflag |= CSTOPB;
    else
        options.c_cflag &= ~CSTOPB;

    switch (config->parity)
    {
    case UART_PARITY_NONE:
        options.c_cflag &= ~PARENB;
        break;
    case UART_PARITY_ODD:
        options.c_cflag |= PARENB;
        options.c_cflag |= PARODD;
        break;
    case UART_PARITY_EVEN:
        options.c_cflag |= PARENB;
        options.c_cflag &= ~PARODD;
        break;
#ifdef CMSPAR
    case UART_PARITY_SPACE:
        options.c_cflag &= ~PARODD;
        options.c_cflag |= PARENB | CMSPAR;
        break;
    case UART_PARITY_MARK:
        options.c_cflag |= PARENB | CMSPAR | PARODD;
        break;
#endif
    case UART_PARITY_IGNORE:
        options.c_cflag |= IGNPAR | ISTRIP;
        break;
    default:
        // Other options not supported
        return -1;
    }

    // Force some other settings
    options.c_cflag |= CLOCAL; // Ignore modem control lines
    options.c_cflag |= CREAD;  // Enable receiver
    options.c_oflag = 0;
    options.c_lflag = 0;
    options.c_iflag &= ~(ICRNL|INLCR);  // No CR<->LF conversions

    // It seems like these should be ignored since we
    // open the port as O_NONBLOCK
    options.c_cc[VMIN] = 1;
    options.c_cc[VTIME] = 0;

    // Set everything
    return tcsetattr(fd, TCSANOW, &options);
}

/**
 * @brief Configure the flow control used on the port
 *
 * @param fd
 * @param config
 * @return <0 on error
 */
static int uart_config_flowcontrol(int fd, const struct uart_config *config)
{
    struct termios options;
    if (tcgetattr(fd, &options) < 0)
        return -1;

    switch (config->flow_control) {
    default:
    case UART_FLOWCONTROL_NONE:
        options.c_cflag &= ~CRTSCTS;
        options.c_iflag &= ~(IXON | IXOFF | IXANY);
        break;
    case UART_FLOWCONTROL_HARDWARE:
        options.c_cflag |= CRTSCTS;
        options.c_iflag &= ~(IXON | IXOFF | IXANY);
        break;
    case UART_FLOWCONTROL_SOFTWARE:
        debug("software flow control");
        options.c_cflag &= ~CRTSCTS;
        options.c_iflag |= IXON | IXOFF | IXANY;
        break;
    }

    // Set everything
    return tcsetattr(fd, TCSANOW, &options);
}

static char *name_to_device_file(const char *name)
{
    // If passed "ttyS0", return "/dev/ttyS0".
    // If passed something that looks like a path, return
    // that since the user must know what they're doing.
    if (name[0] == '/' || name[0] == '.') {
        return strdup(name);
    } else {
        char *result;
        if (asprintf(&result, "/dev/%s", name) < 0)
            return NULL;
        else
            return result;
    }
}

int uart_init(struct uart **pport,
              uart_write_completed_callback write_completed,
              uart_read_completed_callback read_completed,
              uart_notify_read notify_read)
{
    struct uart *port = malloc(sizeof(struct uart));
    *pport = port;

    port->fd = -1;
    port->active_mode_enabled = true;
    port->write_data = NULL;
    port->read_pending = false;

    port->write_completed = write_completed;
    port->read_completed = read_completed;
    port->notify_read = notify_read;

    return 0;
}

int uart_open(struct uart *port, const char *name, const struct uart_config *config)
{
    char *uart_path = name_to_device_file(name);
    if (!uart_path) {
        debug("Can't convert '%s' to uart path", name);
        return -1;
    }

    port->fd = open(uart_path, O_RDWR | O_NOCTTY | O_CLOEXEC | O_NONBLOCK);
    free(uart_path);

    port->active_mode_enabled = config->active;

    if (port->fd < 0) {
        debug("open failed on '%s'", name);
        goto handle_error;
    }

    // Lock the serial port for exclusive use (we don't want others messing with it by accident)
    if (flock(port->fd, LOCK_EX | LOCK_NB) < 0) {
        debug("flock failed on '%s'", name);
        goto handle_error;
    }

    if (uart_config_line(port->fd, config) < 0) {
        debug("uart_config_line failed");
        goto handle_error;
    }

    if (uart_config_flowcontrol(port->fd, config) < 0) {
        debug("uart_config_flowcontrol failed");
        goto handle_error;
    }

    if (is_custom_speed(config->speed) &&
            set_custom_speed(port->fd, config->speed) < 0) {
        debug("set_custom_speed failed");
        goto handle_error;
    }

    // Clear garbage data from RX/TX queues
    tcflush(port->fd, TCIOFLUSH);

    return 0;

handle_error:
    record_errno();

    if (port->fd >= 0)
        close(port->fd);
    port->fd = -1;
    return -1;
}

int uart_is_open(struct uart *port)
{
    return port->fd != -1;
}

int uart_configure(struct uart *port, const struct uart_config *config)
{
    // Update active mode
    if (config->active != port->active_mode_enabled) {
        if (port->read_pending)
            errx(EXIT_FAILURE, "Elixir is supposed to queue read ops");

        port->active_mode_enabled = config->active;
    }

    // Updating closed ports is easy.
    if (port->fd < 0)
        return 0;

    if (uart_config_line(port->fd, config) < 0) {
        debug("uart_config_line failed");
        record_errno();
        return -1;
    }

    if (uart_config_flowcontrol(port->fd, config) < 0) {
        debug("uart_config_flowcontrol failed");
        record_errno();
        return -1;
    }

    return 0;
}

/**
 * @brief Called internally when an unrecoverable error makes the port unusable
 * @param port
 */
static void uart_close_on_error(struct uart *port, int reason)
{
    debug("uart_close_on_error %d, %d", port->fd, reason);
    uart_close(port);

    // If active mode, notify that the failure occurred.
    // NOTE: This isn't done in uart_close, since if the user
    //       is closing the port, they don't need an event telling
    //       them that something happened.
    if (port->active_mode_enabled) {
        record_last_error(reason);
        port->notify_read(reason, NULL, 0);
    }
}

int uart_close(struct uart *port)
{
    // Cancel any pending data to be written.
    if (port->write_data) {
        record_last_error(ECANCELED);
        (port->write_completed)(-1, port->write_data);

        port->write_data = NULL;
    }

    // Cancel any pending reads
    if (port->read_pending) {
        record_last_error(ECANCELED);
        port->read_completed(-1, NULL, 0);

        port->read_pending = false;
    }

    close(port->fd);
    port->fd = -1;
    return 0;
}

void uart_write(struct uart *port, const uint8_t *data, size_t len, int timeout)
{
    if (port->write_data)
        errx(EXIT_FAILURE, "Implement write queuing in Elixir!");

    ssize_t written;
    do {
        written = write(port->fd, data, len);
        debug("uart_write: wrote %d/%d, errno=%d (%s) data=%p, fd=%d",
                (int) written,
                (int) len,
                written < 0 ? errno : 0, /* errno only set on error */
                strerror(written < 0 ? errno : 0),
                data,
                port->fd);
    } while (written < 0 && errno == EINTR);

    if (written < 0) {
         if (errno == EAGAIN && timeout != 0) {
             // Try again later
             port->write_data = data;
             port->write_len = len;
             port->write_offset = 0;
             port->write_completion_deadline = current_time() + (timeout < 0 ? ONE_YEAR_MILLIS : (uint64_t) timeout);
         } else {
             // Unrecoverable error
             int reason = errno;
             record_errno();
             port->write_completed(-1, data);

             uart_close_on_error(port, reason);
         }
    } else {
        if (written != (ssize_t) len) {
            // Partially written

            if (timeout != 0) {
                // Write the rest later
                port->write_data = data;
                port->write_len = len;
                port->write_offset = written;
                port->write_completion_deadline = current_time() + (timeout < 0 ? ONE_YEAR_MILLIS : (uint64_t) timeout);
            } else {
                // Timed out. :(
                record_last_error(EAGAIN);
                port->write_completed(-1, data); // Currently no way to tell Elixir code the amount that was written
            }
        } else {
            // Fully written.
            port->write_completed(0, data);
        }
    }
}

static void continue_in_progress_write(struct uart *port)
{
    size_t to_write = port->write_len - port->write_offset;
    ssize_t written;
    do {
        written = write(port->fd, &port->write_data + port->write_offset, to_write);
        debug("continue_in_progress_write: wrote %d/%d, errno=%d (%s)", (int) written, (int) to_write, errno, strerror(errno));
    } while (written < 0 && errno == EINTR);

    if (written == (ssize_t) to_write) {
        // Fully written.
        const uint8_t *data = port->write_data;
        port->write_data = NULL;
        port->write_completed(0, data);
        return;
    } else if (written < 0) {
         if (errno != EAGAIN) {
             // Unrecoverable error
             const uint8_t *data = port->write_data;
             port->write_data = NULL;

             int reason = errno;
             record_errno();
             port->write_completed(-1, data);

             uart_close_on_error(port, reason);
             return;
         }
    } else {
        // Partially written. Need to try again later.
        port->write_offset += written;
    }

    // The write is still outstanding, check the timeout
    uint64_t time_to_wait = port->write_completion_deadline - current_time();
    if (time_to_wait == 0 || time_to_wait > ONE_YEAR_MILLIS) {
        // Handle timeout.
        const uint8_t *data = port->write_data;
        port->write_data = NULL;
        record_last_error(EAGAIN);
        port->write_completed(-1, data); // Currently no way to tell Elixir code the amount that was written
    }
}

void uart_read(struct uart *port, int timeout)
{
    if (port->active_mode_enabled) {
        debug("don't call read when in active mode");
        record_last_error(EINVAL);
        port->read_completed(-1, NULL, 0);
        return;
    }

    if (port->read_pending)
        errx(EXIT_FAILURE, "Implement read queuing in Elixir");

    ssize_t bytes_read;
    do {
        bytes_read = read(port->fd, port->read_buffer, sizeof(port->read_buffer));
    } while(bytes_read < 0 && errno == EINTR);

    if (bytes_read > 0) {
        // Read complete.
        port->read_completed(0, port->read_buffer, bytes_read);
    } else if (bytes_read == 0 || (bytes_read < 0 && errno == EAGAIN)) {
        if (timeout == 0) {
            // Nothing read, but that's ok.
            port->read_completed(0, NULL, 0);
        } else {
            // Need to wait.
            port->read_pending = true;
            port->read_completion_deadline = current_time() + (timeout < 0 ? ONE_YEAR_MILLIS : (uint64_t) timeout);
        }
    } else {
        // Unrecoverable error
        int reason = errno;
        record_errno();
        port->read_completed(-1, NULL, 0);

        // No recovery - close socket
        uart_close_on_error(port, reason);
    }
}

static void process_read(struct uart *port)
{
    ssize_t bytes_read;
    do {
        bytes_read = read(port->fd, port->read_buffer, sizeof(port->read_buffer));
    } while(bytes_read < 0 && errno == EINTR);

    if (bytes_read > 0) {
        // Read complete.
        if (port->active_mode_enabled) {
            // Active mode report
            port->notify_read(0, port->read_buffer, bytes_read);
        } else {
            // The pending read finished
            port->read_pending = false;
            port->read_completed(0, port->read_buffer, bytes_read);
        }
    } else if (bytes_read < 0 && errno == EAGAIN) {
        // No data this time.

        if (port->read_pending) {
            // Check the deadline if waiting
            uint64_t time_to_wait = port->read_completion_deadline - current_time();
            if (time_to_wait == 0 || time_to_wait > ONE_YEAR_MILLIS) { /* subtraction wrapped */
                // Handle timeout.
                port->read_pending = false;
                port->read_completed(0, NULL, 0);
            }
        }
    } else {
        // Either EOF (bytes_read == 0) or some other error (errno)
        // Both are unrecoverable.
        int reason = (bytes_read == 0 ? EIO : errno);
        if (port->read_pending) {
            port->read_pending = false;
            record_errno();
            port->read_completed(-1, NULL, 0);
        }
        uart_close_on_error(port, reason);
    }
}

int uart_drain(struct uart *port)
{
    // NOTE: This is pretty easy to support if allowed by the Elixir GenServer,
    //       but I can't think of a use case.
    if (port->write_data)
        errx(EXIT_FAILURE, "Elixir is supposed to queue write operations");

    // Wait until everything has been transmitted
    if (tcdrain(port->fd) < 0) {
        record_errno();
        return -1;
    }

    return 0;
}

int uart_flush(struct uart *port, enum uart_direction direction)
{
    // NOTE: This could be supported if allowed by the Elixir GenServer.
    //       Not sure on the use case, though.
    if (port->read_pending)
        errx(EXIT_FAILURE, "Elixir is supposed to queue read operations");

    int queue;
    switch (direction) {
    case UART_DIRECTION_RECEIVE:
        queue = TCIFLUSH;
        break;

    case UART_DIRECTION_TRANSMIT:
        queue = TCOFLUSH;
        break;

    case UART_DIRECTION_BOTH:
    default:
        queue = TCIOFLUSH;
        break;
    }

    // Clear out the selected queue(s)
    if (tcflush(port->fd, queue) < 0) {
        record_errno();
        return -1;
    }

    return 0;
}

int uart_flush_all(struct uart *port)
{
    // This is currently only called on an unexpected exit
    tcflush(port->fd, TCIOFLUSH);
    return 0;
}

int uart_set_rts(struct uart *port, bool val)
{
    int status = TIOCM_RTS;
    if (ioctl(port->fd, val ? TIOCMBIS : TIOCMBIC, &status) < 0) {
        record_errno();
        return -1;
    }

    return 0;
}

int uart_set_dtr(struct uart *port, bool val)
{
    int status = TIOCM_DTR;
    if (ioctl(port->fd, val ? TIOCMBIS : TIOCMBIC, &status) < 0) {
        record_errno();
        return -1;
    }

    return 0;
}

int uart_set_break(struct uart *port, bool val)
{
    if (ioctl(port->fd, val ? TIOCSBRK : TIOCCBRK) < 0) {
        record_errno();
        return -1;
    }

    return 0;
}

int uart_get_signals(struct uart *port, struct uart_signals *sig)
{
    int status;
    if (ioctl(port->fd, TIOCMGET, &status) == -1) {
        record_errno();
        return -1;
    }

    sig->dsr = ((status & (TIOCM_LE | TIOCM_DSR)) != 0);
    sig->dtr = ((status & TIOCM_DTR) != 0);
    sig->rts = ((status & TIOCM_RTS) != 0);
    sig->st = ((status & TIOCM_ST) != 0);
    sig->sr = ((status & TIOCM_SR) != 0);
    sig->cts = ((status & TIOCM_CTS) != 0);
    sig->cd = ((status & (TIOCM_CAR | TIOCM_CD)) != 0);
    sig->rng = ((status & (TIOCM_RNG | TIOCM_RI)) != 0);

    return 0;
}

/**
 * @brief Update the poll timeout based on the specified deadline
 */
static void update_timeout(uint64_t deadline, int *timeout)
{
    uint64_t time_to_wait = deadline - current_time();
    if (time_to_wait > ONE_YEAR_MILLIS) {
        // We're already late. Force poll() to return immediately. Maybe the
        // system will be ready?
        *timeout = 0;
    } else if (time_to_wait > INT32_MAX) {
        // If the time to wait is over 24 days, wait forever.
        // (This means that we don't need to lower the current timeout.)
    } else {
        int our_timeout = (int) time_to_wait;
        if (*timeout < 0 || our_timeout < *timeout)
            *timeout = our_timeout;
    }
}

int uart_add_poll_events(struct uart *port, struct pollfd *fdset, int *timeout)
{
    int count = 0;
    fdset->fd = port->fd;
    fdset->events = 0;
    fdset->revents = 0;

    // Writes...
    if (port->write_data) {
        update_timeout(port->write_completion_deadline, timeout);
        fdset->events = POLLOUT;
        count = 1;
    }

    // Reads...
    if (port->read_pending) {
        // Figure out how long to wait before timing out the
        // read operation.
        update_timeout(port->read_completion_deadline, timeout);
        fdset->events |= POLLIN;
        count = 1;
    } else if (port->active_mode_enabled) {
        // In active mode, we wait forever for bytes to be received
        fdset->events |= POLLIN;
        count = 1;
    }
    return count;
}

void uart_process(struct uart *port, const struct pollfd *fdset)
{
    (void) fdset;
    if (port->fd < 0)
        return;

    // Handle writes
    if (port->write_data) {

        // Indiscriminately try again to catch errors that don't
        // signal POLLOUT.
        continue_in_progress_write(port);
    }

    // Handle reads
    if (port->active_mode_enabled || port->read_pending) {
        process_read(port);
    }
}

#endif
