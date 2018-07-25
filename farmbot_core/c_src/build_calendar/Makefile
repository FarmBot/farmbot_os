ifeq ($(ERL_EI_INCLUDE_DIR),)
$(error ERL_EI_INCLUDE_DIR not set. Invoke via mix)
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR)

NIF_LDFLAGS += -fPIC -shared
NIF_CFLAGS ?= -fPIC -O2 -Wall

NIF=priv/build_calendar.so

ifeq ($(CROSSCOMPILE),)
ifeq ($(shell uname),Darwin)
NIF_LDFLAGS += -undefined dynamic_lookup
endif
endif

.PHONY: all clean

all: $(NIF)

$(NIF): c_src/build_calendar/build_calendar.c
	$(CC) $(ERL_CFLAGS) $(NIF_CFLAGS) $(ERL_LDFLAGS) $(NIF_LDFLAGS) -o $@ $<

clean:
	$(RM) $(NIF)
