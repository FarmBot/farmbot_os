#!/bin/bash

VERSION=`cat VERSION`
echo "MAKING IMAGES!"
echo "VERSION: $VERSION"
echo "NERVES_TARGET: $NERVES_TARGET"
echo ""

echo "Cleaning previous builds"
rm -rf _images/all/*$NERVES_TARGET-$VERSION*
rm -rf _images/$NERVES_TARGET/*

echo "Building firmware"
mix firmware

echo "Copying rootfs..."
cp ../NERVES_SYSTEM_$NERVES_TARGET/images/nerves_system_$NERVES_TARGET.img \
_images/$NERVES_TARGET/farmbot.rootfs-$NERVES_TARGET-$VERSION.img

echo "Renaming firmware"
mv _images/$NERVES_TARGET/farmbot.fw _images/$NERVES_TARGET/farmbot-$NERVES_TARGET-$VERSION.fw

echo "Building firmware image"
fwup -a -t complete -i _images/$NERVES_TARGET/farmbot-$NERVES_TARGET-$VERSION.fw \
-d _images/$NERVES_TARGET/farmbot-$NERVES_TARGET-$VERSION.img

mkdir -p _images/all

echo "Copying images"
cp _images/$NERVES_TARGET/*$NERVES_TARGET-$VERSION* _images/all
