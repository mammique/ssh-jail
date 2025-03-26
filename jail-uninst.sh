#!/usr/bin/env bash

CONFIG_FILE="/etc/ssh/jail.conf"
CONFIG_FILE_SSH='/etc/ssh/sshd_config.d/jail.conf'
KEYS_PATH='/etc/ssh/jail_keys/'
source "$CONFIG_FILE"

echo
echo "This will not remove Jail SSH accounts and environments, just the SSHd installation."
echo

read -p "Uninstall Jail SSH? [y/N] " confirm
[[ $confirm != [yY] ]] && exit 0

echo "Removing configuration files…"
rm $CONFIG_FILE
rm $CONFIG_FILE_SSH
delgroup $JAIL_GROUP
echo "Restart SSH server…"
systemctl restart ssh

echo
echo "Done."
echo
