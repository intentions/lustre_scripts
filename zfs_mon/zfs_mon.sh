#!/bin/bash
#
# zfs monitoring script for lustre with zfs backend
# uses /etc/ldev.conf to locate zpools, then zpool status to find degraded pools.


LDEV_FILE=${LDEV_CONF:-"/etc/ldev.conf"}
EMAIL=${EMAIL_ADDRESS:-"strosahl@jlab.org"}
SUBJECT=${NOTIFY_SUBJECT:-"WARNING: degraded zpool on $HOSTNAME"}
EMAIL_CMD=${EMAIL_CLIENT:-"/usr/bin/mutt"}

while read -r entry
do
	if [[ `echo $entry | grep OST` ]]
	then
		INFO=`echo $entry | cut -b33-43`
		APOOL=`sudo /sbin/zpool status $INFO`
		if [[ `echo "$APOOL" | grep DEGRADED` ]]
		then
			echo "$APOOL" | $EMAIL_CMD -s "WARNING: degraded zpool on $HOSTNAME" $EMAIL
		fi
	fi
done < "$LDEV_FILE"
