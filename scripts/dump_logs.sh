#!/usr/bin/env bash

mkdir -p log/mnt
sudo mount /dev/mmcblk0p3 log/mnt
sqlite3 log/mnt/debug_logs.sqlite3 "SELECT logged_at_dt, message FROM elixir_logs" > log/debug_logs.log
echo log/mnt/debug_log.sqlite3
sudo umount /dev/mmcblk0p3
