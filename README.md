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

Rapsberry PI
------------

Update the RPi, install ruby, firmate and the arduino IDE

sudo apt-get update

sudo apt-get install git-core

sudo apt-get install ruby

sudo apt-get install arduino

gem install firmata

gem install bson

gem install mongo

gem install mongoid


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

Use "ruby runtime.rb" to start the runtime part of the software. This will read the datbase and send commands to the hardware.

Use "ruby menu.rb" to start the interface. A menu will appear. Type the command needed and press enter. It is also possible to add a list of commands to the file 'testcommands.csv' and use the menu to execute the file.

Still to do
===========

* A lot of the settings for pins, sleep times, timeouts and motor inversions have to be moved to configuration.
* Check if it works with the nema 17 motor from OpenBuilds


