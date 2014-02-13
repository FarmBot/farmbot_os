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

Prerequisits
============

Raspberry PI
------------

Update the RPi, install ruby, firmate and the arduino IDE

sudo apt-get update

sudo apt-get install git-core

sudo apt-get install ruby

sudo apt-get install arduino

'bundle install --without test development' from the project directory
OR
'bundle install' (for developers)


Mongo
-----

git clone git://github.com/RickP/mongopi.git

(next steps take a long time)

cd mongopi

scons

sudo scons --prefix=/opt/mongo install

PATH=$PATH:/opt/mongo/bin/

export PATH

sudo mkdir -p /data/db

sudo chown $USER /data/db

start with: /opt/mongo/bin/.mongod --dbpath /data/db

Arduino
-------

Start the arduino IDE in the graphic environment under the start menu / programming / Arduino IDE
Open File / Examples / Firmata / StandardFirmata
Upload to the arduino

FarmBotController
-----------------

use "git clone" to copy the code to the RPi

Usage
=====

Use "ruby sync.rb" to start the skybet communiation ans synchronisation with the farmbot back end

Use "ruby runtime.rb" to start the runtime part of the software. This will read the datbase and send commands to the hardware.

Use "ruby menu.rb" to start the interface. A menu will appear. Type the command needed and press enter. It is also possible to add a list of commands to the file 'testcommands.csv' and use the menu to execute the file.

Author
------

 * Rick Carlino

 * Tim Evers

License
-------

The MIT License

Copyright (c) 2014 Farmbot Project

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
