# FarmBot OTP App

## Normal Subsystems

the `farmbot` OTP app is the container Nerves based application. It contains mostly
glue code between all the subsystems in the other applications along with it's own
platform specific subsystems.

### CeleryScript System Calls

The "official" implementation of all the CeleryScript syscalls. These calls are mostly
glue to other existing implementations from the other otp apps.

### Lua Subsystem

The implementation of the embedded scripting language inside CeleryScript.
Also contains glue code for glueing together the real implementation to the
Lua vm.

### Configurator Subsystem

HTTP server responsible for configuring the running FarmBot OS instance. Will
server a web page that allows a user to supply a username, password, network credentials
etc.

## Platform specific subsystems

the `farmbot_os` OTP app contains target/hardware specific systems. This code is
located in the `platform` directory.

### Network subsystem

Responsible for getting FarmBot connected to the (inter)net. If no network
configuration is available, FarmBot will create a captive portal access
point to allow external devices to configure it.

### GPIO subsystem

Responsible for implementing LED and Button support at the hardware level.

### RTC subsystem

Responsible for syncronizing network time to an attached hardware clock.

### Info Worker subsystem

Responsible for simple workers that handle things like

* CPU temperature
* CPU usage
* memory usage
* disk usage
