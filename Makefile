.PHONY: all clean
.DEFAULT_GOAL: all

MIX_ENV := $(MIX_ENV)
MIX_TARGET := $(MIX_TARGET)
SLACK_CHANNEL := $(SLACK_CHANNEL)

ifeq ($(MIX_ENV),)
MIX_ENV := dev
endif

ifeq ($(MIX_TARGET),)
MIX_TARGET := host
endif

all: help

help:
	@echo "no"

farmbot_celery_script_clean:
	cd farmbot_celery_script && \
	rm -rf _build deps

farmbot_core_clean:
	cd farmbot_core && \
	make clean && \
	rm -rf priv/*.hex &&\
	rm -rf priv/*.so &&\
	rm -rf ./.*.sqlite3 &&\
	rm -rf _build deps

farmbot_ext_clean:
	cd farmbot_ext && \
	rm -rf ./.*.sqlite3 &&\
	rm -rf _build deps

farmbot_os_clean:
	cd farmbot_os && \
	rm -rf _build deps

clean: farmbot_celery_script_clean farmbot_core_clean farmbot_ext_clean farmbot_os_clean

farmbot_core_test:
	cd farmbot_core && \
	MIX_ENV=test mix deps.get && \
	MIX_ENV=test mix ecto.migrate && \
	MIX_ENV=test mix compile

farmbot_ext_test:
	cd farmbot_ext && \
	MIX_ENV=test SKIP_ARDUINO_BUILD=1 mix deps.get && \
	MIX_ENV=test SKIP_ARDUINO_BUILD=1 mix ecto.migrate && \
	MIX_ENV=test SKIP_ARDUINO_BUILD=1 mix compile

farmbot_os_test:
	cd farmbot_os && \
	MIX_ENV=test SKIP_ARDUINO_BUILD=1 mix deps.get && \
	MIX_ENV=test SKIP_ARDUINO_BUILD=1 mix compile

test: farmbot_core_test farmbot_ext_test farmbot_os_test

farmbot_os_firmware:
	cd farmbot_os && \
	MIX_ENV=$(MIX_ENV) MIX_TARGET=$(MIX_TARGET) mix do deps.get, firmware

farmbot_os_firmware_slack: farmbot_os_firmware
	cd farmbot_os && \
	MIX_ENV=$(MIX_ENV) MIX_TARGET=$(MIX_TARGET) mix farmbot.firmware.slack --channels $(SLACK_CHANNEL)
