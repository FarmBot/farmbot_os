# FarmBot Software for the RaspBerry Pi

The "brains" of Farmbot. Responsible for receiving the commands from users or the farmbot-web-app. It executes them and report back the results to any subscribed user(s).

Technical Stuff
---------------

* Written in Ruby.
* Operation scheduling data is stored in SQLite 3.
* Device status info, such as X, Y, Z and calibration data is stored via [PStore](http://ruby-doc.org/stdlib-1.9.2/libdoc/pstore/rdoc/PStore.html)
* Backups to the cloud provided by [Farmbot Web API](https://github.com/farmbot/farmbot-web-api).
* Messaging happens via [MQTT](http://mqtt.org/).
* Communicates with Arduino hardware using the [farmbot-serial gem](https://github.com/FarmBot/farmbot-serial)

# Running in production

```
bundle install
```

If you want to enable auto restarts on crash or memory leak, run:

```
god -c farmbot.god -D
```

If you don't care about autorestarts, just run:

```
ruby farmbot.rb
```

**You can find your device credentials inside of `credentials.yml`**

# Running on Local

If you're running your own local [farmbot web app](https://github.com/farmbot/farmbot-web-app)

`FBENV=development ruby farmbot.rb`


Installation
============

Install Ruby 2.2
----------------

This gem requires Ruby 2.2 minimum. Later versions will work fine as well. As of this writing, a Pi is loaded with 1.9.3 by default.

To remove the old version of Ruby that comes with most RPi distributions:

```
sudo apt-get remove ruby* --purge
```

To upgrade your ruby version, try this:

```
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -L https://get.rvm.io | bash -s stable --ruby
```

This will take about 2 hours a standard Raspberry Pi 2.

Raspberry PI
------------

Update the RPi, install ruby and the arduino IDE

```
sudo apt-get update
sudo apt-get install git-core sqlite3 arduino
```

Clone, install and run:

```
git clone https://github.com/FarmBot/farmbot-raspberry-pi-controller
cd farmbot-raspberry-pi-controller
gem install bundler
bundle install
rake db:setup
ruby farmbot.rb
```

Setup the device:

Go to the [My Farmbot Website](http://my.farmbot.io) (or your private server) and sign up for a Farmbot account.

Then from within the `farmbot-raspberry-pi-controller` project directory run:

```bash
ruby setup.rb
```

Report problems:

We can't fix issues we don't know about. If you are having issues with setup, please [raise an issue with us](https://github.com/FarmBot/farmbot-raspberry-pi-controller/issues/new). This helps us identify confusing steps, common setup issues and other problems.

Arduino
-------

You will need to flash your Arduino with custom firmware. For instructions on how to do this, see [the FarmBot-Arduino github page](https://github.com/FarmBot/farmbot-serial)

Authors
-------

 * Rick Carlino
 * Tim Evers

License
-------

The MIT License

Copyright (c) 2016 Farmbot Project

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
