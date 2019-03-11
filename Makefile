ALL :=
CLEAN :=

PREFIX = $(MIX_COMPILE_PATH)/../priv
BUILD = $(MIX_COMPILE_PATH)/../obj
# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)

NIF_LDFLAGS += -fPIC -shared
NIF_CFLAGS ?= -fPIC -O2 -Wall

NIF=

ifeq ($(ERL_EI_INCLUDE_DIR),)
$(warning ERL_EI_INCLUDE_DIR not set. Invoke via mix)
endif

.PHONY: fbos_arduino_firmware fbos_clean_arduino_firmware all clean

all: $(PREFIX) $(BUILD) $(PREFIX)/build_calendar.so

clean: 
	$(RM) $(PREFIX)/*.so

fbos_arduino_firmware:
	cd c_src/farmbot-arduino-firmware && make all BUILD_DIR=$(PWD)/_build FBARDUINO_FIRMWARE_SRC_DIR=$(PWD)/c_src/farmbot-arduino-firmware/src BIN_DIR=$(PWD)/priv

fbos_clean_arduino_firmware:
	cd c_src/farmbot-arduino-firmware && make clean BUILD_DIR=$(PWD)/_build FBARDUINO_FIRMWARE_SRC_DIR=$(PWD)/c_src/farmbot-arduino-firmware/src BIN_DIR=$(PWD)/priv

$(PREFIX)/build_calendar.so: $(BUILD)/build_calendar.o
	$(CC) $(ERL_LDFLAGS) $(NIF_LDFLAGS) -o $@ $<

$(BUILD)/build_calendar.o: c_src/build_calendar/build_calendar.c
	$(CC) -c $(ERL_CFLAGS) $(NIF_CFLAGS) -o $@ $<

$(PREFIX):
	mkdir -p $(PREFIX)

$(BUILD):
	mkdir -p $(BUILD)