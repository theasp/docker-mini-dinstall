#!/bin/bash

mkdir -p /app/repo/mini-dinstall
mkdir -p /app/repo/mini-dinstall/incoming

CONFIG=/tmp/mini-dinstall.conf
PIDFILE=${REPO_DIR}/mini-dinstall/mini-dinstall.lock

rm -f $PIDFILE

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

exec mini-dinstall --config ${CONFIG}
