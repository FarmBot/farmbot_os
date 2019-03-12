ALL :=
CLEAN :=

PREFIX = $(MIX_COMPILE_PATH)/../priv
BUILD = $(MIX_COMPILE_PATH)/../obj

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR) -lei

CFLAGS += -fPIC --std=c11
LDFLAGS += -fPIC -shared

ifeq ($(ERL_EI_INCLUDE_DIR),)
$(warning ERL_EI_INCLUDE_DIR not set. Invoke via mix)
endif

ESQLITE_SRC = $(MIX_DEPS_PATH)/esqlite/c_src
ESQLITE_BUILD = $(MIX_BUILD_PATH)/lib/esqlite/obj
ESQLITE_PREFIX = $(MIX_BUILD_PATH)/lib/esqlite/priv

.PHONY: fbos_arduino_firmware fbos_clean_arduino_firmware all clean

SQLITE_CFLAGS := -DSQLITE_THREADSAFE=1 \
-DSQLITE_USE_URI \
-DSQLITE_ENABLE_FTS3 \
-DSQLITE_ENABLE_FTS3_PARENTHESIS

all: $(PREFIX) \
		$(BUILD) \
		$(PREFIX)/build_calendar.so \
		$(ESQLITE_BUILD) \
		$(ESQLITE_PREFIX) \
		$(ESQLITE_PREFIX)/esqlite3_nif.so

clean: 
	$(RM) $(PREFIX)/*.so
	$(RM) $(ESQLITE_PREFIX)/*.so

## ARDUINO FIRMWARE

fbos_arduino_firmware:
	cd c_src/farmbot-arduino-firmware && make all BUILD_DIR=$(PWD)/_build FBARDUINO_FIRMWARE_SRC_DIR=$(PWD)/c_src/farmbot-arduino-firmware/src BIN_DIR=$(PWD)/priv

fbos_clean_arduino_firmware:
	cd c_src/farmbot-arduino-firmware && make clean BUILD_DIR=$(PWD)/_build FBARDUINO_FIRMWARE_SRC_DIR=$(PWD)/c_src/farmbot-arduino-firmware/src BIN_DIR=$(PWD)/priv

## ESQLITE NIF HACK

$(ESQLITE_PREFIX)/esqlite3_nif.so: $(ESQLITE_BUILD)/sqlite3.o $(ESQLITE_BUILD)/queue.o $(ESQLITE_BUILD)/esqlite3_nif.o
	$(CC) -o $@ $(ERL_LDFLAGS) $(LDFLAGS) $^

$(ESQLITE_BUILD)/esqlite3_nif.o: $(ESQLITE_SRC)/esqlite3_nif.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) $(SQLITE_CFLAGS) -o $@ $<

$(ESQLITE_BUILD)/queue.o: $(ESQLITE_SRC)/queue.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) $(SQLITE_CFLAGS) -o $@ $<

$(ESQLITE_BUILD)/sqlite3.o: $(ESQLITE_SRC)/sqlite3.c
	$(CC) -c $(CFLAGS) $(SQLITE_CFLAGS) -o $@ $<

## BUILD CALENDAR NIF

$(PREFIX)/build_calendar.so: $(BUILD)/build_calendar.o
	$(CC) -o $@ $(ERL_LDFLAGS) $(LDFLAGS) $^

$(BUILD)/build_calendar.o: c_src/build_calendar/build_calendar.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) -o $@ $<

## DIRECTORIES

$(PREFIX):
	mkdir -p $(PREFIX)

$(BUILD):
	mkdir -p $(BUILD)

$(ESQLITE_BUILD):
	mkdir -p $(ESQLITE_BUILD)

$(ESQLITE_PREFIX):
	mkdir -p $(ESQLITE_PREFIX)
