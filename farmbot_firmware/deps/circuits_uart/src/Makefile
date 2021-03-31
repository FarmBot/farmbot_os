# Makefile for building the NIF
#
# Makefile targets:
#
# all/install   build and install the NIF
# clean         clean build products and intermediates
#
# Variables to override:
#
# BUILD         where to store intermediate files (defaults to src directory)
# PREFIX        path to the installation direction (defaults to ./priv)
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# ERL_CFLAGS	additional compiler flags for files using Erlang header files
# ERL_EI_INCLUDE_DIR include path to ei.h (Required for crosscompile)
# ERL_EI_LIBDIR path to libei.a (Required for crosscompile)
# LDFLAGS	linker flags for linking all binaries
# ERL_LDFLAGS	additional linker flags for projects referencing Erlang libraries
# MIX_APP_PATH  path to the build directory

PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/obj

CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter
CFLAGS += -std=c99 -D_GNU_SOURCE

###################
# If you're having trouble with the serial port, commenting in the following line
# may give some more hints. By default, log messages are appended to circuits_uart.log.
# See src/circuits_uart.c to change this. Be sure to rebuild everything by invoking
# "mix clean" and then "mix compile", so that the flag takes effect.
#CFLAGS += -DDEBUG

SRC=$(wildcard src/*.c)

# Windows-specific updates
ifeq ($(OS),Windows_NT)

# Libraries needed to enumerate serial ports
LDFLAGS += -lSetupapi -lCfgmgr32

# On Windows, make defaults CC=cc and
# cc doesn't exist with mingw
ifeq ($(CC),cc)
CC = gcc
endif

# Statically link on Windows to simplify distribution of pre-built version
LDFLAGS += -static

# To avoid linking issues, use copy/pasted version of ei.
# YES, this is unfortunate, but it was easier than
# battling mingw/visual c++ differences.
ERL_CFLAGS = -I"$(CURDIR)/src/ei_copy"
SRC += $(wildcard src/ei_copy/*.c)
CFLAGS += -DUNICODE

EXEEXT=.exe

RM=del

else
# Non-Windows

# -lrt is needed for clock_gettime() on linux with glibc before version 2.17
# (for example raspbian wheezy)
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
  LDFLAGS += -lrt
endif

# The paths to the EI library and header files are either passed in when
# compiled by Nerves (crosscompiled builds) or determined by mix.exs for
# host builds.
ifeq ($(ERL_EI_INCLUDE_DIR),)
$(error ERL_EI_INCLUDE_DIR not set. Invoke via mix)
endif
ifeq ($(ERL_EI_LIBDIR),)
$(error ERL_EI_LIBDIR not set. Invoke via mix)
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR) -lei

# If compiling on OSX and not crosscompiling, include CoreFoundation and IOKit
ifeq ($(CROSSCOMPILE),)
ifeq ($(shell uname),Darwin)
LDFLAGS += -framework CoreFoundation -framework IOKit
endif
endif

endif

HEADERS =$(wildcard src/*.h)
OBJ=$(SRC:src/%.c=$(BUILD)/%.o)
PORTEXE=$(PREFIX)/circuits_uart$(EXEEXT)

all: install

install: $(PREFIX) $(BUILD) $(BUILD)/ei_copy $(PORTEXE)

$(OBJ): $(HEADERS) src/Makefile

$(BUILD)/%.o: src/%.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) -o $@ $<

$(PORTEXE): $(OBJ)
	$(CC) $^ $(ERL_LDFLAGS) $(LDFLAGS) -o $@

ifeq ($(OS),Windows_NT)
$(PREFIX) $(BUILD) $(BUILD)/ei_copy:
	mkdir $(subst /,\\,$@)

clean:
	-$(RM) $(subst /,\,$(PORTEXE) $(OBJ))
else
$(PREFIX) $(BUILD) $(BUILD)/ei_copy:
	mkdir -p $@

clean:
	$(RM) $(PORTEXE) $(OBJ)
endif

.PHONY: all clean install
