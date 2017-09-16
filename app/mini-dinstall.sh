#!/bin/bash

START="/app/mini-dinstall-start.sh"
STOP='/app/mini-dinstall-stop.sh'
CHECK='/app/mini-dinstall-check.sh'

exec /app/signal-wrapper.sh "$START" "$STOP" "$CHECK"
