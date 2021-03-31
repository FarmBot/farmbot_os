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

#ifndef UART_ENUM_H
#define UART_ENUM_H

struct serial_info {
    char *name;
    char *description;
    char *manufacturer;
    char *serial_number;
    int vid;
    int pid;

    struct serial_info *next;
};

// Common code
struct serial_info *serial_info_alloc();
void serial_info_free(struct serial_info *info);
void serial_info_free_list(struct serial_info *info);

// Prototypes for device-specific code
struct serial_info *find_serialports();

#endif // UART_ENUM_H
