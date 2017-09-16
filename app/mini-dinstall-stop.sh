#!/bin/bash

function waitpids {
  RET=timeout
  COUNT=0
  MAX=5

  while [[ $COUNT -le $MAX ]]; do
    PIDS=
    if [[ -z $PIDS ]]; then
      RET=ok
      break
    fi
    sleep 1
    COUNT=$(( COUNT + 1 ))
  done
}

if [[ -e $PIDFILE ]]; then
  mini-dinstall -k
  waitpids $(pidof mini-dinstall || true)
fi

PIDS=$(pidof mini-dinstall || true)
if [[ "$PIDS" ]]; then
  kill $PIDS
  waitpids $PIDS
fi

PIDS=$(pidof mini-dinstall || true)
if [[ "$PIDS" ]]; then
  kill -9 $PIDS
fi
