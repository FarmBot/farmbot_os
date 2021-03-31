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

#ifdef __APPLE__
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <AvailabilityMacros.h>
#include <sys/param.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/serial/IOSerialKeys.h>

#include "uart_enum.h"

/* This code was largely ported from node-serialport */
// Function prototypes
static kern_return_t FindModems(io_iterator_t *matchingServices);
static io_service_t GetUsbDevice(io_service_t service);

static kern_return_t FindModems(io_iterator_t *matchingServices)
{
    kern_return_t     kernResult;
    CFMutableDictionaryRef  classesToMatch;
    classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    if (classesToMatch != NULL)
    {
        CFDictionarySetValue(classesToMatch,
                             CFSTR(kIOSerialBSDTypeKey),
                             CFSTR(kIOSerialBSDAllTypes));
    }

    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, matchingServices);

    return kernResult;
}

static io_service_t GetUsbDevice(io_service_t service)
{
    IOReturn status;
    io_iterator_t   iterator = 0;
    io_service_t    device = 0;

    if (!service)
        return device;

    status = IORegistryEntryCreateIterator(service,
                                           kIOServicePlane,
                                           (kIORegistryIterateParents | kIORegistryIterateRecursively),
                                           &iterator);

    if (status == kIOReturnSuccess) {
        io_service_t currentService;
        while ((currentService = IOIteratorNext(iterator)) && device == 0) {
            io_name_t serviceName;
            status = IORegistryEntryGetNameInPlane(currentService, kIOServicePlane, serviceName);
            if (status == kIOReturnSuccess && IOObjectConformsTo(currentService, kIOUSBDeviceClassName)) {
                device = currentService;
            } else {
                // Release the service object which is no longer needed
                (void) IOObjectRelease(currentService);
            }
        }

        // Release the iterator
        (void) IOObjectRelease(iterator);
    }

    return device;
}

static void ExtractUsbInformation(struct serial_info *info, IOUSBDeviceInterface  **deviceInterface)
{
    kern_return_t kernResult;

    UInt16 vendorID;
    kernResult = (*deviceInterface)->GetDeviceVendor(deviceInterface, &vendorID);
    if (KERN_SUCCESS == kernResult)
        info->vid = vendorID;

    UInt16 productID;
    kernResult = (*deviceInterface)->GetDeviceProduct(deviceInterface, &productID);
    if (KERN_SUCCESS == kernResult)
        info->pid = productID;
}

struct serial_info *find_serialports()
{
    struct serial_info *info = NULL;

    kern_return_t kernResult;
    io_iterator_t serialPortIterator;
    char bsdPath[MAXPATHLEN];

    FindModems(&serialPortIterator);

    io_service_t modemService;
    kernResult = KERN_FAILURE;
    Boolean modemFound = false;

    // Initialize the returned path
    *bsdPath = '\0';

    while ((modemService = IOIteratorNext(serialPortIterator))) {
        CFTypeRef bsdPathAsCFString;

        bsdPathAsCFString = IORegistryEntrySearchCFProperty(modemService, kIOServicePlane, CFSTR(kIOCalloutDeviceKey), kCFAllocatorDefault, kIORegistryIterateRecursively);

        if (bsdPathAsCFString) {
            Boolean result;

            // Convert the path from a CFString to a C (NUL-terminated)

            result = CFStringGetCString((CFStringRef) bsdPathAsCFString,
                                        bsdPath,
                                        sizeof(bsdPath),
                                        kCFStringEncodingUTF8);
            CFRelease(bsdPathAsCFString);

            if (result)
            {
                struct serial_info *new_info = serial_info_alloc();
                new_info->name = strdup(bsdPath);
                new_info->next = info;
                info = new_info;

                modemFound = true;
                kernResult = KERN_SUCCESS;

                io_service_t device = GetUsbDevice(modemService);

                if (device) {
                    CFStringRef manufacturerAsCFString = (CFStringRef) IORegistryEntryCreateCFProperty(device,
                                                                                                       CFSTR(kUSBVendorString),
                                                                                                       kCFAllocatorDefault,
                                                                                                       0);

                    if (manufacturerAsCFString) {
                        Boolean result;
                        char    manufacturer[MAXPATHLEN];

                        // Convert from a CFString to a C (NUL-terminated)
                        result = CFStringGetCString(manufacturerAsCFString,
                                                    manufacturer,
                                                    sizeof(manufacturer),
                                                    kCFStringEncodingUTF8);

                        if (result)
                            new_info->manufacturer = strdup(manufacturer);

                        CFRelease(manufacturerAsCFString);
                    }

                    CFStringRef serialNumberAsCFString = (CFStringRef) IORegistryEntrySearchCFProperty(device,
                                                                                                       kIOServicePlane,
                                                                                                       CFSTR(kUSBSerialNumberString),
                                                                                                       kCFAllocatorDefault,
                                                                                                       kIORegistryIterateRecursively);

                    if (serialNumberAsCFString) {
                        Boolean result;
                        char    serialNumber[MAXPATHLEN];

                        // Convert from a CFString to a C (NUL-terminated)
                        result = CFStringGetCString(serialNumberAsCFString,
                                                    serialNumber,
                                                    sizeof(serialNumber),
                                                    kCFStringEncodingUTF8);

                        if (result)
                            new_info->serial_number = strdup(serialNumber);

                        CFRelease(serialNumberAsCFString);
                    }

                    IOCFPlugInInterface **plugInInterface = NULL;
                    SInt32        score;
                    HRESULT       res;

                    IOUSBDeviceInterface  **deviceInterface = NULL;

                    kernResult = IOCreatePlugInInterfaceForService(device, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,
                                                                   &plugInInterface, &score);

                    if ((kIOReturnSuccess != kernResult) || !plugInInterface) {
                        continue;
                    }

                    // Use the plugin interface to retrieve the device interface.
                    res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                                             (LPVOID*) &deviceInterface);

                    // Now done with the plugin interface.
                    (*plugInInterface)->Release(plugInInterface);

                    if (res || deviceInterface == NULL) {
                        continue;
                    }

                    // Extract the desired Information
                    ExtractUsbInformation(new_info, deviceInterface);

                    // Release the Interface
                    (*deviceInterface)->Release(deviceInterface);

                    // Release the device
                    (void) IOObjectRelease(device);
                }
            }
        }

        // Release the io_service_t now that we are done with it.
        (void) IOObjectRelease(modemService);
    }

    IOObjectRelease(serialPortIterator);  // Release the iterator.

    return info;
}
#endif
