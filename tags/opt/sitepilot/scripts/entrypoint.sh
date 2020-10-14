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

log "Creating .sitepilot dir."
mkdir -p /opt/sitepilot/home/.sitepilot

log "Generating host keys (if not exist)."
SSH_HOST_DSA_KEY=/opt/sitepilot/home/.sitepilot/ssh_host_dsa_key
SSH_HOST_RSA_KEY=/opt/sitepilot/home/.sitepilot/ssh_host_rsa_key
SSH_HOST_ED25519_KEY=/opt/sitepilot/home/.sitepilot/ssh_host_ed25519_key

if [ ! -f "$SSH_HOST_DSA_KEY" ]; then log "Generating dsa key." && ssh-keygen -q -N "" -t dsa -f $SSH_HOST_DSA_KEY; fi
if [ ! -f "$SSH_HOST_RSA_KEY" ]; then log "Generating rsa key." && ssh-keygen -q -N "" -t rsa -b 4096 -f $SSH_HOST_RSA_KEY; fi
if [ ! -f "$SSH_HOST_ED25519_KEY" ]; then log "Generating ed25519 key." && ssh-keygen -q -N "" -t ed25519 -f $SSH_HOST_ED25519_KEY; fi

log "Creating .ssh folder."
mkdir -p /opt/sitepilot/home/.ssh
chmod 700 /opt/sitepilot/home/.ssh

log "Creating symlink to apps folder."
rm -f /opt/sitepilot/home/apps
ln -s /opt/sitepilot/apps /opt/sitepilot/home/apps

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

log "Updating file permissions."
chown -R $BUILD_USER_NAME:$BUILD_USER_GROUP /opt/sitepilot/home

log "Updating user password."
echo "$BUILD_USER_NAME:$USER_PASSWORD" | chpasswd

log "Updating user name."
usermod -l $USER_NAME $BUILD_USER_NAME

log "Updating default shell."
chsh --shell /bin/zsh $USER_NAME

log "Removing sudo privileges."
sed -i '$ d' /etc/sudoers

log "Done!"

exec "$@"