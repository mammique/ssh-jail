#!/usr/bin/env bash
#
# GPL-3 https://github.com/mammique/ssh-jail
#
# Script for deploying minimal SSH jail system on Debian-like distributions,
# upon normal SSH installation without altering it.
#
# Then easily add/remove SSH jail accounts, allowing users to Rsync/sFTP
# in their `$JAIL/home/dir` and execute minimal commands (GNU-like commands via Toybox).
#
# Commands:
#
# - jail-add.sh (first deployment and add account)
# - jail-del.sh (delete account)
# - jail-uninst.sh

CONFIG_FILE="/etc/ssh/jail.conf"
CONFIG_FILE_SSH='/etc/ssh/sshd_config.d/jail.conf'
KEYS_PATH='/etc/ssh/jail_keys/'

echo

# Select ToyBox or BusyBox.
apt-cache show toybox >/dev/null 2>&1 && CMDBIN="toybox" || CMDBIN="busybox"

install_jail() {

	echo "Jail SSH not installed…"
	echo
	CMDBIN_PKG=$CMDBIN
	[ "$CMDBIN" = 'busybox' ] && dpkg -l busybox-static &>/dev/null && CMDBIN_PKG="busybox-static"
	apt install --no-upgrade openssh-server openssh-sftp-server rsync $CMDBIN_PKG
	echo
	echo "Creating configuration file…"
	echo
	read -p "Enter absolute root path for the jail environments (e.g. '/mnt/ssh_jails/'): " JAILS_PATH
	read -p "Name of the POSIX user group for jail members (e.g. 'jail'): " JAIL_GROUP
	echo
	echo "Writing configuration filen…"
	cat > "$CONFIG_FILE" <<EOF
JAILS_PATH='$JAILS_PATH'
JAIL_GROUP='$JAIL_GROUP'
EOF
	echo "Writing separate SSH configuration for the jail system in $CONFIG_FILE_SSH…"
	cat > "$CONFIG_FILE_SSH" <<EOF
Match Group $JAIL_GROUP
     AuthorizedKeysFile $KEYS_PATH%u.pub
     ChrootDirectory %h
     X11Forwarding no
     AllowTcpForwarding no
     PermitTunnel no
EOF
	echo "Restart SSH server…"
	systemctl restart ssh
	echo "Creatin directories $JAILS_PATH and $KEYS_PATH…"
	mkdir -p $JAILS_PATH
	mkdir -p $KEYS_PATH 
	addgroup $JAIL_GROUP
}

if [ ! -f "$CONFIG_FILE" ]; then
	install_jail
else
	source "$CONFIG_FILE"
fi

read -p "Name of the new user: " USER
read -p "Paste user's SSH public key: " KEY_PUB

echo "Creating jail environment for $USER…"
CHROOT_PATH=$JAILS_PATH/$USER
mkdir -p $CHROOT_PATH
cd $CHROOT_PATH
useradd --no-create-home -d "$CHROOT_PATH" -s /bin/bash $USER
usermod -aG $JAIL_GROUP $USER
echo $KEY_PUB >> "$KEYS_PATH/$USER.pub"

# Importing minimal binaries and libraries.
# https://tools.deltazero.cz/server/setup.chroot.for.rsync.sh
copies=$((ldd `which sh`; ldd `which bash`; ldd `which rsync` ; ldd "`which $CMDBIN`" 2>/dev/null;) | awk '/\// { print ($3 ? $3 : $1) }' | sort | uniq)
copies+=" $(which sh) $(which bash) $(which rsync) $(which $CMDBIN) /usr/lib/openssh/sftp-server"
for f in $copies; do
  d=$(dirname ${f})
  [[ ! -d ".$d" ]] && mkdir -p ".$d"
  [[ ! -f ".$f" ]] && cp "$f" ".$f"
done
mkdir -p $CHROOT_PATH/bin
ln -s /usr/bin/bash $CHROOT_PATH/bin/
if [ $CMDBIN == 'toybox' ]; then
	for cmd in $(toybox); do ln -s /usr/bin/toybox usr/bin/$cmd; done
else
	for cmd in $(busybox --list); do
		if [ ! -f "usr/bin/$cmd" ]; then
			ln -s /usr/bin/busybox usr/bin/$cmd;
		fi
	done
fi

# Creating devices.
mkdir -p $CHROOT_PATH/dev
(
    cd $CHROOT_PATH/dev || exit 1
        mknod -m 666 null c 1 3
        mknod -m 666 zero c 1 5
        mknod -m 666 random c 1 8
        mknod -m 666 urandom c 1 9
        mknod -m 666 tty c 5 0
)
# echo "Devices created in ${CHROOT_PATH}/dev :"
# ls -l "${CHROOT_PATH}/dev" | grep -E 'null|zero|random|urandom|tty'

# Create non-root user's read-write home.
mkdir -p $CHROOT_PATH/home/$USER
chown $USER:$USER $CHROOT_PATH/home/$USER

# Import minimal account information.
mkdir etc
cp /etc/passwd etc/

echo "Done."
echo
