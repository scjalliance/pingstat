#!/bin/bash

EXECNAME=$(basename "$0")

DIR=$(dirname "$(readlink -f "$0")")
if [[ -z "${DIR}" ]]; then
	echo "Unable to determine current directory."
	exit 1
fi

PEERFILE="$DIR/peer.list"

if [ -f "$DIR/config" ]; then
	. "$DIR/config"
fi

if [[ -z "${INSTANCE}" ]]; then
	echo "INSTANCE must be provided in the environment or config file."
	exit 2
fi

if [[ -z "${STATHAT_EZKEY}" ]]; then
	echo "STATHAT_EZKEY must be provided in the environment or config file."
	exit 3
fi

PEERINSTANCE="$1"
PEERADDR="$2"

if [ -z "$PEERINSTANCE" -a -z "$PEERADDR" ]; then
	if [ ! -f "$PEERFILE" ]; then
		echo "PEERINSTANCE and PEERADDR must be provided as arguments or $PEERFILE must exist."
		exit 4
	fi

	while read PEER; do
		[ ! -z "$PEER" ] && "$DIR/$EXECNAME" $PEER &
	done < "$PEERFILE"
	exit
fi

if [ -z "$PEERINSTANCE" ]; then
	echo "PEERINSTANCE must be provided as the first argument."
	exit 5
fi

if [ -z "$PEERADDR" ]; then
	echo "PEERADDR must be provided as the second argument."
	exit 6
fi

if [[ "$PEERINSTANCE" = "${INSTANCE}-"* ]]; then
	exit 0
fi

STATNAME="netstat $INSTANCE $PEERINSTANCE"

#60 packets transmitted, 60 received, 0% packet loss, time 59093ms
#rtt min/avg/max/mdev = 20.200/32.525/55.603/6.642 ms

STAT=$(ping -c2 -i1 -W1 "$PEERADDR" | tail -n2)

SENT=$(sed -n 's/.*\([0-9][0-9]*\)\s*packets.*/\1/p' <<<"$STAT")
RCVD=$(sed -n 's/.*\([0-9][0-9]*\)\s*received.*/\1/p' <<<"$STAT")
LOSS=$(sed -n 's/.*\([0-9][0-9]*\)%\s*packet\s*loss.*/\1/p' <<<"$STAT")
RTT=$(sed -n 's/.*=\s*\([0-9\./][0-9\./]*\)\s*.*/\1/p' <<<"$STAT")
RTTMIN=$(cut -d/ -f1 <<<"$RTT")
RTTAVG=$(cut -d/ -f2 <<<"$RTT")
RTTMAX=$(cut -d/ -f3 <<<"$RTT")
RTTMDEV=$(cut -d/ -f4 <<<"$RTT")
RTTJITTER=$(bc <<<"${RTTMAX} - ${RTTMIN}")

curl -d "stat=${STATNAME} loss&ezkey=${STATHAT_EZKEY}&value=${LOSS}" -m 10 https://api.stathat.com/ez
curl -d "stat=${STATNAME} min&ezkey=${STATHAT_EZKEY}&value=${RTTMIN}" -m 10 https://api.stathat.com/ez
curl -d "stat=${STATNAME} avg&ezkey=${STATHAT_EZKEY}&value=${RTTAVG}" -m 10 https://api.stathat.com/ez
curl -d "stat=${STATNAME} max&ezkey=${STATHAT_EZKEY}&value=${RTTMAX}" -m 10 https://api.stathat.com/ez
curl -d "stat=${STATNAME} jitter&ezkey=${STATHAT_EZKEY}&value=${RTTJITTER}" -m 10 https://api.stathat.com/ez
