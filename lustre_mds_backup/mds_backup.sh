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

send_email ()
{
/usr/bin/mutt -s "mds backup error on $HOSTNAME" $EMAIL<< EOF
"$1"
EOF
}

if [[ $1 == "-c" || $1 == "--conf" ]]
then
	if [ -f $2 ]
	then
	. $2
	else
	ERROR="given configuraiton file $2 does not exist"
	fi
else
	ERROR="no configuration file given, please use -c <config file> or --config <config file"
fi


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

#name of snapshot
SNAPSHOTNAME=${SNAPSHOT_NAME:-""}

#mds directory
TARGET_MDS=${MDS_DISK:-""}

#snapshot mount directory
SNAPSHOTDISK=${LVBAK:-""}

#mount point for backup directory
BACKUPMOUNT=${SNAPSHOT_MOUNT:-""}

#path to where the backups go
BACKUPPATH=${BACKUP_PATH:-""}

echo "email $EMAIL"
echo "backup tar $BACKUPTAR"
echo "ea file name $EAFILE"
echo "target mds $TARGET_MDS"
echo "snapshot name $SNAPSHOTNAME"

#create logical volume snapshot
echo "creating lv backup"

/sbin/lvcreate --size $SNAPSIZE --snapshot --name $SNAPSHOTNAME $TARGET_MDS 

if [ "$?" -ne 0 ]
then
	ERROR_MESSAGE="error encountered while creating lv snapshot\n"
	ERROR_MESSAGE= "$ERROR_MESSAGE $?"
	send_email $ERROR_MESSAGE
	exit
fi

#sleep for 60s to allow the multi-mount protection to age out
echo "sleeping for a minute to allow multi-mount protection to expire"
sleep 60

#mount snapshot as ldisk

echo "mounting $SNAPSHOTDISK $BACKUPMOUNT"

ERROR=`/bin/mount -t ldiskfs $SNAPSHOTDISK $BACKUPMOUNT 2>&1`
if ["$?" -ne 0 ] 
then
	ERROR_MESSAGE="error encountered while mounting mds snapshot\n"
	ERROR_MESSAGE= "$ERROR_MESSAGE $ERROR"
	echo "$ERROR_MESSAGE" | /usr/bin/mutt -s "mds backup error on $HOSTNAME" $EMAIL
	exit
fi

#Start of backup

STARTTIME=$(date +%s)

echo "starting backup at $STARTTIME"

cd $BACKUPMOUNT

/usr/bin/getfattr -R -d -m '.*' -P . > $BACKUPPATH/$EAFILE
EA_INFO=`ls -lsrt $BACKUPPATH/$EA_FILE 2>&1`

echo "created ea file $BACKUPPATH/$EA_FILE"

if [ "$?" -ne -0 ]
then
	ERROR_MESSAGE="Error checking $EA_FILE: $EA_INFO"
	echo "$ERROR_MESSAGE" | /usr/bin/mutt -s "mds backup error on $HOSTNAME" $EMAIL
	exit
fi

#create sparse tar
TAR_MDS=`/bin/tar czf $BACKUPPATH/$BACKUPTAR --sparse . 2>&1`
if [ "$?" -ne 0 ]
then
	ERROR_MESSAGE="Error creating backup tar of mds: $TAR_MDS"
	echo "$ERROR_MESSAGE" | /usr/bin/mutt -s "mds backup error on $HOSTNAME" $EMAIL
	exit
fi

BACKUP_INFO=`ls -lsrt $BACKUPPATH/$BACKUPTAR 2>&1`
if [ "$?" -ne 0 ]
then
	ERROR_MESSAGE="Error checking backup tar of mds: $BACKUP_INFO"
	echo "$ERROR_MESSAGE" | /usr/bin/mutt -s "mds backup error on $HOSTNAME" $EMAIL
	exit
fi

echo "backup tar $BACKUPPATH/$BACKUPTAR created"

#get out of the backup directory 
cd /tmp


UNMOUNT_INFO=`/bin/umount $BACKUPMOUNT 2>&1`
if [ "$?" -ne 0 ]
then
	ERROR_MESSAGE="Error unmounting mds backup directory: $UNMOUNT_INFO"
	echo "$ERROR_MESSAGE" | /usr/bin/mutt -s "mds backup error on $HOSTNAME" $EMAIL
        exit
fi

echo "snapshot unmounted"

#now remove the snapshot, commented out for testing
echo "now the snapshot $SNAPSHOTDISK can be removed with lvremove"
#/sbin/lvremove $SNAPSHOTDISK

#time back ends
ENDTIME=$(date +%s)

#calculate the run time
RUNTIME=$[$ENDTIME - $STARTTIME]

/usr/bin/mutt -s "mds backup created successfuly on $HOSTNAME" $EMAIL <<EOF
backup took $RUNTIME seconds
backup ea file $BACKUPPATH/$EA_FILE:
$EA_INFO
backup mds tar file $BACKUPPATH/$BACKUPTAR:
$BACKUP_INFO
EOF

exit 0

