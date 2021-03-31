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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "erlcmd.h"
#include "util.h"
#include "uart_enum.h"
#include "uart_comm.h"

#if defined(__linux__) || defined(__APPLE__)
#include <poll.h>
#include <unistd.h>
#endif
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


/*
 * Serial port handling definitions and prototypes
 */

// Global UART reference
static struct uart *uart = NULL;
static struct uart_config current_config;

// Utilities
static const char response_id = 'r';
static const char notification_id = 'n';

/**
 * @brief Send :ok back to Elixir
 */
static void send_ok_response()
{
    char resp[256];
    int resp_index = sizeof(uint16_t); // Space for payload size
    resp[resp_index++] = response_id;
    ei_encode_version(resp, &resp_index);
    ei_encode_atom(resp, &resp_index, "ok");
    erlcmd_send(resp, resp_index);
}

/**
 * @brief Send a response of the form {:error, reason}
 *
 * @param reason a reason (sent back as an atom)
 */
static void send_error_response(const char *reason)
{
    char resp[256];
    int resp_index = sizeof(uint16_t); // Space for payload size
    resp[resp_index++] = response_id;
    ei_encode_version(resp, &resp_index);
    ei_encode_tuple_header(resp, &resp_index, 2);
    ei_encode_atom(resp, &resp_index, "error");
    ei_encode_atom(resp, &resp_index, reason);
    erlcmd_send(resp, resp_index);
}


// Elixir call handlers

static int parse_option_list(const char *req, int *req_index, struct uart_config *config)
{
    int term_type;
    int option_count;
    if (ei_get_type(req, req_index, &term_type, &option_count) < 0 ||
            (term_type != ERL_LIST_EXT && term_type != ERL_NIL_EXT)) {
        debug("expecting option list");
        return -1;
    }

    if (term_type == ERL_NIL_EXT)
        option_count = 0;
    else
        ei_decode_list_header(req, req_index, &option_count);

    // Go through all of the options
    for (int i = 0; i < option_count; i++) {
        int term_size;
        if (ei_decode_tuple_header(req, req_index, &term_size) < 0 ||
                term_size != 2) {
            debug("expecting kv tuple for options");
            return -1;
        }

        char key[64];
        if (ei_decode_atom(req, req_index, key) < 0) {
            debug("expecting atoms for option keys");
            return -1;
        }

        if (strcmp(key, "active") == 0) {
            int val;
            if (ei_decode_boolean(req, req_index, &val) < 0) {
                debug("active should be a bool");
                return -1;
            }
            config->active = (val != 0);
        } else if (strcmp(key, "speed") == 0) {
            long val;
            if (ei_decode_long(req, req_index, &val) < 0) {
                debug("speed should be an integer");
                return -1;
            }
            config->speed = val;
        } else if (strcmp(key, "data_bits") == 0) {
            long val;
            if (ei_decode_long(req, req_index, &val) < 0) {
                debug("data_bits should be an integer");
                return -1;
            }
            config->data_bits = val;
        } else if (strcmp(key, "stop_bits") == 0) {
            long val;
            if (ei_decode_long(req, req_index, &val) < 0) {
                debug("stop_bits should be an integer");
                return -1;
            }
            config->stop_bits = val;
        } else if (strcmp(key, "parity") == 0) {
            char parity[16];
            if (ei_decode_atom(req, req_index, parity) < 0) {
                debug("parity should be an atom");
                return -1;
            }
            if (strcmp(parity, "none") == 0) config->parity = UART_PARITY_NONE;
            else if (strcmp(parity, "even") == 0) config->parity = UART_PARITY_EVEN;
            else if (strcmp(parity, "odd") == 0) config->parity = UART_PARITY_ODD;
            else if (strcmp(parity, "space") == 0) config->parity = UART_PARITY_SPACE;
            else if (strcmp(parity, "mark") == 0) config->parity = UART_PARITY_MARK;
            else if (strcmp(parity, "ignore") == 0) config->parity = UART_PARITY_IGNORE;
        } else if (strcmp(key, "flow_control") == 0) {
            char flow_control[16];
            if (ei_decode_atom(req, req_index, flow_control) < 0) {
                debug("flow_control should be an atom");
                return -1;
            }
            if (strcmp(flow_control, "none") == 0) config->flow_control = UART_FLOWCONTROL_NONE;
            else if (strcmp(flow_control, "hardware") == 0) config->flow_control = UART_FLOWCONTROL_HARDWARE;
            else if (strcmp(flow_control, "software") == 0) config->flow_control = UART_FLOWCONTROL_SOFTWARE;
        } else {
            // unknown term
            ei_skip_term(req, req_index);
        }
    }
    return 0;
}

/*
 * Handle {name, kv_list}
 *
 *    name is the serial port name
 *    kv_list a list of configuration values (speed, parity, etc.)
 */
static void handle_open(const char *req, int *req_index)
{
    int term_type;
    int term_size;

    if (ei_decode_tuple_header(req, req_index, &term_size) < 0 ||
            term_size != 2)
        errx(EXIT_FAILURE, ":open requires a 2-tuple");

    char name[64];
    long binary_len;
    if (ei_get_type(req, req_index, &term_type, &term_size) < 0 ||
            term_type != ERL_BINARY_EXT ||
            term_size >= (int) sizeof(name) ||
            ei_decode_binary(req, req_index, name, &binary_len) < 0) {
        // The name is almost certainly too long, so report that it
        // doesn't exist.
        send_error_response("enoent");
        return;
    }
    name[term_size] = '\0';

    struct uart_config config = current_config;
    if (parse_option_list(req, req_index, &config) < 0) {
        send_error_response("einval");
        return;
    }

    // If the uart was already open, close and open it again
    if (uart_is_open(uart))
        uart_close(uart);

    if (uart_open(uart, name, &config) >= 0) {
        current_config = config;
        send_ok_response();
    } else {
        send_error_response(uart_last_error());
    }
}

static void handle_configure(const char *req, int *req_index)
{
    struct uart_config config = current_config;
    if (parse_option_list(req, req_index, &config) < 0) {
        send_error_response("einval");
        return;
    }

    if (uart_configure(uart, &config) >= 0) {
        current_config = config;
        send_ok_response();
    } else {
        send_error_response(uart_last_error());
    }
}

static void handle_configuration(const char *req, int *req_index)
{
    char resp[256];
    int resp_index = sizeof(uint16_t); // Space for payload size
    resp[resp_index++] = response_id;
    ei_encode_version(resp, &resp_index);

    ei_encode_list_header(resp, &resp_index, 5);

    ei_encode_tuple_header(resp, &resp_index, 2);
    ei_encode_atom(resp, &resp_index, "speed");
    ei_encode_long(resp, &resp_index, current_config.speed);

    ei_encode_tuple_header(resp, &resp_index, 2);
    ei_encode_atom(resp, &resp_index, "data_bits");
    ei_encode_long(resp, &resp_index, current_config.data_bits);

    ei_encode_tuple_header(resp, &resp_index, 2);
    ei_encode_atom(resp, &resp_index, "stop_bits");
    ei_encode_long(resp, &resp_index, current_config.stop_bits);

    ei_encode_tuple_header(resp, &resp_index, 2);
    ei_encode_atom(resp, &resp_index, "parity");
    switch (current_config.parity) {
    default:
    case UART_PARITY_NONE: ei_encode_atom(resp, &resp_index, "none"); break;
    case UART_PARITY_EVEN: ei_encode_atom(resp, &resp_index, "even"); break;
    case UART_PARITY_ODD: ei_encode_atom(resp, &resp_index, "odd"); break;
    case UART_PARITY_SPACE: ei_encode_atom(resp, &resp_index, "space"); break;
    case UART_PARITY_MARK: ei_encode_atom(resp, &resp_index, "mark"); break;
    case UART_PARITY_IGNORE: ei_encode_atom(resp, &resp_index, "ignore"); break;
    }

    ei_encode_tuple_header(resp, &resp_index, 2);
    ei_encode_atom(resp, &resp_index, "flow_control");
    switch (current_config.flow_control) {
    default:
    case UART_FLOWCONTROL_NONE: ei_encode_atom(resp, &resp_index, "none"); break;
    case UART_FLOWCONTROL_HARDWARE: ei_encode_atom(resp, &resp_index, "hardware"); break;
    case UART_FLOWCONTROL_SOFTWARE: ei_encode_atom(resp, &resp_index, "software"); break;
    }

    ei_encode_empty_list(resp, &resp_index);

    erlcmd_send(resp, resp_index);
}

static void handle_close(const char *req, int *req_index)
{
    (void) req;
    (void) req_index;

    if (uart_is_open(uart))
        uart_close(uart);

    send_ok_response();
}

static void handle_write(const char *req, int *req_index)
{
    if (!uart_is_open(uart)) {
        send_error_response("ebadf");
        return;
    }

    int term_size;
    if (ei_decode_tuple_header(req, req_index, &term_size) < 0 ||
            term_size != 2)
        errx(EXIT_FAILURE, "expecting {data, timeout}");

    int term_type;
    if (ei_get_type(req, req_index, &term_type, &term_size) < 0 ||
            term_type != ERL_BINARY_EXT)
        errx(EXIT_FAILURE, "expecting data as a binary");

    uint8_t *to_write = malloc(term_size);
    long amount_to_write;
    if (ei_decode_binary(req, req_index, to_write, &amount_to_write) < 0)
        errx(EXIT_FAILURE, "decode binary error?");

    long timeout;
    if (ei_decode_long(req, req_index, &timeout) < 0)
        errx(EXIT_FAILURE, "expecting timeout");

    // uart_write always invokes a callback when it completes (error or no error).
    uart_write(uart, to_write, amount_to_write, timeout);
}

static void handle_write_completed(int rc, const uint8_t *data)
{
    free((uint8_t *) data);

    if (rc == 0)
        send_ok_response();
    else
        send_error_response(uart_last_error());
}

static void handle_read(const char *req, int *req_index)
{
    if (!uart_is_open(uart)) {
        send_error_response("ebadf");
        return;
    }

    long timeout;
    if (ei_decode_long(req, req_index, &timeout) < 0)
        errx(EXIT_FAILURE, "expecting timeout");

    uart_read(uart, timeout);

    // handle_read_completed is called when read completes, times out, or errors
}

/* Called when uart_read completes or fails */
static void handle_read_completed(int rc, const uint8_t *data, size_t len)
{
    if (rc >= 0) {
        char *resp = malloc(32 + len);
        int resp_index = sizeof(uint16_t);
        resp[resp_index++] = response_id;
        ei_encode_version(resp, &resp_index);
        ei_encode_tuple_header(resp, &resp_index, 2);
        ei_encode_atom(resp, &resp_index, "ok");
        ei_encode_binary(resp, &resp_index, data, len);
        erlcmd_send(resp, resp_index);
        free(resp);
    } else
        send_error_response(uart_last_error());
}

/* Called in active mode when there's a read or an error */
static void handle_notify_read(int error_reason, const uint8_t *data, size_t len)
{
    char *resp = malloc(64 + len);
    int resp_index = sizeof(uint16_t);
    resp[resp_index++] = notification_id;
    ei_encode_version(resp, &resp_index);

    ei_encode_tuple_header(resp, &resp_index, 2);
    ei_encode_atom(resp, &resp_index, "notif");

    if (error_reason == 0) {
        // Normal receive
        ei_encode_binary(resp, &resp_index, data, len);
    } else {
        // Error notification
        ei_encode_tuple_header(resp, &resp_index, 2);
        ei_encode_atom(resp, &resp_index, "error");
        ei_encode_atom(resp, &resp_index, uart_last_error());
    }
    erlcmd_send(resp, resp_index);
    free(resp);
}

static void handle_drain(const char *req, int *req_index)
{
    (void) req;
    (void) req_index;
    if (!uart_is_open(uart)) {
        send_error_response("ebadf");
        return;
    }

    if (uart_drain(uart) >= 0)
        send_ok_response();
    else
        send_error_response(uart_last_error());
}

static void handle_flush(const char *req, int *req_index)
{
    char dirstr[MAXATOMLEN];
    if (ei_decode_atom(req, req_index, dirstr) < 0) {
        send_error_response("einval");
        return;
    }

    enum uart_direction direction;
    if (strcmp(dirstr, "receive") == 0)
        direction = UART_DIRECTION_RECEIVE;
    else if (strcmp(dirstr, "transmit") == 0)
        direction = UART_DIRECTION_TRANSMIT;
    else if (strcmp(dirstr, "both") == 0)
        direction = UART_DIRECTION_BOTH;
    else {
        send_error_response("einval");
        return;
    }

    if (!uart_is_open(uart)) {
        send_error_response("ebadf");
        return;
    }

    if (uart_flush(uart, direction) >= 0)
        send_ok_response();
    else
        send_error_response(uart_last_error());
}

static void encode_kv_bool(char *resp, int *resp_index, const char *key, int value)
{
    ei_encode_atom(resp, resp_index, key);
    ei_encode_boolean(resp, resp_index, value);
}

static void handle_set_rts(const char *req, int *req_index)
{
    int val;
    if (ei_decode_boolean(req, req_index, &val) < 0) {
        send_error_response("einval");
        return;
    }

    if (!uart_is_open(uart)) {
        send_error_response("ebadf");
        return;
    }

    if (uart_set_rts(uart, !!val) >= 0)
        send_ok_response();
    else
        send_error_response(uart_last_error());
}

static void handle_set_dtr(const char *req, int *req_index)
{
    int val;
    if (ei_decode_boolean(req, req_index, &val) < 0) {
        send_error_response("einval");
        return;
    }

    if (!uart_is_open(uart)) {
        send_error_response("ebadf");
        return;
    }

    if (uart_set_dtr(uart, !!val) >= 0)
        send_ok_response();
    else
        send_error_response(uart_last_error());
}

static void handle_set_break(const char *req, int *req_index)
{
    int val;
    if (ei_decode_boolean(req, req_index, &val) < 0) {
        send_error_response("einval");
        return;
    }

    if (!uart_is_open(uart)) {
        send_error_response("ebadf");
        return;
    }

    if (uart_set_break(uart, !!val) >= 0)
        send_ok_response();
    else
        send_error_response(uart_last_error());
}

static void handle_signals(const char *req, int *req_index)
{
    // No arguments
    (void) req;
    (void) req_index;

    if (!uart_is_open(uart)) {
        send_error_response("ebadf");
        return;
    }

    struct uart_signals sig;
    if (uart_get_signals(uart, &sig) >= 0) {
        char resp[128];
        int resp_index = sizeof(uint16_t);
        resp[resp_index++] = response_id;
        ei_encode_version(resp, &resp_index);
        ei_encode_tuple_header(resp, &resp_index, 2);
        ei_encode_atom(resp, &resp_index, "ok");
        ei_encode_map_header(resp, &resp_index, 8);
        encode_kv_bool(resp, &resp_index, "dsr", sig.dsr);
        encode_kv_bool(resp, &resp_index, "dtr", sig.dtr);
        encode_kv_bool(resp, &resp_index, "rts", sig.rts);
        encode_kv_bool(resp, &resp_index, "st", sig.st);
        encode_kv_bool(resp, &resp_index, "sr", sig.sr);
        encode_kv_bool(resp, &resp_index, "cts", sig.cts);
        encode_kv_bool(resp, &resp_index, "cd", sig.cd);
        encode_kv_bool(resp, &resp_index, "rng", sig.rng);
        erlcmd_send(resp, resp_index);
    } else
        send_error_response(uart_last_error());
}

struct request_handler {
    const char *name;
    void (*handler)(const char *req, int *req_index);
};

/* Elixir request handler table
 * Ordered roughly based on most frequent calls to least.
 */
static struct request_handler request_handlers[] = {
{ "write", handle_write },
{ "read", handle_read },
{ "flush", handle_flush },
{ "drain", handle_drain },
{ "open", handle_open },
{ "configure", handle_configure },
{ "configuration", handle_configuration },
{ "close", handle_close },
{ "signals", handle_signals },
{ "set_rts", handle_set_rts },
{ "set_dtr", handle_set_dtr },
{ "set_break", handle_set_break },
{ NULL, NULL }
};

/**
 * @brief Decode and forward requests from Elixir to the appropriate handlers
 * @param req the undecoded request
 * @param cookie
 */
static void handle_elixir_request(const char *req, void *cookie)
{
    (void) cookie;

    // Commands are of the form {Command, Arguments}:
    // { atom(), term() }
    int req_index = sizeof(uint16_t);
    if (ei_decode_version(req, &req_index, NULL) < 0)
        errx(EXIT_FAILURE, "Message version issue?");

    int arity;
    if (ei_decode_tuple_header(req, &req_index, &arity) < 0 ||
            arity != 2)
        errx(EXIT_FAILURE, "expecting {cmd, args} tuple");

    char cmd[MAXATOMLEN];
    if (ei_decode_atom(req, &req_index, cmd) < 0)
        errx(EXIT_FAILURE, "expecting command atom");

    for (struct request_handler *rh = request_handlers; rh->name != NULL; rh++) {
        if (strcmp(cmd, rh->name) == 0) {
            rh->handler(req, &req_index);
            return;
        }
    }
    errx(EXIT_FAILURE, "unknown command: %s", cmd);
}

#if defined(__linux__) || defined(__APPLE__)
void main_loop()
{
    uart_default_config(&current_config);
    if (uart_init(&uart,
                  handle_write_completed,
                  handle_read_completed,
                  handle_notify_read) < 0)
        errx(EXIT_FAILURE, "uart_init failed");

    struct erlcmd *handler = malloc(sizeof(struct erlcmd));
    erlcmd_init(handler, handle_elixir_request, NULL);

    for (;;) {
        struct pollfd fdset[3];

        fdset[0].fd = STDIN_FILENO;
        fdset[0].events = POLLIN;
        fdset[0].revents = 0;

        int timeout = -1; // Wait forever unless told by otherwise
        int count = uart_add_poll_events(uart, &fdset[1], &timeout);

        int rc = poll(fdset, count + 1, timeout);
        if (rc < 0) {
            // Retry if EINTR
            if (errno == EINTR)
                continue;

            err(EXIT_FAILURE, "poll");
        }

        if (fdset[0].revents & (POLLIN | POLLHUP)) {
            if (erlcmd_process(handler))
                break;
        }

        // Call uart_process if it added any events
        if (count)
            uart_process(uart, &fdset[1]);
    }

    // Exit due to Erlang trying to end the process.
    //
    if (uart_is_open(uart))
        uart_flush_all(uart);
}
#elif defined(__WIN32__)
#include <windows.h>

void main_loop()
{
    uart_default_config(&current_config);
    if (uart_init(&uart,
                  handle_write_completed,
                  handle_read_completed,
                  handle_notify_read) < 0)
        errx(EXIT_FAILURE, "uart_init failed");

    struct erlcmd *handler = malloc(sizeof(struct erlcmd));
    erlcmd_init(handler, handle_elixir_request, NULL);

    bool running = true;
    while (running) {
        HANDLE handles[3];
        handles[0] = erlcmd_wfmo_event(handler);

        DWORD timeout = INFINITE;
        DWORD count = 1 + uart_add_wfmo_handles(uart, &handles[1], &timeout);

        debug("Calling WFMO count=%d", (int) count);
        DWORD result = WaitForMultipleObjects(count,
                                              handles,
                                              FALSE,
                                              timeout);


        debug("WFMO returned %d", (int) result);

        switch(result) {
        case WAIT_OBJECT_0 + 0:
            if (erlcmd_process(handler))
                running = false;
            break;

        case WAIT_OBJECT_0 + 1:
            uart_process_handle(uart, handles[1]);
            break;

        case WAIT_OBJECT_0 + 2:
            uart_process_handle(uart, handles[2]);
            break;

        case WAIT_TIMEOUT:
            uart_process_timeout(uart);
            break;

        case WAIT_FAILED:
            debug("WFMO wait failed! %d", (int) GetLastError());
            // TODO: Is this ever a transient occurrence that we
            //       should ignore and retry?
            running = false;
            break;

        default:
            break;
        }

    }

    // Exit due to Erlang trying to end the process.
    if (uart_is_open(uart))
        uart_flush_all(uart);
}

#else
#error "Unsupported platform"
#endif

static void enumerate_ports()
{
    struct serial_info *port_list = find_serialports();
    int port_list_len = 0;
    for (struct serial_info *port = port_list;
         port != NULL;
         port = port->next)
        port_list_len++;

    debug("Found %d ports", port_list_len);
    char resp[4096];
    int resp_index = sizeof(uint16_t); // Space for payload size
    resp[resp_index++] = response_id;
    ei_encode_version(resp, &resp_index);

    ei_encode_map_header(resp, &resp_index, port_list_len);

    for (struct serial_info *port = port_list;
         port != NULL;
         port = port->next) {
        ei_encode_binary(resp, &resp_index, port->name, strlen(port->name));

        int info_count = (port->description ? 1 : 0) +
                (port->manufacturer ? 1 : 0) +
                (port->serial_number ? 1 : 0) +
                (port->vid > 0 ? 1 : 0) +
                (port->pid > 0 ? 1 : 0);

        ei_encode_map_header(resp, &resp_index, info_count);
        if (port->description) {
            ei_encode_atom(resp, &resp_index, "description");
            ei_encode_binary(resp, &resp_index, port->description, strlen(port->description));
        }
        if (port->manufacturer) {
            ei_encode_atom(resp, &resp_index, "manufacturer");
            ei_encode_binary(resp, &resp_index, port->manufacturer, strlen(port->manufacturer));
        }
        if (port->serial_number) {
            ei_encode_atom(resp, &resp_index, "serial_number");
            ei_encode_binary(resp, &resp_index, port->serial_number, strlen(port->serial_number));
        }
        if (port->vid > 0) {
            ei_encode_atom(resp, &resp_index, "vendor_id");
            ei_encode_ulong(resp, &resp_index, port->vid);
        }
        if (port->pid > 0) {
            ei_encode_atom(resp, &resp_index, "product_id");
            ei_encode_ulong(resp, &resp_index, port->pid);
        }
    }
    erlcmd_send(resp, resp_index);
    serial_info_free_list(port_list);
}

#ifdef DEBUG
void test();
#endif

int main(int argc, char *argv[])
{
#ifdef DEBUG
#if 0
    // Erlang on Windows really doesn't like logging to stderr.
    log_location = stderr;
#else
    char logfile[64];
#ifdef __WIN32__
    sprintf(logfile, "circuits_uart-%d.log", (int) GetCurrentProcessId());
#else
    sprintf(logfile, "/tmp/circuits_uart-%d.log", (int) getpid());
#endif
    FILE *fp = fopen(logfile, "w+");
    log_location = fp;

    debug("Starting...");
#endif
#endif

    if (argc == 1)
        main_loop();
    else if (argc == 2 && strcmp(argv[1], "enumerate") == 0)
        enumerate_ports();
#ifdef DEBUG
    else if (argc == 2 && strcmp(argv[1], "test") == 0)
        test();
#endif
    else
        errx(EXIT_FAILURE, "%s [enumerate]", argv[0]);

    return 0;
}
