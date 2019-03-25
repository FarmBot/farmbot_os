PREFIX = $(MIX_COMPILE_PATH)/../priv
BUILD = $(MIX_COMPILE_PATH)/../obj

ifeq ($(MIX_COMPILE_PATH),)
$(error Something is wrong with mix. Pls fix)
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR) -lei

CFLAGS += -fPIC --std=c11
LDFLAGS += -fPIC -shared

ifeq ($(MIX_TARGET),host)
else
# oof
$(shell $(RM) $(PREFIX)/*.so $(BUILD)/*.o)
endif

ifeq ($(ERL_EI_INCLUDE_DIR),)
$(warning ERL_EI_INCLUDE_DIR not set. Invoke via mix)
endif

.PHONY: all clean

all: $(PREFIX) \
		$(BUILD) \
		$(PREFIX)/build_calendar.so

clean:
	$(RM) $(PREFIX)/*.so

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
