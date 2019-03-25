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

.PHONY: all clean

SQLITE_CFLAGS := -DSQLITE_THREADSAFE=1 \
-DSQLITE_USE_URI \
-DSQLITE_ENABLE_FTS3 \
-DSQLITE_ENABLE_FTS3_PARENTHESIS

all: $(ESQLITE_BUILD) \
		$(ESQLITE_PREFIX) \
		$(ESQLITE_PREFIX)/esqlite3_nif.so

clean:
	$(RM) $(ESQLITE_PREFIX)/*.so

## ESQLITE NIF HACK

$(ESQLITE_PREFIX)/esqlite3_nif.so: $(ESQLITE_BUILD)/sqlite3.o $(ESQLITE_BUILD)/queue.o $(ESQLITE_BUILD)/esqlite3_nif.o
	$(CC) -o $@ $(ERL_LDFLAGS) $(LDFLAGS) $^

$(ESQLITE_BUILD)/esqlite3_nif.o: $(ESQLITE_SRC)/esqlite3_nif.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) $(SQLITE_CFLAGS) -o $@ $<

$(ESQLITE_BUILD)/queue.o: $(ESQLITE_SRC)/queue.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) $(SQLITE_CFLAGS) -o $@ $<

$(ESQLITE_BUILD)/sqlite3.o: $(ESQLITE_SRC)/sqlite3.c
	$(CC) -c $(CFLAGS) $(SQLITE_CFLAGS) -o $@ $<

## DIRECTORIES

$(ESQLITE_BUILD):
	mkdir -p $(ESQLITE_BUILD)

$(ESQLITE_PREFIX):
	mkdir -p $(ESQLITE_PREFIX)
