#!/bin/bash
#
# zfs monitoring script for lustre with zfs backend
# uses /etc/ldev.conf to locate zpools, then zpool status to find degraded pools.

HELP="
 This script uses zpool list and zpool status to identify mounted pools, then report on their status
"

LDEV_FILE=${LDEV_CONF:-"/etc/ldev.conf"}
EMAIL=${EMAIL_ADDRESS:-"strosahl@jlab.org"}
SUBJECT=${NOTIFY_SUBJECT:-"WARNING: degraded zpool on $HOSTNAME"}
EMAIL_CMD=${EMAIL_CLIENT:-"/usr/bin/mutt"}

send_email ()
{
/usr/bin/mutt -s "zpool status warning on $HOSTNAME" $EMAIL<< EOF
"$1"
EOF
}

if [ ! -f $LDEV_FILE ]
then
	$EMAIL_CMD -s "WARNING, no ldev file found on $HOSTNAME" $EMAIL
	exit
fi

for POOL in `cat $LDEV_FILE`
do
	if [[ `echo $POOL | grep ost` ]]
	then
		POOL_NAME=`echo $POOL | cut -f2 -d":" | cut -f1 -d"/"`
		POOL_STATUS=`/sbin/zpool status $POOL_NAME`
		if [ $? ]
		then
			send_email "$POOL_STATUS"	
		fi
		
		POOL_STATE=`echo "$POOL_STATUS" | grep state`
		if [[ $POOL_STATE != *ONLINE* ]]
		then
		send_email "$POOL_STATUS"
		fi
	fi

done
