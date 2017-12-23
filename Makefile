ifeq ($(ERTS_DIR),)
ERTS_DIR = $(shell erl -eval "io:format(\"~s/erts-~s~n\", [code:root_dir(), erlang:system_info(version)])" -s init stop -noshell)
ifeq ($(ERTS_DIR),)
   $(error Could not find the Erlang installation. Check to see that 'erl' is in your PATH)
endif
endif

CFLAGS = -fPIC -Wl,-undefined -Wl,dynamic_lookup -shared
ERL_FLAGS = -I$(ERTS_DIR)/include
CC ?= $(CROSSCOMPILER)cc

all:
	$(CC) $(ERL_FLAGS) $(CFLAGS) -o priv/build_calendar.so c_src/build_calendar.c

clean:
	$(RM) build_calendar.* priv/build_calendar.*
