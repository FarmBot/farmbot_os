farmbot-controller
==================

This software is responsible for receiving the commands from the 'farmbot cloud backend', execute them and report back the results.

Technicals
----------

* Written in Ruby
* Data is stored in nedb
* Running on Raspberry Pi
* Sends commands to hardware using firmata
* Hardware is an Arduino Mega with a RAMPS 1.4 board
* Communication with cloud using skynet
