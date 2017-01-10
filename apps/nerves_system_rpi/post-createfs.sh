#!/bin/sh

set -e

FWUP_CONFIG=$NERVES_DEFCONFIG_DIR/fwup.conf

# Mark the Raspberry Pi kernel image as using device tree
$HOST_DIR/usr/bin/mkknlimg \
    $BINARIES_DIR/zImage $BINARIES_DIR/zImage.mkknlimg

# Run the common post-image processing for nerves
$BR2_EXTERNAL/board/nerves-common/post-createfs.sh $TARGET_DIR $FWUP_CONFIG
