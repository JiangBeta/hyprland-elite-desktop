#!/bin/bash
# YouTube Music wrapper script for wofi launch

export DISPLAY=:0
exec /usr/bin/youtube-music --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage "$@"