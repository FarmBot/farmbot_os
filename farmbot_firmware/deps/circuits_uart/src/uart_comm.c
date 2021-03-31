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

#include "uart_comm.h"

/**
 * @brief Initialize UART configuration defaults
 *
 * The user is expected to really expected to provide
 * the configuration they want.
 *
 * @param config
 */
void uart_default_config(struct uart_config *config)
{
    config->active = true;
    config->speed = 9600;
    config->data_bits = 8;
    config->stop_bits = 1;
    config->parity = UART_PARITY_NONE;
    config->flow_control = UART_FLOWCONTROL_NONE;
}
