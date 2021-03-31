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

#ifndef UART_COMM_H
#define UART_COMM_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum uart_parity {
    UART_PARITY_NONE = 0,
    UART_PARITY_EVEN,
    UART_PARITY_ODD,
    UART_PARITY_SPACE,
    UART_PARITY_MARK,
    UART_PARITY_IGNORE
};

enum uart_flow_control {
    UART_FLOWCONTROL_NONE = 0,
    UART_FLOWCONTROL_HARDWARE,
    UART_FLOWCONTROL_SOFTWARE
};

enum uart_direction {
    UART_DIRECTION_RECEIVE = 0,
    UART_DIRECTION_TRANSMIT,
    UART_DIRECTION_BOTH
};

struct uart_config
{
    bool active;
    int speed;      // 9600, 115200, etc.
    int data_bits;  // 5, 6, 7, 8
    int stop_bits;  // 1 or 2
    enum uart_parity parity;
    enum uart_flow_control flow_control;
};

struct uart_signals
{
    bool dsr;
    bool dtr;
    bool rts;
    bool st;
    bool sr;
    bool cts;
    bool cd;
    bool rng;
};

struct uart;

void uart_default_config(struct uart_config *config);

const char *uart_last_error();

typedef void (*uart_write_completed_callback)(int rc, const uint8_t *data);
typedef void (*uart_read_completed_callback)(int rc, const uint8_t *data, size_t len);
typedef void (*uart_notify_read)(int error_reason, const uint8_t *data, size_t len);

/**
 * @brief Initialize the UART data
 *
 * @param pport a uart struct is allocated and returned on success
 * @param write_completed a callback for completed writes
 * @return 0 on success, <0 on error
 */
int uart_init(struct uart **pport,
              uart_write_completed_callback write_completed,
              uart_read_completed_callback read_completed,
              uart_notify_read notify_read);

/**
 * @brief Return true (1) if port is open
 *
 * @param port the uart struct
 * @return 0 if closed, 1 if open
 */
int uart_is_open(struct uart *port);

/**
 * @brief Open the specified UART port
 *
 * @param port the uart struct
 * @param name  the name of the port to open
 * @param config the initial configuration
 * @return 0 on success, <0 on error
 */
int uart_open(struct uart *port, const char *name, const struct uart_config *config);

/**
 * @brief Close and free up the resources for a UART
 * @param port the uart struct
 * @return 0 on success
 */
int uart_close(struct uart *port);

/**
 * @brief Write data to the UART
 *
 * An attempt can be made to send the data synchronously, but many
 * transfers complete asynchrously, so the data buffer shouldn't be
 * freed until the write_completed() callback is invoked.
 *
 * Only one write may be pending at a time.
 *
 * @param port the uart struct
 * @param data the bytes to write
 * @param len how many
 * @param timeout the max number of milliseconds to allow (-1 = forever)
 * @return the write_completed callback is always invoked with the result
 */
void uart_write(struct uart *port, const uint8_t *data, size_t len, int timeout);

/**
 * @brief Read data from the UART
 *
 * This function initiates a read from the UART. The results of the read
 * are reported by the read_completed() callback. If nothing is immediately
 * available and the timeout allows for it, the operation occurs asynchronously.
 *
 * Only one read may be pending at a time.
 *
 * @param port the uart struct
 * @param timeout wait up to this long for something to be received
 *                -1 means wait forever
 * @return the read_completed callback is always invoked
 */
void uart_read(struct uart *port, int timeout);

/**
 * @brief Update the UART's configuration
 *
 * @param port the uart struct
 * @param config the new configuration
 * @return <0 on error
 */
int uart_configure(struct uart *port, const struct uart_config *config);

/**
 * @brief Block until all data is written out the port
 *
 * @param port the uart struct
 * @return 0 on success
 */
int uart_drain(struct uart *port);

/**
 * @brief Flush the receive and/or transmit queues
 *
 * @param port the uart struct
 * @param direction which direction
 * @return 0 on success
 */
int uart_flush(struct uart *port, enum uart_direction direction);

/**
 * @brief Flush the tx and rx queues
 *
 * @param port the uart struct
 * @return 0 on success
 */
int uart_flush_all(struct uart *port);

/**
 * @brief Set or clear the Request To Send signal
 *
 * @param port the uart struct
 * @param val true or false
 * @return 0 on success
 */
int uart_set_rts(struct uart *port, bool val);

/**
 * @brief Set or clear the Data Terminal Ready signal
 *
 * @param port the uart struct
 * @param val true or false
 * @return 0 on success
 */
int uart_set_dtr(struct uart *port, bool val);

/**
 * @brief Set or clear the break signal
 *
 * @param port the uart struct
 * @param val true or false
 * @return 0 on success
 */
int uart_set_break(struct uart *port, bool val);

/**
 * @brief Read the state of all UART signals
 *
 * @param port the uart struct
 * @param sig the state is returned here
 * @return 0 on success
 */
int uart_get_signals(struct uart *port, struct uart_signals *sig);

#if defined(__linux__) || defined(__APPLE__)
struct pollfd;

/**
 * @brief Update fdset with desired events
 *
 * @param port the uart struct
 * @param fdset an open fdset slot
 * @param timeout milliseconds to poll
 *
 * @return the number of events added
 */
int uart_add_poll_events(struct uart *port, struct pollfd *fdset, int *timeout);

/**
 * @brief Process events
 *
 * @param port the uart struct
 * @param fdset the returned fdset from poll()
 */
void uart_process(struct uart *port, const struct pollfd *fdset);
#elif defined(__WIN32__)
#include <windows.h>

int uart_add_wfmo_handles(struct uart *port, HANDLE *handles, DWORD *timeout);

void uart_process_handle(struct uart *port, HANDLE *event);
void uart_process_timeout(struct uart *port);

#else
#error Unsupported platform
#endif

#endif // UART_COMM_H
