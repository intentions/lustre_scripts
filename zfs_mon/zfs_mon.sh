#!/bin/bash
#
# zfs monitoring script for lustre with zfs backend
# uses /etc/ldev.conf to locate zpools, then zpool status to find degraded pools.

HELP="
 This script uses /etc/ldev.conf and zpool status to identify mounted pools, then sends an email if 
 a pool returns a status other then ONLINE
"

LDEV_FILE="/etc/ldev.conf" 
EMAIL="strosahl@jlab.org"
EMAIL_CMD="/usr/bin/mutt"

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

		#check for errors running zpool
		if [ ! $? ]
		then
			send_email "$POOL_STATUS"	
		fi

		#get pool state		
		POOL_STATE=`echo "$POOL_STATUS" | grep state`
		if [[ $POOL_STATE != *ONLINE* ]]
		then
			send_email "$POOL_STATUS"
		fi
	fi

done
