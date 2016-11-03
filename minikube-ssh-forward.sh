#!/bin/bash

VM_NAME=minikube
DOCKER_MACHINE_CONFIG=~/.minikube/machines/${VM_NAME}/config.json

function die {
    echo "$@" >&2
    exit 1
}

# Check VBoxManage exists
VBOX_MANAGE_SEARCH=${VBOX_MSI_INSTALL_PATH+$(/usr/bin/realpath "$VBOX_MSI_INSTALL_PATH")/}VBoxManage
VBOX_MANAGE=$(which "$VBOX_MANAGE_SEARCH" 2>/dev/null) || die "File ${VBOX_MANAGE_SEARCH} not found! Put to path or set env variable VBOX_MSI_INSTALL_PATH!"

# Read local SSH port (expected by docker-machine)
[ -r "$DOCKER_MACHINE_CONFIG" ] || die "File $DOCKER_MACHINE_CONFIG not found!"
LOCAL_SSH_PORT=$(grep SSHPort "$DOCKER_MACHINE_CONFIG" | cut -c20-24)
[ -n "$LOCAL_SSH_PORT" ] || die "No SSH port in $DOCKER_MACHINE_CONFIG found!"
echo "Local SSH port: $LOCAL_SSH_PORT"

# Get IP of running VM
echo -n 'Waiting for Virtual Machine IP...'
VM_IP=
while [ -z "$VM_IP" ]; do
    VM_IP=$(MSYS_NO_PATHCONV=1 "$VBOX_MANAGE" guestproperty get "$VM_NAME" '/VirtualBox/GuestInfo/Net/1/V4/IP' | grep 'Value:' | cut -c8-)
    if test -z "$VM_IP"; then
        echo -n '.'
        sleep 5
    fi
done
echo " $VM_IP"

# Start SSH port forwarding
echo 'SSH port forwarding started'
SELF_DIR=$(dirname "$0")
/usr/bin/perl "$SELF_DIR/tcpforward.pl" -k -c "${VM_IP}:22" -l "127.0.0.1:${LOCAL_SSH_PORT}"