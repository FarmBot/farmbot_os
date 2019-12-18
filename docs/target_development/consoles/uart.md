# UART Console

Accessing an target UART console

## Setup

No additional setup is required for setting up the UART console on the target.

On your `host` machine, you need to have a console cable, as well as a console client.
The console cable must be 3.3 volts, **not** 5 volts. a 5 volt cable will harm your
Raspberry Pi. Here are some known working cables:
* https://www.amazon.com/Converter-Terminated-Galileo-BeagleBone-Minnowboard/dp/B06ZYPLFNB
* https://www.amazon.com/DSD-TECH-Adapter-FT232RL-Compatible/dp/B07BBPX8B8
* https://www.amazon.com/JANSANE-PL2303TA-Serial-Console-Raspberry/dp/B07D9R5JFK

The most common client is probably `screen` on *Nix based systems or `putty` on windows. 
See your distribution's package manager for installation and usage instructions.

## Connecting

Connecting to a console is dependent on your particular client. Here is an example 
`screen` command:

```bash
screen /dev/ttyUSB0 115200
```

## Disconnecting

Disconnecting is also dependent on your particular client. To exit screen, 
issue a `ctrl+\+y` sequence to escape the console.