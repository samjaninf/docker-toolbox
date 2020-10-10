#!/bin/sh
set -e 

log() {
    echo "[ENTRYPOINT] $1"
}

if [ -z "$USER_NAME" ]; then 
    log "No user name found in environment."
    exit 1
fi

if [ -z "$USER_PASSWORD" ]; then 
    log "No user password found in environment."
    exit 1
fi

log "Updating user name."
usermod -l $USER_NAME $BUILD_USER_NAME

log "Updating user password."
echo "$USER_NAME:$USER_PASSWORD" | chpasswd 

log "Removing sudo privileges."
sed -i '$ d' /etc/sudoers

log "Done!"

exec "$@"