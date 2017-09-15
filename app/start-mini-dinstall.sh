#!/bin/bash

mkdir -p /app/repo/mini-dinstall
mkdir -p /app/repo/mini-dinstall/incoming

CONFIG=/tmp/mini-dinstall.conf

if [[ -e /app/etc/mini-dinstall.conf ]]; then
  cp /app/etc/mini-dinstall.conf ${CONFIG}
else
  envsubst < /app/mini-dinstall.conf.envsubst > ${CONFIG}

  if [[ "$REPO_SECTIONS" ]]; then
    for name in $REPO_SECTIONS; do
      echo
      echo "[$name]"
    done >> ${CONFIG}
  else
    for name in /app/repo/*; do
      name=$(basename $name)
      
      if [[ -d "$name" ]] && [[ "$name" != mini-dinstall ]]; then
        echo 
        echo "[$name]"
      fi
    done >> ${CONFIG}
  fi
fi

START='mini-dinstall --config ${CONFIG}'
STOP='mini-dinstall -k'
CHECK='test -e "${PIDFILE}" && kill -0 $(cat "${PIDFILE}")'

exec /app/signal-wrapper.sh "$START" "$STOP" "$CHECK"
