#!/bin/bash

set -e

export USER_NAME=${USER_NAME:-apt}
export USER_UID=${USER_UID:-1000}
export USER_GID=${USER_GID:-1000}
export USER_HOME=${USER_HOME:-/home/${USER_NAME}}
export USER_SHELL="/bin/bash"
export USER_GECOS=${USER_GECOS:-APT}

export SMTP_RELAY=${SMTP_RELAY:-localhost}
export SMTP_HOSTNAME=${SMTP_HOSTNAME:-$(hostname -f)}

export ARCHITECTURES="${ARCHITECTURES:-all, i386, amd64}"
export EXTRA_KEYRING="${EXTRA_KEYRING:-/app/etc/extra-keyring.gpg}"
export ARCHIVE_STYLE="${ARCHIVE_STYLE:-flat}"
export EMAIL="${EMAIL:-nobody}"
export REPO_KEY="${REPO_KEY:-/app/etc/key.gpg}"
export REPO_KEY_AGE=${REPO_KEY_AGE:-3650}
export REPO_NAME="${REPO_NAME:-Unknown APT Repository}"
export REPO_DIR="${REPO_DIR:-/app/repo}"
export REPO_SECTIONS=${REPO_SECTIONS:-unstable}
export PIDFILE=${REPO_DIR}/mini-dinstall/mini-dinstall.lock
export MINI_DINSTALL_CONFIG=/tmp/mini-dinstall.conf
export MINI_DINSTALL_LOGFILE=${REPO_DIR}/mini-dinstall/mini-dinstall.log

if [[ $DEBUG = true ]]; then
  set -x
fi

getent group "${USER_NAME}" > /dev/null 2>&1 || addgroup --gid="${USER_GID}" "${USER_NAME}"
getent passwd "${USER_NAME}" > /dev/null 2>&1 || adduser --disabled-password --home="${USER_HOME}" --shell="${USER_SHELL}" --gecos="${USER_GECOS}" --uid="${USER_UID}" --gid="${USER_GID}" "${USER_NAME}"

for dir in /app/etc "${REPO_DIR}" "${REPO_DIR}/mini-dinstall" "${REPO_DIR}/mini-dinstall/incoming"; do
  mkdir -p "${dir}"
  chown "${USER_UID}:${USER_GID}" "${dir}" || true
done

chmod 0755 "${REPO_DIR}"
chmod 0755 "${REPO_DIR}/mini-dinstall"
chmod 0775 "${REPO_DIR}/mini-dinstall/incoming"

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


export VERIFY_SIGS KEEP_OLD RESTRICT_CHANGES_FILES

if [[ -e $REPO_KEY ]]; then
  echo "INFO: Importing GPG key ${REPO_KEY}"
  sudo -u "${USER_NAME}" -H gpg2 --batch --import < "${REPO_KEY}"
else
  expiry=$(date +%F --date="+${REPO_KEY_AGE} days")

  echo "INFO: Generating GPG key ${REPO_KEY} that expires ${expiry}"
  (
    umask 0077;
    sudo -u "${USER_NAME}" -H gpg2 --batch --yes --passphrase '' --quick-gen-key "$REPO_NAME" default default "${expiry}";
    sudo -u "${USER_NAME}" -H gpg2 --batch --yes --export-secret-key > "${REPO_KEY}"
  )
fi

# Export a copy of the key to key.asc
if [[ ! -f "${REPO_DIR}/repository-key.asc" ]]; then
  echo "INFO: Exporting GPG public key"
  sudo -u "${USER_NAME}" -H bash -c "gpg --export -a > '${REPO_DIR}'/repository-key.asc"
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
    for dir in "${REPO_DIR}"/*; do
      name=$(basename "${dir}")

      if [[ -d $dir ]] && [[ $name != mini-dinstall ]]; then
        echo
        echo "[${name}]"
      fi
    done >> "${MINI_DINSTALL_CONFIG}"
  fi
fi

exec sudo -u "${USER_NAME}" -H mini-dinstall --config "${MINI_DINSTALL_CONFIG}" --foreground
