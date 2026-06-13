#!/usr/bin/env bash
PIDFILE="/tmp/display-wake-listener.pid"

# Kill any existing wake listener from a previous press
if [[ -f "$PIDFILE" ]]; then
    kill "$(cat $PIDFILE)" 2>/dev/null
    rm -f "$PIDFILE"
fi

hyprctl dispatch dpms off

# Listen for any input activity and wake the display back up
swayidle timeout 1 '' resume 'hyprctl dispatch dpms on && brightnessctl -r' &
echo $! > "$PIDFILE"
