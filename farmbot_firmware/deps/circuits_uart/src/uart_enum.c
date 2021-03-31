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

#include "uart_enum.h"

#include <stdlib.h>
#include <string.h>

struct serial_info *serial_info_alloc()
{
    struct serial_info *info = (struct serial_info *) malloc(sizeof(struct serial_info));
    memset(info, 0, sizeof(struct serial_info));
    return info;
}

void serial_info_free(struct serial_info *info)
{
    // Free any data
    if (info->name)
        free(info->name);
    if (info->description)
        free(info->description);
    if (info->serial_number)
        free(info->serial_number);
    if (info->manufacturer)
        free(info->manufacturer);

    // Reset the fields
    memset(info, 0, sizeof(struct serial_info));
}

void serial_info_free_list(struct serial_info *info)
{
    while (info) {
        struct serial_info *next = info->next;
        serial_info_free(info);
        free(info);
        info = next;
    }
}

