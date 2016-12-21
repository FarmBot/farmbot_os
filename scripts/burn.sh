#!/bin/bash
CWD=$PWD # this should be from the root of the project
OS_DIR=$CWD/apps/os
cd $OS_DIR
mix firmware.burn
