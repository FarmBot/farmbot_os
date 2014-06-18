Command line flash tool installation
==========================

(in progress)

sudo apt-get install gcc-avr avr-libc avrdude python-configobj python-jinja2 python-serial

mkdir tmp

cd tmp

git clone https://github.com/miracle2k/python-glob2

cd python-glob2

sudo python setup.py install


git clone git://github.com/amperka/ino.git

make install


Command line flash tool use
==========================

ino build
ino upload
