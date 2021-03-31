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

#include <stdbool.h>
#include <stdint.h>

#include "erlcmd.h"
#include "uart_comm.h"
#include "uart_enum.h"
#include "util.h"

#ifndef __WIN32__
#include <string.h>
#include <unistd.h>
#endif

/*
 * These tests are only enabled when DEBUG is definied. They're sometimes
 * useful when debugging the C code so that Erlang and Elixir don't
 * complicate things.
 */
#ifdef DEBUG
static struct uart *uart = NULL;

static bool test_write_is_done = false;
static bool test_read_is_done = false;
static void test_write_completed(int rc, const uint8_t *data)
{
    (void) data;
    debug("test_write_completed: rc=%d", rc);
    if (rc < 0)
        errx(EXIT_FAILURE, "Error from uart_write: %s\n", uart_last_error());
    test_write_is_done = true;
}
static void test_read_completed(int rc, const uint8_t *data, size_t len)
{
    (void) data;
    debug("test_read_completed: rc=%d, %d bytes", rc, (int) len);
    if (rc < 0)
        errx(EXIT_FAILURE, "Error from uart_read: %s\n", uart_last_error());
    test_read_is_done = true;
}

static void test_wait_once(struct erlcmd *handler)
{
#ifdef __WIN32__
    HANDLE handles[3];
    DWORD timeout = INFINITE;
    handles[0] = erlcmd_wfmo_event(handler);
    int count = 1 + uart_add_wfmo_handles(uart, &handles[1], &timeout);
    debug("Calling WFMO...");
    DWORD result = WaitForMultipleObjects(count,
                                          handles,
                                          FALSE,
                                          timeout);
    debug("WFMO result=%d!!", (int) result);
    switch (result) {
    case WAIT_OBJECT_0 + 0:
        erlcmd_process(handler);
        break;
    case WAIT_OBJECT_0 + 1:
    case WAIT_OBJECT_0 + 2:
        uart_process_handle(uart, handles[result]);
        break;
    case WAIT_TIMEOUT:
        uart_process_timeout(uart);
        break;
    default:
        errx(EXIT_FAILURE, "Error from WFMO");
        break;
    }
#else
    (void) handler;
    usleep(1000);
    fprintf(stderr, "polling\n");
    uart_process(uart, NULL);
#endif
}

void test()
{
    struct erlcmd *handler = malloc(sizeof(struct erlcmd));
    erlcmd_init(handler, NULL, NULL);

    struct serial_info *port_list = find_serialports();
    if (!port_list) {
        fprintf(stderr, "No serial ports detected!\n");
        return;
    }
    fprintf(stderr, "Name: %s\n", port_list->name);
    fprintf(stderr, "Description: %s\n", port_list->description);
    fprintf(stderr, "Manufacturer: %s\n", port_list->manufacturer);
    fprintf(stderr, "Serial number: %s\n", port_list->serial_number);
    fprintf(stderr, "vid: 0x%04x\n", port_list->vid);
    fprintf(stderr, "pid: 0x%04x\n", port_list->pid);
    fprintf(stderr, "---\n");

    fprintf(stderr, "Calling open on %s...\n", port_list->name);
    struct uart_config config;
    uart_default_config(&config);
    config.active = false;

    uart_init(&uart, test_write_completed, test_read_completed, NULL);
    int rc = uart_open(uart, port_list->name, &config);
    if (rc < 0)
        errx(EXIT_FAILURE, "Error from uart_open: %s\n", uart_last_error());

    fprintf(stderr, "Calling write...\n");
    int big_buffer_size = 100; // This may take a while.
    uint8_t *big_buffer = malloc(big_buffer_size);
    memset(big_buffer, 'a', big_buffer_size);
    uart_write(uart, big_buffer, big_buffer_size, -1);

    while (!test_write_is_done)
        test_wait_once(handler);
    free(big_buffer);

    for (int i = 0; i < 10; i++) {
        test_read_is_done = false;
        fprintf(stderr, "Calling read (%d)...\n", i);
        uart_read(uart, 1000);
        while (!test_read_is_done)
            test_wait_once(handler);
        fprintf(stderr, "uart_read returned %d\n", rc);
    }

    fprintf(stderr, "Done!\n");
    uart_close(uart);
    serial_info_free_list(port_list);
}
#endif
