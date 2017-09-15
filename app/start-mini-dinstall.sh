#!/bin/bash

mkdir -p /app/repo/mini-dinstall
mkdir -p /app/repo/mini-dinstall/incoming
chmod 0775 /app/repo/mini-dinstall/incoming

if [[ -e /app/etc/mini-dinstall.conf ]]; then
  cp /app/etc/mini-dinstall.conf /app/mini-dinstall.conf
else
  envsubst < /app/mini-dinstall.conf.envsubst > /app/mini-dinstall.conf

  if [[ "$REPO_SECTIONS" ]]; then
    for name in $REPO_SECTIONS; do
      echo "[$name]"
      echo
    done >> /app/mini-dinstall.conf
  else
    for name in /app/repo/*; do
      name=$(basename $name)
      
      if [[ -d "$name" ]] && [[ "$name" != mini-dinstall ]]; then
        echo "[$name]"
        echo 
      fi
    done >> /app/mini-dinstall.conf
  fi
fi

START='mini-dinstall --config ${CONFIG}'
STOP='mini-dinstall -k'
CHECK='test -e "${PIDFILE}" && kill -0 $(cat "${PIDFILE}")'

exec /app/signal-wrapper.sh "$START" "$STOP" "$CHECK"
