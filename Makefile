# Erlang Nif Stuff
ifeq ($(ERL_EI_INCLUDE_DIR),)
ERL_ROOT_DIR = $(shell erl -eval "io:format(\"~s~n\", [code:root_dir()])" -s init stop -noshell)
ifeq ($(ERL_ROOT_DIR),)
	 $(error Could not find the Erlang installation. Check to see that 'erl' is in your PATH)
endif
ERL_EI_INCLUDE_DIR = "$(ERL_ROOT_DIR)/usr/include"
ERL_EI_LIBDIR = "$(ERL_ROOT_DIR)/usr/lib"
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)

NIF_LDFLAGS += -fPIC -shared
NIF_CFLAGS ?= -fPIC -O2 -Wall

ifeq ($(CROSSCOMPILE),)
ifeq ($(shell uname),Darwin)
NIF_LDFLAGS += -undefined dynamic_lookup
endif
endif

NIF=priv/build_calendar.so
ARDUINO_FW=priv/arduino-firmware.hex
FARMDUINO_FW=priv/farmduino-firmware.hex

ARDUINO_INSTALL_DIR ?= $(HOME)/arduino-1.8.5
ARDUINO_BUILDER=$(ARDUINO_INSTALL_DIR)/arduino-builder

ARDUINO_HARDWARE_DIR = $(ARDUINO_INSTALL_DIR)/hardware
ARDUINO_HARDWARE_FLAGS = -hardware $(ARDUINO_HARDWARE_DIR)

ARDUINO_TOOLS_FLAGS = -tools $(ARDUINO_INSTALL_DIR)/tools-builder \
-tools $(ARDUINO_HARDWARE_DIR)/tools/avr

ARDUINO_LIBS_FLAGS = -built-in-libraries $(ARDUINO_INSTALL_DIR)/libraries

ARDUINO_PREFS_FLAGS = -prefs=build.warn_data_percentage=75 \
	-prefs=runtime.tools.avrdude.path=$(ARDUINO_INSTALL_DIR)/hardware/tools/avr \
	-prefs=runtime.tools.avr-gcc.path=$(ARDUINO_INSTALL_DIR)/hardware/tools/avr

ARDUINO_ARCH_FLAGS = -fqbn=arduino:avr:mega:cpu=atmega2560
ARDUINO_SRC_INO = c_src/farmbot-arduino-firmware/src/src.ino

ARDUINO_BUILD_DIR = $(PWD)/_build/arduino
ARDUINO_CACHE_DIR = $(PWD)/_build/arduino-cache
ARDUINO_BUILD_DIR_FLAGS =	-build-path $(ARDUINO_BUILD_DIR) -build-cache	$(ARDUINO_CACHE_DIR)

ARDUINO_BUILD = $(ARDUINO_BUILDER) \
	$(ARDUINO_HARDWARE_FLAGS) \
	$(ARDUINO_TOOLS_FLAGS) \
	$(ARDUINO_LIBS_FLAGS) \
	$(ARDUINO_ARCH_FLAGS) \
	$(ARDUINO_PREFS_FLAGS) \
	$(ARDUINO_BUILD_DIR_FLAGS) \
	$(ARDUINO_SRC_INO)

all: priv $(NIF) farmbot_arduino_firmware

farmbot_arduino_firmware_build_dirs: $(ARDUINO_BUILD_DIR) $(ARDUINO_CACHE_DIR)

$(ARDUINO_BUILD_DIR):
	mkdir -p $(ARDUINO_BUILD_DIR)

$(ARDUINO_CACHE_DIR):
	mkdir -p $(ARDUINO_CACHE_DIR)

farmbot_arduino_firmware: arduino farmduino

arduino: farmbot_arduino_firmware_build_dirs $(ARDUINO_FW)

farmduino: farmbot_arduino_firmware_build_dirs $(FARMDUINO_FW)

priv:
	mkdir -p priv

$(NIF): c_src/build_calendar.c
	$(CC) $(ERL_CFLAGS) $(NIF_CFLAGS) $(ERL_LDFLAGS) $(NIF_LDFLAGS) -o $@ $<

$(ARDUINO_FW):
	$(shell echo \#define RAMPS_V14 > c_src/farmbot-arduino-firmware/src/Board.h)
	rm -rf $(ARDUINO_BUILD_DIR)/*
	rm -rf $(ARDUINO_CACHE_DIR)/*
	$(ARDUINO_BUILD)
	cp $(ARDUINO_BUILD_DIR)/src.ino.hex $@

$(FARMDUINO_FW):
	$(shell echo \#define FARMDUINO_V10 > c_src/farmbot-arduino-firmware/src/Board.h)
	rm -rf $(ARDUINO_BUILD_DIR)/*
	rm -rf $(ARDUINO_CACHE_DIR)/*
	$(ARDUINO_BUILD)
	cp $(ARDUINO_BUILD_DIR)/src.ino.hex $@

clean:
	$(RM) $(NIF)
	rm -rf $(ARDUINO_BUILD_DIR) $(ARDUINO_CACHE_DIR)
	rm -rf priv/*.hex
