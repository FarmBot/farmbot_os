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

#ifdef __linux__
#include <dirent.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/serial.h>
#include <string.h>
#include <linux/limits.h>

#include "uart_enum.h"

/* Linux serial port detection strategies
 *
 * There appears to be two main ways of detecting attached serial ports:
 *
 *   1. Call udevadm:
 *      udevadm info --query=property -p $(udevadm info -q path -n /dev/ttyUSB0)
 *   2. Scan the udev directories (e.g., /run/udev/data)
 *   3. Scan /sys/class/tty
 *
 * The udev approaches seem to be preferred, but since Nerves doesn't run
 * udev, I implemented option 3. It seems to work.
 */

static int has_string_prefix(const char *prefix, const char *s)
{
    size_t len = strlen(prefix);
    return strncmp(prefix, s, len) == 0;
}

static int is_tty_filename(const struct dirent *d)
{
    // Check the device filename against a list of known serial
    // port types. This list was found at
    // http://code.qt.io/cgit/qt/qtserialport.git/tree/src/serialport/qserialportinfo_unix.cpp

    const char *name = d->d_name;
    if (has_string_prefix("ttyS", name) ||         // Standard UART 8250 and etc.
            has_string_prefix("ttyO", name) ||     // OMAP UART 8250 and etc.
            has_string_prefix("ttyUSB", name) ||   // USB/serial converters PL2303 and etc.
            has_string_prefix("ttyACM", name) ||   // CDC_ACM converters
            has_string_prefix("ttyGS", name) ||    // Gadget serial device
            has_string_prefix("ttyMI", name) ||    // MOXA pci/serial converters
            has_string_prefix("ttymxc", name) ||   // Motorola IMX serial ports
            has_string_prefix("ttyAMA", name) ||   // AMBA serial device for embedded platforms
            has_string_prefix("ttyTHS", name) ||   // Serial device for embedded platforms on ARM
            has_string_prefix("rfcomm", name) ||   // Bluetooth serial device
            has_string_prefix("ifcomm", name) ||   // IrDA serial device
            has_string_prefix("tnt", name))        // Virtual tty0tty serial device
        return 1;
    else
        return 0;
}

static int try_read_all(const char *directory, const char *filename, char **result)
{
    static const size_t max_filesize = 4096;

    int rc = 0;
    char *path;
    if (asprintf(&path, "%s/%s", directory, filename) < 0)
        return 0;

    FILE *fp = fopen(path, "r");
    free(path);
    if (fp) {
        *result = malloc(max_filesize);
        size_t amount_read = fread(*result, 1, max_filesize - 1, fp);
        fclose(fp);
        if (amount_read != 0) {
            // NULL terminate the string
            (*result)[amount_read] = '\0';
            rc = 1;
        } else
            free(*result);
    }
    return rc;
}

static int try_read_first_line(const char *directory, const char *filename, char **result)
{
    int rc = try_read_all(directory, filename, result);
    if (rc) {
        char *newline = strchr(*result, '\n');
        if (newline)
            *newline = '\0';
    }
    return rc;
}

static int try_hex_read(const char *directory, const char *filename, int *result)
{
    char *str;
    int rc = try_read_first_line(directory, filename, &str);
    if (rc) {
        *result = (int) strtol(str, NULL, 16);
        free(str);
    }
    return rc;
}

static int get_serialport_info(const char *sys_devices_path, struct serial_info *info)
{
    int rc = try_read_first_line(sys_devices_path, "manufacturer", &info->manufacturer);
    rc |= try_read_first_line(sys_devices_path, "serial", &info->serial_number);
    rc |= try_hex_read(sys_devices_path, "idVendor", &info->vid);
    rc |= try_hex_read(sys_devices_path, "idProduct", &info->pid);
    rc |= try_read_first_line(sys_devices_path, "product", &info->description);

    if (info->manufacturer && info->vid == 0) {
        // Try to get the vid from the manufacturer field.
        info->vid = (int) strtol(info->manufacturer, NULL, 16);
    }
    if (info->description && info->pid == 0) {
        info->pid = (int) strtol(info->description, NULL, 16);
    }
    return rc;
}

static char *parse_uevent(const char *contents, const char *key)
{
    // Find the key. These are short and simple files, so
    // this code is a little naive.
    const char *location = strstr(contents, key);
    if (!location)
        return NULL;

    // Skip past the key and the equal sign.
    location += strlen(key) + 1;
    const char *end = strchr(location, '\n');
    size_t len = (end != NULL) ? (size_t) (end - location) : strlen(location);
    char *value = malloc(len + 1);
    memcpy(value, location, len);
    value[len] = '\0';
    return value;
}

static char *get_driver(const char *tty_path)
{
    char *uevent_str;
    char *driver = NULL;
    if (try_read_all(tty_path, "device/uevent", &uevent_str)) {
        driver = parse_uevent(uevent_str, "DRIVER");
        free(uevent_str);
    }
    return driver;
}

/**
 * @brief Check whether the serial8250 driver is attached to real hardware
 *
 * The idea for how to check this condition was found in the Qt serial port
 * detection code.
 *
 * @param devname E.g., "ttyS0"
 * @return 0 if not, 1 if so
 */
static int is_real_serial8250(const char *devname)
{
    char *devpath;
    if (asprintf(&devpath, "/dev/%s", devname) < 0)
        return 0;

    int fd = open(devpath, O_RDWR | O_NONBLOCK | O_NOCTTY);
    free(devpath);
    if (fd != -1) {
        struct serial_struct serinfo;
        int rc = ioctl(fd, TIOCGSERIAL, &serinfo);
        close(fd);
        if (rc >= 0 && serinfo.type != PORT_UNKNOWN)
            return 1;
    }
    return 0;
}

/**
 * @brief Check whether this serial port is a real one
 *
 * @param devname E.g., "ttyS0"
 * @param tty_path
 * @return 0 if not, 1 if so
 */
static int is_real_serialport(const char *devname, const char *tty_path)
{
    int rc;
    char *driver = get_driver(tty_path);
    if (driver) {
        if (strcmp(driver, "serial8250") == 0 &&
                !is_real_serial8250(devname))
            rc = 0;
        else
            rc = 1;
        free(driver);
    } else {
        // No driver. The tnt and rfcomm ports don't show
        // a driver
        if (has_string_prefix("rfcomm",devname) ||
            has_string_prefix("tnt", devname))
            rc = 1;
        else
            rc = 0;
    }
    return rc;
}

struct serial_info *find_serialports()
{
    struct dirent **namelist;
    struct serial_info *info = NULL;

    int n = scandir("/sys/class/tty", &namelist, is_tty_filename, NULL);
    if (n < 0)
        return info;

    for (int i = 0; i < n; i++) {
        char *filepath = NULL;
        if (asprintf(&filepath, "/sys/class/tty/%s", namelist[i]->d_name) < 0)
            break;

        if (!is_real_serialport(namelist[i]->d_name, filepath)) {
            free(filepath);
            continue;
        }

        char symlink[PATH_MAX];
        ssize_t rc = readlink(filepath, symlink, sizeof(symlink));
        if (rc > 0) {
            symlink[rc] = 0;
            char *info_filepath = NULL;
            if (asprintf(&info_filepath, "/sys/class/tty/%s", symlink) < 0)
                break;

            struct serial_info *new_info = serial_info_alloc();
            new_info->name = strdup(namelist[i]->d_name);
            while (info_filepath[0] != '\0') {
                if (get_serialport_info(info_filepath, new_info))
                    break;

                // Go up a directory
                char *pos = strrchr(info_filepath, '/');
                if (pos != NULL)
                    *pos = '\0';
            }
            free(info_filepath);
            new_info->next = info;
            info = new_info;
        }
        free(filepath);
        free(namelist[i]);
    }
    free(namelist);
    return info;
}
#endif
