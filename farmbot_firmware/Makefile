PREFIX=$(PWD)/priv
BUILD=$(PWD)/_build
ARDUINO_SRC_DIR=$(PWD)/c_src/farmbot-arduino-firmware

.PHONY: all clean fbos_arduino_firmware

all: fbos_arduino_firmware

fbos_arduino_firmware:
	cd $(ARDUINO_SRC_DIR) && \
	make all \
	BUILD_DIR=$(BUILD) \
	FBARDUINO_FIRMWARE_SRC_DIR=$(ARDUINO_SRC_DIR)/src \
	BIN_DIR=$(PREFIX)

clean:
	cd $(ARDUINO_SRC_DIR) && \
	make clean \
	BUILD_DIR=$(BUILD) \
	FBARDUINO_FIRMWARE_SRC_DIR=$(ARDUINO_SRC_DIR)/src \
	BIN_DIR=$(PREFIX)

$(PREFIX):
	mkdir -p $(PREFIX)

$(BUILD):
	mkdir -p $(BUILD)