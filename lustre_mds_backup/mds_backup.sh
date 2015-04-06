#!/bin/bash
#
# mds backup script
# written by: Kurt J. Strosahl (strosahl@jlab.org)
# 
# The purpose of this script is to automatically generate a backup of a lustre metadata system
# using logical volunes and the tar method (it may be revised to use block backups if that can
# be shown to be faster.
#
# requires a .conf file to be provided, the configuration file provides system specific details
# on how and where the backup is to be rubn, as well as where to place the backup after it is 
# completed.
# logging should also be used to keep track of backups

if [[ $1 == "-c" || $1 == "--conf" ]]
then
	if [ -f $2 ]
	then
	. $2
	else
	ERROR="given configuraiton file $2 does not exist"
else
	ERROR="no configuration file given, please use -c <config file> or --config <config file"
fi

#START TIME

#timestamp for backups
TIMESTAMP=`date +%d%^b%y`

EMAIL=${NOTIFY_EMAIL:-""}

ERR_CATCH=""

#file name for the tar
BACKUPTAR=${BACKUP_NAME:-""}-$TIMESTAMP.tgz

#file name for the ea file
EAFILE=${EA_FILE:-""}-$TIMESTAMP.bak

#Size of the snapshot
SNAPSIZE=${SNAPSHOT_SIZE:-""}

#create logical volume snapshot
/sbin/lvcreate --size $SNAPSIZE --shapshot $SNAPSHOTNAME $TARGET 2> $ERR_CATCH

if [ $ERR_CATCH ]


#sleep for 60s to allow the multi-mount protection to age out
sleep 60

#mount snapshot as ldisk

/bin/mount -t ldiskfs $SNAPSHOTDISK $BACKUPMOUNT

cd $BACKUPMOUNT

/usr/bin/getfattr -R -d -m '.*' -P . > $BACKUPPATH/$EA_FILE

#create sparse tar
/bin/tar czf $BACKUPPATH/$BACKUPTAR --sparse . 2>

#now remove the snapshot, commented out for testing
#/sbin/lvremove $SNAPSHOTDISK


