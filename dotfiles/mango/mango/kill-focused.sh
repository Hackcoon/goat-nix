#!/usr/bin/env bash
# SIGKILL the focused window's PID (mango 0.12.8 has no killclient force)
PID=$(mmsg -g -c 2>/dev/null | grep -oE 'pid: [0-9]+' | head -1 | cut -d' ' -f2)
[ -n "$PID" ] && kill -9 "$PID"
