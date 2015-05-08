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
else
	ERROR="no configuration file given, please use -c <config file> or --config <config file"
fi

#sets debug mode
[ -n ${DEBUG_MODE:-""} ] && set -x


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
/sbin/lvcreate --size $SNAPSIZE --shapshot $SNAPSHOTNAME $TARGET 

if [ "$?" -ne 0 ]
then
	ERROR_MESSAGE="error encountered while creating lv snapshot\n"
	ERROR_MESSAGE= "$ERROR_MESSAGE $?"
	send_email $ERROR_MESSAGE
	exit
fi

#sleep for 60s to allow the multi-mount protection to age out
sleep 60

#mount snapshot as ldisk

/bin/mount -t ldiskfs $SNAPSHOTDISK $BACKUPMOUNT 2> ERROR
if ["$?" -ne 0 ] 
then
	ERROR_MESSAGE="error encountered while mounting mds snapshot\n"
	ERROR_MESSAGE= "$ERROR_MESSAGE $ERROR"
	echo "$ERROR_MESSAGE" | /usr/bin/mutt -s "mds bnackup error on $HOSTNAME" $EMAIL
	exit
fi

#Start of backup
STARTTIME=$(date +%s)

cd $BACKUPMOUNT

OUTPUT_CATCH=`/usr/bin/getfattr -R -d -m '.*' -P . > $BACKUPPATH/$EA_FILE`
EA_INFO = `ls -lsrt $BACKUPPATH/$EA_FILE`

#create sparse tar
/bin/tar czf $BACKUPPATH/$BACKUPTAR --sparse .
BACKUP_INFO=`ls -lsrt $BACKUPPATH/$BACKUPTAR`



#get out of the backup directory 
cd /tmp

/bin/umount $BACKUPMOUNT

#now remove the snapshot, commented out for testing
#/sbin/lvremove $SNAPSHOTDISK

#time back ends
ENDTIME=$(date +%s)

#calculate the run time
RUNTIME=$[$ENDTIME - $STARTTIME]

/usr/bin/mutt -s "mds backup created successfuly on $HOSTNAME" $EMAIL <<EOF
backup took $RUNTIME


