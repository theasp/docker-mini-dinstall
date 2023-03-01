#!/bin/bash

export ARCHITECTURES="${ARCHITECTURES:-all, i386, amd64}"
export EXTRA_KEYRING="${EXTRA_KEYRING:-/app/etc/extra-keyring.gpg}"
export ARCHIVE_STYLE="${ARCHIVE_STYLE:-flat}"
export EMAIL="${EMAIL:-nobody}"
export GPG_KEY="${REPO_KEY:-/app/etc/key.gpg}"
export GPG_KEY_AGE=${REPO_KEY_AGE:-3650}
export REPO_NAME="${REPO_NAME:-Unknown APT Repository}"
export REPO_DIR=/app/repo
export PIDFILE=${REPO_DIR}/mini-dinstall/mini-dinstall.lock
export LOGFILE=${REPO_DIR}/mini-dinstall/mini-dinstall.log
export MINI_DINSTALL_CONFIG=/tmp/mini-dinstall.conf

for dir in /app/etc /app/repo /app/repo/mini-dinstall /app/repo/mini-dinstall/incoming; do
  mkdir -p "${dir}"
  chown "${USER_UID}:${USER_GID}" "${dir}" || true
done


case ${VERIFY_SIGS:-true} in
  true|yes) VERIFY_SIGS=yes;;
  *)        VERIFY_SIGS=no;;
esac

case ${KEEP_OLD:-true} in
  true|yes) KEEP_OLD=yes;;
  *)        KEEP_OLD=no;;
esac

case ${RESTRICT_CHANGES_FILES:-false} in
  true|yes) RESTRICT_CHANGES_FILES=yes;;
  *)        RESTRICT_CHANGES_FILES=no;;
esac


export VERIFY_SIGS KEEP_OLD

envsubst < /app/supervisord.d/mini-dinstall.envsubst > /app/supervisord.d/mini-dinstall.conf

if [[ -e $GPG_KEY ]]; then
  log info "Importing GPG key ${GPG_KEY}"
  sudo -u "${USER_NAME}" -H gpg2 --batch --import < "${GPG_KEY}"
else
  expiry=$(date +%F --date="+${GPG_KEY_AGE} days")

  log info "Generating GPG key ${GPG_KEY} that expires ${expiry}"
  (
    umask 0077;
    sudo -u "${USER_NAME}" -H gpg2 --batch --yes --passphrase '' --quick-gen-key "$REPO_NAME" default default "${expiry}";
    sudo -u "${USER_NAME}" -H gpg2 --batch --yes --export-secret-key > "${GPG_KEY}"
  )
fi

# Make sure the GPG key is unreadable by anyone else
chmod 0600 "${GPG_KEY}"

# Export a copy of the key to key.asc
if [ ! -f /app/repo/repository-key.asc ]; then
  log info "Exporting GPG public key"
  sudo -u "${USER_NAME}" -H bash -c 'gpg --export -a > /app/repo/repository-key.asc'
fi

sudo -u "${USER_NAME}" rm -f "${PIDFILE}"

# If a config is provided use it
if [[ -e /app/etc/mini-dinstall.conf ]]; then
  cp /app/etc/mini-dinstall.conf "${MINI_DINSTALL_CONFIG}"
else
  envsubst < /app/mini-dinstall.conf.envsubst > "${MINI_DINSTALL_CONFIG}"

  # If REPO_SECTIONS is set, use the repos from there, otherwise use
  # the existing repo directories.
  if [[ $REPO_SECTIONS ]]; then
    for name in $REPO_SECTIONS; do
      echo
      echo "[${name}]"
    done >> "${MINI_DINSTALL_CONFIG}"
  else
    for name in /app/repo/*; do
      name=$(basename "${name}")

      if [[ -d $name ]] && [[ $name != mini-dinstall ]]; then
        echo
        echo "[${name}]"
      fi
    done >> "${MINI_DINSTALL_CONFIG}"
  fi
fi
