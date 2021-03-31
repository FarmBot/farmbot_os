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
 *
 * Common Erlang->C port communications code
 */

#include "erlcmd.h"
#include "util.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifdef __WIN32__
// Assume that all windows platforms are little endian
#define TO_BIGENDIAN16(X) _byteswap_ushort(X)
#define FROM_BIGENDIAN16(X) _byteswap_ushort(X)
#else
// Other platforms have htons and ntohs without pulling in another library
#define TO_BIGENDIAN16(X) htons(X)
#define FROM_BIGENDIAN16(X) ntohs(X)
#endif

#ifdef __WIN32__
/*
 * stdin on Windows
 *
 * Caveat: I'm convinced that I don't understand stdin on Windows, so take
 * with a grain of salt.
 *
 * Here's what I know:
 *
 *   1. When running from a command prompt, stdin is a console. Windows
 *      consoles collect lines at a time. See SetConsoleMode.
 *   2. The console is opened for synchronous use. I.e., overlapped I/O
 *      doesn't work.
 *   3. Opening stdin using CONIN$ works for console use, but not
 *      redirected use. (Seems obvious, but lots of search hits on
 *      Google do this, so it seemed worthwhile to try.)
 *   5. When stdin is redirected to another program, it behaves like
 *      a pipe. It may really be a pipe, but the docs that I've read
 *      don't call it one.
 *   6. The pipe is opened for synchronous use.
 *   7. Calling ReOpenFile to change it to support overlapped I/O
 *      didn't work.
 *   8. Despite pipes not being listed as things you can wait on with
 *      WaitForMultipleObjects, it seems to work. Hopefully just a
 *      documentation omission...
 *
 * Since there seems to be no way of making stdin be overlapped I/O
 * capable, I created a thread and a new pipe. The thread synchronously
 * reads from stdin and writes to the new pipe. The read end of the new
 * pipe supports overlapped I/O so I can use it in the main WFMO loop.
 *
 * If performance gets to be an issue, the pipe could be replaced with
 * a shared memory/event notification setup. Until this, the pipe version
 * is pretty simple albeit with a lot of data copies and process switches.
 */

static DWORD WINAPI pipe_copy_thread(LPVOID lpParam)
{
    struct erlcmd *handler = (struct erlcmd *) lpParam;

    // NEED to get overlapped version of stdin reader
    HANDLE real_stdin = GetStdHandle(STD_INPUT_HANDLE);

    // Turn off ENABLE_LINE_INPUT (and everything else)
    // This has to be done on the STD_INPUT_HANDLE rather than
    // the one we use for events. Don't know why.
    SetConsoleMode(real_stdin, 0);

    while (handler->running) {
        char buffer[1024];
        DWORD bytes_read;
        if (!ReadFile(real_stdin, buffer, sizeof(buffer), &bytes_read, NULL)) {
            debug("ReadFile on real_stdin failed (port closed)! %d", (int) GetLastError());
            break;
        }

        if (!WriteFile(handler->stdin_write_pipe, buffer, bytes_read, NULL, NULL)) {
            debug("WriteFile on stdin_write_pipe failed! %d", (int) GetLastError());
            break;
        }
    }

    handler->running = FALSE;
    CloseHandle(handler->stdin_write_pipe);
    handler->stdin_write_pipe = NULL;

    ExitThread(0);
    return 0;
}

static void start_async_read(struct erlcmd *handler)
{
    ReadFile(handler->h,
               handler->buffer + handler->index,
               sizeof(handler->buffer) - handler->index,
               NULL,
               &handler->overlapped);
}

#endif

/**
 * Initialize an Erlang command handler.
 *
 * @param handler the structure to initialize
 * @param request_handler callback for each message received
 * @param cookie optional data to pass back to the handler
 */
void erlcmd_init(struct erlcmd *handler,
                 void (*request_handler)(const char *req, void *cookie),
                 void *cookie)
{
    memset(handler, 0, sizeof(*handler));

    handler->request_handler = request_handler;
    handler->cookie = cookie;

#ifdef __WIN32__
    handler->running = TRUE;

    char pipe_name[64];
    sprintf(pipe_name,
             "\\\\.\\Pipe\\circuits-uart.%08x",
             (unsigned int) GetCurrentProcessId());

    handler->stdin_read_pipe = CreateNamedPipeA(
                         pipe_name,
                         PIPE_ACCESS_INBOUND | FILE_FLAG_OVERLAPPED,
                         PIPE_TYPE_BYTE | PIPE_WAIT,
                         1,             // Number of pipes
                         4096,          // Out buffer size
                         4096,          // In buffer size
                         120 * 1000,    // Timeout in ms
                         NULL
                         );
    if (!handler->stdin_read_pipe)
        errx(EXIT_FAILURE, "Can't create overlapped i/o stdin pipe");

    handler->stdin_write_pipe = CreateFileA(
                        pipe_name,
                        GENERIC_WRITE,
                        0,                         // No sharing
                        NULL,
                        OPEN_EXISTING,
                        FILE_ATTRIBUTE_NORMAL,
                        NULL                       // Template file
                      );
    if (!handler->stdin_write_pipe)
        errx(EXIT_FAILURE, "Can't create write side of stdin pipe");

    handler->stdin_reader_thread = CreateThread(
               NULL,                   // default security attributes
               0,                      // use default stack size
               pipe_copy_thread,       // thread function name
               handler,          // argument to thread function
               0,                      // use default creation flags
               NULL);
    if (handler->stdin_reader_thread == NULL) {
        errx(EXIT_FAILURE, "CreateThread failed: %d", (int) GetLastError());
        return;
    }
    handler->h = handler->stdin_read_pipe;
    if (handler->h == INVALID_HANDLE_VALUE)
        errx(EXIT_FAILURE, "Can't open stdin %d", (int) GetLastError());

    handler->overlapped.hEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    handler->overlapped.Offset = 0;
    handler->overlapped.OffsetHigh = 0;

    start_async_read(handler);
#endif
}

/**
 * @brief Synchronously send a response back to Erlang
 *
 * @param response what to send back
 */
void erlcmd_send(char *response, size_t len)
{
    uint16_t be_len = TO_BIGENDIAN16(len - sizeof(uint16_t));
    memcpy(response, &be_len, sizeof(be_len));

#ifdef __WIN32__
    BOOL rc = WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), response, len, NULL, NULL);
    if (!rc)
        errx(EXIT_FAILURE, "WriteFile to stdout failed (Erlang exit?)");
#else
    size_t wrote = 0;
    do {        
        ssize_t amount_written = write(STDOUT_FILENO, response + wrote, len - wrote);
        if (amount_written < 0) {
            if (errno == EINTR)
                continue;

            err(EXIT_FAILURE, "write");
        }
        wrote += amount_written;
    } while (wrote < len);
#endif
}

/**
 * @brief Dispatch commands in the buffer
 * @return the number of bytes processed
 */
static size_t erlcmd_try_dispatch(struct erlcmd *handler)
{
    /* Check for length field */
    if (handler->index < sizeof(uint16_t))
        return 0;

    uint16_t be_len;
    memcpy(&be_len, handler->buffer, sizeof(uint16_t));
    size_t msglen = FROM_BIGENDIAN16(be_len);
    if (msglen + sizeof(uint16_t) > sizeof(handler->buffer))
        errx(EXIT_FAILURE, "Message too long: %d bytes. Max is %d bytes",
             (int) (msglen + sizeof(uint16_t)), (int) sizeof(handler->buffer));

    /* Check whether we've received the entire message */
    if (msglen + sizeof(uint16_t) > handler->index)
        return 0;

    handler->request_handler(handler->buffer, handler->cookie);

    return msglen + sizeof(uint16_t);
}

/**
 * @brief Call to process any new requests from Erlang
 *
 * @return 1 if the program should exit gracefully
 */
int erlcmd_process(struct erlcmd *handler)
{
#ifdef __WIN32__
    DWORD amount_read;
    BOOL rc = GetOverlappedResult(handler->h,
                                  &handler->overlapped,
                                  &amount_read, FALSE);

    if (!rc) {
        DWORD last_error = GetLastError();

        // Check if this was a spurious event.
        if (last_error == ERROR_IO_PENDING)
            return 0;

        // Error - most likely the Erlang port connected to us was closed.
        // Tell the caller to exit gracefully.
        return 1;
    }

    ResetEvent(handler->overlapped.hEvent);
#else
    ssize_t amount_read = read(STDIN_FILENO, handler->buffer + handler->index, sizeof(handler->buffer) - handler->index);
    if (amount_read < 0) {
        /* EINTR is ok to get, since we were interrupted by a signal. */
        if (errno == EINTR)
            return 0;

        /* Everything else is unexpected. */
        err(EXIT_FAILURE, "read");
    } else if (amount_read == 0) {
        /* EOF. Erlang process was terminated. This happens after a release or if there was an error. */
        return 1;
    }
#endif
    handler->index += amount_read;

    for (;;) {
        size_t bytes_processed = erlcmd_try_dispatch(handler);

        if (bytes_processed == 0) {
            /* Only have part of the command to process. */
            break;
        } else if (handler->index > bytes_processed) {
            /* Processed the command and there's more data. */
            memmove(handler->buffer, &handler->buffer[bytes_processed], handler->index - bytes_processed);
            handler->index -= bytes_processed;
        } else {
            /* Processed the whole buffer. */
            handler->index = 0;
            break;
        }
    }

#ifdef __WIN32__
    start_async_read(handler);
#endif

    return 0;
}

#ifdef __WIN32__
HANDLE erlcmd_wfmo_event(struct erlcmd *handler)
{
    return handler->overlapped.hEvent;
}

#endif
