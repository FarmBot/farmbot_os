farmbot-controller
==================

This software is responsible for receiving the commands from the 'farmbot cloud backend', execute them and report back the results.

Technicals
----------

* Written in Ruby
* Data is stored in sqlite 3
* Running on Raspberry Pi
* Sends commands to hardware using firmata (soon to be replaced with g-code)
* Hardware is an Arduino Mega with a RAMPS 1.4 board
* Communication with cloud using skynet (machine instant messaging)

Prerequisites
============

Raspberry PI
------------

Update the RPi, install ruby, firmate and the arduino IDE
```
sudo apt-get update
sudo apt-get install git-core ruby-dev sqlite3 arduino bundler
```

retrieving code from github:
```
git clone https://github.com/FarmBot/farmbot-raspberry-pi-controller
```
prepping ruby:
```
cd farmbot-raspberry-pi-controller
sudo gem install bundler
sudo gem install sqlite3 -v '1.3.10'
bundler update
bundle install
```

Setup the database
```
rake db:migrate
```

Arduino
-------

git clone https://github.com/FarmBot/farmbot-arduino-controller

Start the arduino IDE in the graphic environment under the start menu / programming / Arduino IDE
Open File / Examples / Firmata / StandardFirmata
Upload to the arduino

Usage
=====

Use "ruby farmbot.rb" to start hardware control and skynet communication

Use "ruby menu.rb" to start the interface. A menu will appear. Type the command needed and press enter. It is also possible to add a list of commands to the file 'testcommands.csv' and use the menu to execute the file.

To change parameters manually, edit the file "write_db_settings.rb" and run the command "ruby write_db_settings.rb"

During running in the console, a few basic status parameters are displayed:

x 0000 *- y 0000 -- z 0000 *- 

For each axis, the coordinates are shown and the status of the end stops. A "-" means the end stop is not activated, a "*" means the and stop is activated. First the home end point is displayed, then the end-of-line end stop.

Main software structure
=======================

```                                                        
/farmbot.rb +-----> /lib/messaging.rb                   
            |                                           
            |           /lib/messaging/messaging.rb     
            |                                           
            |           /lib/messaging/messagehandler.rb
            |                                           
            +-----> /lib/controller.rb                  
            |                                           
            |                                           
            +-----> /hardware/gcode/ramps.rb            
```

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

