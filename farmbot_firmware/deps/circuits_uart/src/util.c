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

#include "util.h"
#ifdef __APPLE__
#include <mach/clock.h>
#include <mach/mach.h>
#else
#include <time.h>
#endif

#ifdef DEBUG
FILE *log_location;
#endif

/**
 * @return a monotonic timestamp in milliseconds
 */
uint64_t current_time()
{
#ifdef __APPLE__
    clock_serv_t cclock;
    mach_timespec_t mts;

    host_get_clock_service(mach_host_self(), SYSTEM_CLOCK, &cclock);
    clock_get_time(cclock, &mts);
    mach_port_deallocate(mach_task_self(), cclock);

    return ((uint64_t) mts.tv_sec) * 1000 + mts.tv_nsec / 1000000;
#else
    // Linux and Windows support clock_gettime()
    struct timespec tp;
    int rc = clock_gettime(CLOCK_MONOTONIC, &tp);
    if (rc < 0)
        errx(EXIT_FAILURE, "clock_gettime failed?");

    return ((uint64_t) tp.tv_sec) * 1000 + tp.tv_nsec / 1000000;
#endif
}

