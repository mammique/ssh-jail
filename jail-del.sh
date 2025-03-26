#!/usr/bin/env bash

CONFIG_FILE="/etc/ssh/jail.conf"
source "$CONFIG_FILE"
KEYS_PATH='/etc/ssh/jail_keys/'

[ -z "$1" ] && { echo "Argument missing. Please enter the username of the Jail SSH accout to delete."; exit 1; }

USER=$1

echo

read -p "Delete Jail SSH account '$USER'? [y/N] " confirm
[[ $confirm == [yY] ]] && {
	rm "$KEYS_PATH/$USER.pub"
	deluser $USER
}

read -p "Delete directory '$JAILS_PATH/$USER'? [y/N] " confirm
[[ $confirm == [yY] ]] && rm -rf "$JAILS_PATH/$USER"
