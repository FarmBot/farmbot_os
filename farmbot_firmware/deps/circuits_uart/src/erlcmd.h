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

#ifndef ERLCMD_H
#define ERLCMD_H

#include <ei.h>

#ifdef __WIN32__
#include <windows.h>
#endif

/*
 * Erlang request/response processing
 */
#define ERLCMD_BUF_SIZE 16384 // Large size is to support large UART writes
struct erlcmd
{
    char buffer[ERLCMD_BUF_SIZE];
    size_t index;

    void (*request_handler)(const char *emsg, void *cookie);
    void *cookie;

#ifdef __WIN32__
    HANDLE h;
    OVERLAPPED overlapped;

    HANDLE stdin_reader_thread;
    HANDLE stdin_read_pipe;
    HANDLE stdin_write_pipe;
    BOOL running;
#endif
};

void erlcmd_init(struct erlcmd *handler,
		 void (*request_handler)(const char *req, void *cookie),
		 void *cookie);
void erlcmd_send(char *response, size_t len);
int erlcmd_process(struct erlcmd *handler);

#ifdef __WIN32__
HANDLE erlcmd_wfmo_event(struct erlcmd *handler);
#endif

#endif
