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

#ifdef __WIN32__
#include "uart_comm.h"
#include "util.h"

#include <windows.h>
#include <stdio.h>

/*
 * Serial I/O on Windows Notes
 *
 * The goal for circuits_uart is to be able to poll the serial ports
 * using WaitForMultipleObjects. This means that overlapped I/O or
 * other asynchronous I/O needs to be used.
 *
 * The tricky part seems to be dealing with receive timeouts. See
 * SetCommTimeouts(). The catch is that ReadFile is terminated
 * when either the timeout occurs OR the buffer is filled. This
 * is different from Unix where read() returns as soon as there's
 * anything to return. This means that you have to either call
 * ReadFile with a 1 byte buffer repeatedly or find another way.
 * WaitCommEvent lets you get an event when a byte is in the
 * receive buffer (EV_RXCHAR).
 *
 * The receive code works below by using WaitCommEvent asynchronously
 * to figure out when to call ReadFile synchronously. The timeout
 * for ReadFile is set to return immediately. This lets us read
 * everything in the input buffer in one call while still being
 * asynchronous.
 */
struct uart {
    // UART file handle
    HANDLE h;

    // Read handling
    bool active_mode_enabled;
    OVERLAPPED read_overlapped;
    uint64_t read_completion_deadline;

    OVERLAPPED events_overlapped;
    DWORD desired_event_mask;
    DWORD received_event_mask;

    bool read_pending;

    uint8_t read_buffer[4096];

    // Write handling
    int current_write_timeout;
    OVERLAPPED write_overlapped;
    const uint8_t *write_data;

    // DCB state handling
    DCB dcb;

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
    // Convert the Windows last error to an appropriate
    // Erlang atom.
    switch(err) {
    case NO_ERROR:
        last_error = "ok";
        break;
    case ERROR_FILE_NOT_FOUND:
        last_error = "enoent";
        break;
    case ERROR_INVALID_HANDLE:
        last_error = "ebadf";
        break;
    case ERROR_ACCESS_DENIED:
        last_error = "eacces";
        break;
    case ERROR_OPERATION_ABORTED:
        last_error = "eagain";
        break;
    case ERROR_CANCELLED:
        last_error = "ecanceled"; // Spelled with one 'l' in Linux
        break;
    case ERROR_INVALID_PARAMETER:
    default:
        last_error = "einval";
        break;
    }
}

static void record_errno()
{
    record_last_error(GetLastError());
}

static BYTE to_windows_parity(enum uart_parity parity)
{
    switch(parity) {
    default:
    case UART_PARITY_NONE:  return NOPARITY;
    case UART_PARITY_MARK:  return MARKPARITY;
    case UART_PARITY_EVEN:  return EVENPARITY;
    case UART_PARITY_ODD:   return ODDPARITY;
    case UART_PARITY_SPACE: return SPACEPARITY;
    }
}

static BYTE to_windows_stopbits(int stop_bits)
{
    if (stop_bits == 2)
        return TWOSTOPBITS;
    else
        return ONESTOPBIT;
}

int uart_init(struct uart **pport,
              uart_write_completed_callback write_completed,
              uart_read_completed_callback read_completed,
              uart_notify_read notify_read)
{
    struct uart *port = malloc(sizeof(struct uart));
    *pport = port;

    memset(port, 0, sizeof(struct uart));
    port->h = INVALID_HANDLE_VALUE;
    port->active_mode_enabled = true;
    port->write_data = NULL;
    port->read_pending = false;

    port->write_completed = write_completed;
    port->read_completed = read_completed;
    port->notify_read = notify_read;

    // Create the overlapped I/O events that will be needed
    // once the device has been opened.
    port->read_overlapped.hEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    if (port->read_overlapped.hEvent == NULL) {
        record_errno();
        return -1;
    }
    port->read_overlapped.Offset = 0;
    port->read_overlapped.OffsetHigh = 0;

    port->write_overlapped.hEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    if (port->write_overlapped.hEvent == NULL) {
        record_errno();
        return -1;
    }
    port->write_overlapped.Offset = 0;
    port->write_overlapped.OffsetHigh = 0;

    port->events_overlapped.hEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    if (port->events_overlapped.hEvent == NULL) {
        record_errno();
        return -1;
    }
    port->events_overlapped.Offset = 0;
    port->events_overlapped.OffsetHigh = 0;

    return 0;
}

static int update_write_timeout(struct uart *port, int timeout)
{
    COMMTIMEOUTS timeouts;

    // Set the timeouts to not block on reads

    // Per Microsoft documentation on read timeouts:
    //
    // A value of MAXDWORD, combined with zero values for both the
    // ReadTotalTimeoutConstant and ReadTotalTimeoutMultiplier members,
    // specifies that the read operation is to return immediately with the
    // bytes that have already been received, even if no bytes have been
    // received.
    timeouts.ReadIntervalTimeout = MAXDWORD;
    timeouts.ReadTotalTimeoutMultiplier = 0;
    timeouts.ReadTotalTimeoutConstant = 0;

    if (timeout == 0) {
        // Don't block

        // This doesn't seem like a useful case, but handle it for completeness
        // by giving the shortest possible timeout.
        timeouts.WriteTotalTimeoutConstant = 1;
        timeouts.WriteTotalTimeoutMultiplier = 0;
    } else if (timeout < 0) {
        // A value of zero for both the WriteTotalTimeoutMultiplier and
        // WriteTotalTimeoutConstant members indicates that total time-outs are not
        // used for write operations.
        timeouts.WriteTotalTimeoutConstant = 0;
        timeouts.WriteTotalTimeoutMultiplier = 0;
    } else {
        // Block for the specified time
        timeouts.WriteTotalTimeoutConstant = timeout;
        timeouts.WriteTotalTimeoutMultiplier = 0;
    }

    if (!SetCommTimeouts(port->h, &timeouts)) {
        debug("SetCommTimeouts failed");
        record_errno();
        return -1;
    } else {
        port->current_write_timeout = timeout;
        return 0;
    }
}

static int uart_init_dcb(struct uart *port)
{
    port->dcb.DCBlength = sizeof(DCB);
    if (!GetCommState(port->h, &port->dcb)) {
        debug("GetCommState failed");
        record_errno();
        return -1;
    }

    // Force some fields to known states.
    port->dcb.fRtsControl = RTS_CONTROL_ENABLE;
    port->dcb.fDtrControl = DTR_CONTROL_DISABLE;
    port->dcb.fBinary = TRUE;

    // The rest of the fields will be set in
    // calls to uart_config_line.
    return 0;
}

static int uart_config_line(struct uart *port, const struct uart_config *config)
{
    // Note:
    //  dcb.fRtsControl and dcb.fDtrControl are not modified unless switching
    //  away from hardware flow control. Cached versions
    //  of their current state are stored here so that they may be returned
    //  without making a system call. This also means that the SetCommState
    //  call will receive the RTS and DTR state that the user expects. The
    //  Microsoft docs imply that these fields are only used when the device is
    //  opened, but that doesn't make sense to me, since you have to open
    //  the device to call SetCommState. Additionally, getting the RTS and DTR
    //  states from Windows requires overlapped I/O (since we opened the handled
    //  that way). Using cached results is so much easier. The case this breaks
    //  is if the user wants to know what hardware flowcontrol is doing. This
    //  seems like a debug case that is more easily satisfied with a scope.
    port->dcb.BaudRate = config->speed;
    port->dcb.Parity = to_windows_parity(config->parity);
    port->dcb.ByteSize = config->data_bits;
    port->dcb.StopBits = to_windows_stopbits(config->stop_bits);

    port->dcb.fInX = FALSE;
    port->dcb.fOutX = FALSE;
    port->dcb.fOutxDsrFlow = FALSE;
    port->dcb.fOutxCtsFlow = FALSE;

    if (port->dcb.fRtsControl == RTS_CONTROL_HANDSHAKE)
        port->dcb.fRtsControl = RTS_CONTROL_ENABLE;

    switch (config->flow_control) {
    default:
    case UART_FLOWCONTROL_NONE:
        break;
    case UART_FLOWCONTROL_SOFTWARE:
        port->dcb.fInX = TRUE;
        port->dcb.fOutX = TRUE;
        break;
    case UART_FLOWCONTROL_HARDWARE:
        port->dcb.fOutxCtsFlow = TRUE;
        port->dcb.fRtsControl = RTS_CONTROL_HANDSHAKE;
        break;
    }

    if (!SetCommState(port->h, &port->dcb)) {
        record_errno();
        return -1;
    }
    return 0;
}

static int start_async_reads(struct uart *port) {
    debug("Starting async read");
    BOOL rc = WaitCommEvent(
                port->h,
                &port->received_event_mask,
                &port->events_overlapped);
    if (rc) {
        debug("WaitCommEvent returned synchronously");
    } else if (GetLastError() != ERROR_IO_PENDING) {
        debug("start_async_reads WaitCommEvent failed?? %d", (int) GetLastError());
        record_errno();
        return -1;
    } else {
        debug("WaitCommEvent returned asynchronously");
    }

    return 0;
}

int uart_open(struct uart *port, const char *name, const struct uart_config *config)
{
    // If the port is open, close it and re-open it.
    uart_close(port);

    // name is "COM1", etc. We need "\\.\COM1", so prepend the "\\.\"
#define COM_PORT_PREFIX         "\\\\.\\"
    int namelen = strlen(name);
    char windows_port_path[namelen + sizeof(COM_PORT_PREFIX) + 1];
    sprintf(windows_port_path, COM_PORT_PREFIX "%s", name);

    port->h = CreateFileA(windows_port_path,
                          GENERIC_READ | GENERIC_WRITE,
                          0, // sharing not allowed on Windows
                          NULL,
                          OPEN_EXISTING,
                          FILE_ATTRIBUTE_NORMAL | FILE_FLAG_OVERLAPPED,
                          NULL);

    port->active_mode_enabled = config->active;

    if (port->h == INVALID_HANDLE_VALUE) {
        record_errno();
        return -1;
    }

    if (uart_init_dcb(port) < 0 ||
            uart_config_line(port, config) < 0) {
        CloseHandle(port->h);
        port->h = INVALID_HANDLE_VALUE;
        return -1;
    }

    // Reset timeouts to wait forever
    update_write_timeout(port, -1);

    // Remove garbage data in RX/TX queues
    PurgeComm(port->h, PURGE_RXCLEAR | PURGE_TXCLEAR);

    // TODO: Watch for comm events: (break, CTS changed, DSR changed, err, ring, rlsd)
    port->desired_event_mask = EV_RXCHAR;
    if (!SetCommMask(port->h, port->desired_event_mask)) {
        debug("SetCommMask failed? %d", (int) GetLastError());
        record_errno();
        CloseHandle(port->h);
        port->h = INVALID_HANDLE_VALUE;
        return -1;
    }

    // Reset all events like they would be if we just created them.
    ResetEvent(port->events_overlapped.hEvent);
    ResetEvent(port->write_overlapped.hEvent);
    ResetEvent(port->read_overlapped.hEvent);

    if (port->active_mode_enabled && start_async_reads(port) < 0) {
        CloseHandle(port->h);
        port->h = INVALID_HANDLE_VALUE;
        return -1;
    }

    return 0;
}

int uart_is_open(struct uart *port)
{
    return port->h != INVALID_HANDLE_VALUE;
}

int uart_configure(struct uart *port, const struct uart_config *config)
{
    bool active_mode_changed = false;
    if (config->active != port->active_mode_enabled) {
      port->active_mode_enabled = config->active;
      active_mode_changed = true;
    }

    // Updating closed ports is easy.
    if (port->h == INVALID_HANDLE_VALUE)
        return 0;

    // Update active mode
    if (active_mode_changed) {
        if (port->read_pending)
            errx(EXIT_FAILURE, "Elixir is supposed to queue read ops");

        port->active_mode_enabled = config->active;
        if (port->active_mode_enabled) {
            port->desired_event_mask |= EV_RXCHAR;
            if (!SetCommMask(port->h, port->desired_event_mask))
                errx(EXIT_FAILURE, "uart_configure: SetCommMask failure unexpected: 0x%08x, Error=%d", (int) port->desired_event_mask, (int) GetLastError());

            if (start_async_reads(port) < 0) {
                CloseHandle(port->h);
                port->h = INVALID_HANDLE_VALUE;
                return -1;
            }
        } else {
            port->desired_event_mask &= ~EV_RXCHAR;
            if (!SetCommMask(port->h, port->desired_event_mask))
                errx(EXIT_FAILURE, "uart_configure: SetCommMask failure unexpected: 0x%08x, Error=%d", (int) port->desired_event_mask, (int) GetLastError());
        }
    }

    if (uart_config_line(port, config) < 0) {
        debug("uart_config_line failed");
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
    if (port->h == INVALID_HANDLE_VALUE)
        return 0;

    // Cancel any pending reads or writes
    PurgeComm(port->h, PURGE_RXABORT | PURGE_TXABORT);

    // Cancel any pending data to be written.
    if (port->write_data) {
        record_last_error(ERROR_CANCELLED);
        (port->write_completed)(-1, port->write_data);

        port->write_data = NULL;
    }

    // Cancel any pending reads
    if (port->read_pending) {
        record_last_error(ERROR_CANCELLED);
        port->read_completed(-1, NULL, 0);

        port->read_pending = false;
    }

    CloseHandle(port->h);
    port->h = INVALID_HANDLE_VALUE;
    return 0;
}

void uart_write(struct uart *port, const uint8_t *data, size_t len, int timeout)
{
    if (port->write_data)
        errx(EXIT_FAILURE, "Implement write queuing in Elixir!");

    if (port->current_write_timeout != timeout) {
        if (update_write_timeout(port, timeout) < 0) {
            warnx("uart_write() update_timeouts failed?");
            port->write_completed(-1, data);
            return;
        }
    }

    port->write_data = data;

    debug("Going to write %d bytes", (int) len);
    if (WriteFile(port->h,
                  data,
                  len,
                  NULL,
                  &port->write_overlapped)) {
        debug("WriteFile synchronous completion signalled.");
        // Based on trial and error, the proper handling here is the same as
        // the asynchronous completion case that we'd expect.
    } else if (GetLastError() != ERROR_IO_PENDING) {
        debug("WriteFile failed %d", (int) GetLastError());
        record_errno();
        port->write_completed(-1, data);
    } else {
        debug("WriteFile asynchronous completion");
    }
}

void uart_read(struct uart *port, int timeout)
{
    debug("uart_read");
    if (port->active_mode_enabled) {
        debug("don't call read when in active mode");
        record_last_error(ERROR_INVALID_PARAMETER);
        port->read_completed(-1, NULL, 0);
        return;
    }

    if (port->read_pending)
        errx(EXIT_FAILURE, "Implement read queuing in Elixir");

    port->read_pending = true;
    port->read_completion_deadline = current_time() + (timeout < 0 ? ONE_YEAR_MILLIS : (uint64_t) timeout);

    if (! (port->desired_event_mask & EV_RXCHAR)) {
        port->desired_event_mask |= EV_RXCHAR;
        if (!SetCommMask(port->h, port->desired_event_mask))
            errx(EXIT_FAILURE, "uart_read: SetCommMask failure unexpected: 0x%08x, Error=%d", (int) port->desired_event_mask, (int) GetLastError());
    }

    if (start_async_reads(port) < 0) {
        port->read_pending = false;
        port->read_completed(-1, NULL, 0);
    }
}

int uart_drain(struct uart *port)
{
    // NOTE: This is pretty easy to support if allowed by the Elixir GenServer,
    //       but I can't think of a use case.
    if (port->write_data)
        errx(EXIT_FAILURE, "Elixir is supposed to queue write operations");

    // TODO: wait for everything to be transmitted...
    //  How is this done on Windows???
    return 0;
}

int uart_flush(struct uart *port, enum uart_direction direction)
{
    // NOTE: This could be supported if allowed by the Elixir GenServer.
    //       Not sure on the use case, though.
    if (port->read_pending)
        errx(EXIT_FAILURE, "Elixir is supposed to queue read operations");

    DWORD flags;
    switch (direction) {
    case UART_DIRECTION_RECEIVE:
        flags = PURGE_RXCLEAR;
        break;

    case UART_DIRECTION_TRANSMIT:
        flags = PURGE_TXCLEAR;
        break;

    case UART_DIRECTION_BOTH:
    default:
        flags = PURGE_RXCLEAR | PURGE_TXCLEAR;
        break;
    }

    // Clear out the queue(s)
    PurgeComm(port->h, flags);
    return 0;
}

int uart_set_rts(struct uart *port, bool val)
{
    DWORD func;
    if (val) {
        func = SETRTS;
        port->dcb.fRtsControl = RTS_CONTROL_ENABLE; // Cache state
    } else {
        func = CLRRTS;
        port->dcb.fRtsControl = RTS_CONTROL_DISABLE;
    }
    if (!EscapeCommFunction(port->h, func)) {
        debug("EscapeCommFunction(SETRTS/CLRRTS) failed %d", (int) GetLastError());
        record_errno();
        return -1;
    }

    return 0;
}

int uart_set_dtr(struct uart *port, bool val)
{
    DWORD func;
    if (val) {
        func = SETDTR;
        port->dcb.fDtrControl = DTR_CONTROL_ENABLE; // Cache state
    } else {
        func = CLRDTR;
        port->dcb.fDtrControl = DTR_CONTROL_DISABLE;
    }
    if (!EscapeCommFunction(port->h, func)) {
        debug("EscapeCommFunction(SETDTR/CLRDTR) failed %d", (int) GetLastError());
        record_errno();
        return -1;
    }

    return 0;
}

int uart_set_break(struct uart *port, bool val)
{
    BOOL rc;
    if (val)
        rc = SetCommBreak(port->h);
    else
        rc = ClearCommBreak(port->h);

    if (!rc) {
        debug("SendCommBreak or ClearCommBreak failed %d", (int) GetLastError());
        record_errno();
        return -1;
    }

    return 0;
}

int uart_get_signals(struct uart *port, struct uart_signals *sig)
{
    DWORD modem_status;
    if (!GetCommModemStatus(port->h, &modem_status)) {
        debug("GetCommModemStatus failed %d", (int) GetLastError());
        record_errno();
        return -1;
    }

    sig->dsr = ((modem_status & MS_DSR_ON) != 0);
    sig->dtr = (port->dcb.fDtrControl == DTR_CONTROL_ENABLE);
    sig->rts = (port->dcb.fRtsControl == RTS_CONTROL_ENABLE);
    sig->st = false; // Not supported on Windows
    sig->sr = false; // Not supported on Windows
    sig->cts = ((modem_status & MS_CTS_ON) != 0);
    sig->cd = ((modem_status & MS_RLSD_ON) != 0);
    sig->rng = ((modem_status & MS_RING_ON) != 0);

    return 0;
}

int uart_flush_all(struct uart *port)
{
    // This is currently only called on an unexpected exit
    PurgeComm(port->h, PURGE_RXABORT | PURGE_RXCLEAR | PURGE_TXABORT | PURGE_TXCLEAR);
    return 0;
}

/**
 * @brief Update the poll timeout based on the specified deadline
 */
static void update_timeout(uint64_t deadline, DWORD *timeout)
{
    uint64_t time_to_wait = deadline - current_time();
    if (time_to_wait > ONE_YEAR_MILLIS) {
        // We're already late. Force poll() to return immediately. Maybe the
        // system will be ready?
        *timeout = 0;
    } else if (time_to_wait > MAXDWORD) {
        // If the time to wait is over 24 days, wait forever.
        // (This means that we don't need to lower the current timeout.)
    } else {
        DWORD our_timeout = (DWORD) time_to_wait;
        if (our_timeout < *timeout)
            *timeout = our_timeout;
    }
}

int uart_add_wfmo_handles(struct uart *port, HANDLE *handles, DWORD *timeout)
{
    debug("uart_add_wfmo_handles");
    int count = 0;
    // Check if a file handle is open and waiting
    if (port->h) {
        if (port->write_data) {
            debug("  adding write handle");
            handles[count] = port->write_overlapped.hEvent;
            count++;
        }
        if (port->read_pending) {
            debug("  adding read handle (passive mode)");
            update_timeout(port->read_completion_deadline, timeout);
            handles[count] = port->events_overlapped.hEvent;
            count++;
        } else if (port->active_mode_enabled) {
            debug("  adding read handle (active mode)");
            handles[count] = port->events_overlapped.hEvent;
            count++;
        }
    }
    return count;
}

void uart_process_handle(struct uart *port, HANDLE *event)
{
    if (event == port->write_overlapped.hEvent) {
        debug("uart_process_handle: write event");
        if (port->write_data) {
            ResetEvent(port->write_overlapped.hEvent);
            DWORD bytes_written;
            BOOL rc = GetOverlappedResult(port->h, &port->write_overlapped, &bytes_written, FALSE);
            DWORD last_error = GetLastError();

            debug("Back from write %d, %d", (int) rc, (int) last_error);
            if (rc || last_error != ERROR_IO_INCOMPLETE) {
                record_last_error(last_error);
                const uint8_t *data = port->write_data;
                port->write_data = NULL;
                port->write_completed(rc ? 0 : -1, data);
            }
        }
    }
    if (event == port->events_overlapped.hEvent) {
        debug("uart_process_handle: event event");
        ResetEvent(port->events_overlapped.hEvent);
        if (port->read_pending || port->active_mode_enabled) {
            DWORD amount_read;
            BOOL rc = GetOverlappedResult(port->h, &port->events_overlapped, &amount_read, FALSE);
            DWORD last_error = rc ? NO_ERROR : GetLastError();
            debug("Got an events event: %d %d %d!!", rc, (int) last_error, (int) amount_read);

            // If still incomplete, try again later.
            // TODO: Clean up next line
            if (last_error == ERROR_IO_INCOMPLETE) {
                debug("incomplete -> trying again");
                return;
            }

            if (rc) {
                // Replace line below when supporting hw line events in addition
                // to EV_RXCHAR.
                if (!(port->received_event_mask & EV_RXCHAR)) {
                    debug("unhandled received event: 0x%08x", port->received_event_mask);
                    if (port->active_mode_enabled)
                        start_async_reads(port);

                    return;
                }

                rc = ReadFile(port->h, port->read_buffer, sizeof(port->read_buffer), &amount_read, &port->read_overlapped);
                debug("ReadFile returned: %d %d %d!!", rc, (int) GetLastError(), (int) amount_read);

                if (rc) {
                    // Synchronouse return
#ifdef DEBUG
                    if (amount_read) {
                        port->read_buffer[amount_read] = 0;
                        debug("  sync read %d bytes: %s", (int) amount_read, port->read_buffer);
                    }
#endif
                    last_error = NO_ERROR;
                } else {
                    // This case seems to occur more with passive mode reads.
                    last_error = GetLastError();
                    if (last_error == ERROR_IO_PENDING) {
                        // Bytes were notified. They should come real soon now.
                        WaitForSingleObject(port->read_overlapped.hEvent, 100);
                        ResetEvent(port->read_overlapped.hEvent);
                        rc = GetOverlappedResult(port->h, &port->read_overlapped, &amount_read, FALSE);
                        debug("ReadFile result: %d %d %d!!", rc, (int) GetLastError(), (int) amount_read);
#ifdef DEBUG
                        if (amount_read) {
                            port->read_buffer[amount_read] = 0;
                            debug("  async read %d bytes: %s", (int) amount_read, port->read_buffer);
                        }
#endif
                        last_error = rc ? NO_ERROR : GetLastError();
                    } else {
                        // Unrecoverable error
                        debug("Unrecoverable error on ReadFile: %d", (int) GetLastError());
                        uart_close_on_error(port, last_error);
                        return;
                    }
                }
            } else {
                // Unrecoverable error
                debug("Unrecoverable error on event: %d", (int) GetLastError());
                uart_close_on_error(port, last_error);
                return;
            }
            record_last_error(last_error);

            if (port->active_mode_enabled) {
                // Active mode: notify input and start listening again
                port->notify_read(last_error, port->read_buffer, amount_read);
                if (rc)
                    start_async_reads(port);
            } else {
                // Passive mode: notify result
                if (port->read_pending) {
                    port->read_pending = false;
                    port->read_completed(rc ? 0 : -1, port->read_buffer, amount_read);
                }
            }
        }
    }
}

void uart_process_timeout(struct uart *port)
{
    // Timeouts only apply to synchronous reads
    if (!port->read_pending)
        return;

    uint64_t time_to_wait = port->read_completion_deadline - current_time();
    if (time_to_wait == 0 || time_to_wait > ONE_YEAR_MILLIS) { /* subtraction wrapped */
        // Handle timeout.

        // Stop waiting for RXCHAR events
        port->desired_event_mask &= ~EV_RXCHAR;
        if (!SetCommMask(port->h, port->desired_event_mask))
            errx(EXIT_FAILURE, "uart_process_timeout: SetCommMask failure unexpected: 0x%08x, Error=%d", (int) port->desired_event_mask, (int) GetLastError());

        // The Windows doc says that changing the CommMask will cause pending
        // overlapped ops to return immediately. Things should be set up so
        // that we don't need to call GetOverlappedResult here, and if the overlapped
        // result happens, we should be able to ignore transients anyway...
        //DWORD ignored;
        //rc = GetOverlappedResult(port->h, &port->events_overlapped, &ignored, FALSE);
        //debug("Cancel read: GetOverlappedResult: %d %d", rc, (int) GetLastError());

        // Clearing the event doesn't seem to be needed.
        //ResetEvent(port->events_overlapped.hEvent);

        // Report the timeout
        port->read_pending = false;
        port->read_completed(0, NULL, 0);
    }
}

#endif
