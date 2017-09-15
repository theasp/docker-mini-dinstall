#!/bin/bash

export ARCHITECTURES="${ARCHITECTURES:-all, i386, amd64}"
export EXTRA_KEYRING="${EXTRA_KEYRING:-/app/etc/extra-keyring.gpg}"
export ARCHIVE_STYLE="${ARCHIVE_STYLE:-flat}"
export EMAIL="${EMAIL:-nobody}"
export GPG_KEY="${REPO_KEY:-/app/etc/key.gpg}"
export REPO_NAME="${REPO_NAME:-Unknown APT Repository}"
export REPO_DIR=/app/repo
export PIDFILE=/tmp/mini-dinstall.lock
export LOGFILE=${REPO_DIR}/mini-dinstall/mini-dinstall.log

mkdir -p /app/etc
mkdir -p /app/repo

chown $USER_UID:$USER_GID /app/repo || true

case ${VERIFY_SIGS:-true} in
  true|yes) VERIFY_SIGS=1;;
  *) VERIFY_SIGS=0;;
esac

case ${KEEP_OLD:-true} in
  true|yes) KEEP_OLD=1;;
  *) KEEP_OLD=0;;
esac

export VERIFY_SIGS KEEP_OLD

envsubst < /app/supervisord.d/mini-dinstall.envsubst > /app/supervisord.d/mini-dinstall.conf

if [[ -e "$GPG_KEY" ]]; then
  log info "Importing GPG key $GPG_KEY"
  sudo -u $USER_NAME -H gpg2 --batch --import < $GPG_KEY
else
  log info "Generating GPG key $GPG_KEY"
  (umask 0077;   
   sudo -u $USER_NAME -H gpg2 --batch --yes --passphrase '' --quick-gen-key "$REPO_NAME";
   sudo -u $USER_NAME -H gpg2 --batch --yes --export-secret-key > $GPG_KEY)
fi

# Make sure the GPG key is unreadable by anyone else
chmod 0600 $GPG_KEY

# Export a copy of the key to key.asc
if [ ! -f /app/repo/repository-key.asc ]; then
  log info "Exporting GPG public key"
  sudo -u $USER_NAME -H bash -c 'gpg --export -a > /app/repo/repository-key.asc'
fi

sudo -u $USER_NAME rm -f $PIDFILE
