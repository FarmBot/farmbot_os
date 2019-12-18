# FarmBot Firmware OTP App

The `farmbot_firmware` OTP application is responsible for maintaining a connection to
the arduino-firmware.

## GCODE encoder/decoder subsystem

The official Farmbot-Arduino-Firmware communicates over UART using a ASCII based
protocol based on CNC GCODE. This subsystem is responsible for translating
the ASCII data into an intermediate representation that can be `transport`ed
proto agnostically. 

## Transport subsystem

This subsystem is responsible for abstracting the details of transporting 
FarmBot GCODEs to/from the firmware implementation. A `transport` will take 
in the intermediate (farmbot specific) representation of a GCODE, and dispatch/handle
it in it's own specific manor. This keeps the usage of the overall application uniform
with or without a firmware plugged in. 

## UART subsystem

Responsible for the official communication mechanism with the official arduino hardware.