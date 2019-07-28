#!/bin/bash

if [ -z "${SUDO_USER}" -o "${USER}" != "root" ]; then
	echo "Please run this via sudo to become root."
	exit
fi

DIR=$(dirname $(readlink -e "$0"))
if [[ -z "${DIR}" ]]; then
	echo "Unable to determine current directory."
	exit 1
fi

HOSTNAME=$(hostname -s)
if [[ -z "${HOSTNAME}" ]]; then
	echo "Unable to determine hostname."
	exit 2
fi

if [ ! -f "$DIR/config" ]; then
	INSTANCE="$1"
	if [[ -z "${INSTANCE}" ]]; then
		echo "The instance should be provided as the first argument."
		exit 3
	fi

	STATHAT_EZKEY="$2"
	if [[ -z "${STATHAT_EZKEY}" ]]; then
		echo "The stathat ezkey should be provided as the second argument."
		exit 4
	fi

	echo "INSTANCE=$INSTANCE" > "$DIR/config" && \
	echo "STATHAT_EZKEY=$STATHAT_EZKEY" >> "$DIR/config"
fi

if [ ! -f "$DIR/peer.list" ]; then
	cat >"$DIR/peer.list" <<EOL
lcy-pub    olympia.scjalliance.com
lcy-gw  gw.olympia.scjalliance.com
cen-pub    centralia.scjalliance.com
cen-gw  gw.centralia.scjalliance.com
gig-pub    gigharbor.scjalliance.com
gig-gw  gw.gigharbor.scjalliance.com
bal-pub    ballard.scjalliance.com
bal-gw  gw.ballard.scjalliance.com
sea-gw  gw.seattle.scjalliance.com
wen-pub    wenatchee.scjalliance.com
wen-gw  gw.wenatchee.scjalliance.com
van-pub    vancouver.scjalliance.com
van-gw  gw.vancouver.scjalliance.com
spo-pub    spokane.scjalliance.com
spo-gw  gw.spokane.scjalliance.com
EOL
fi

chmod 0755 "$DIR/install.sh" "$DIR/pingstat.sh" && \
chmod 0640 "$DIR/config" && \
chmod 0644 "$DIR/peer.list" && \
chown root: -R "$DIR"

if [ ! -f /etc/cron.d/pingstat ]; then
	echo "MAILTO=$HOSTNAME+cron@it.scj.io" > /etc/cron.d/pingstat
	echo "* * * * *	root	test -x $DIR/pingstat.sh && $DIR/pingstat.sh" >> /etc/cron.d/pingstat
fi
