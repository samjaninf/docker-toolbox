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

log "Creating .ssh folder."
mkdir -p /opt/sitepilot/home/.ssh
chmod 700 /opt/sitepilot/home/.ssh

if [ ! -z "$USER_PRIVATE_KEY" ]; then 
    log "Saving user private key."
    echo "$USER_PRIVATE_KEY" > /opt/sitepilot/home/.ssh/id_rsa
    chmod 600 /opt/sitepilot/home/.ssh/id_rsa
fi

if [ ! -z "$USER_AUTHORIZED_KEYS" ]; then 
    log "Saving user authorized keys."
    echo "$USER_AUTHORIZED_KEYS" > /opt/sitepilot/home/.ssh/authorized_keys
    chmod 600 /opt/sitepilot/home/.ssh/authorized_keys
fi

chown -R $BUILD_USER_NAME:$BUILD_USER_GROUP /opt/sitepilot/home/.ssh

log "Updating user password."
echo "$BUILD_USER_NAME:$USER_PASSWORD" | chpasswd

log "Updating user name."
usermod -l $USER_NAME $BUILD_USER_NAME

log "Removing sudo privileges."
sed -i '$ d' /etc/sudoers

log "Done!"

exec "$@"