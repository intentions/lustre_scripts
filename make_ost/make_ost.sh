#!/bin/bash
#
#ost creation file for lustre 2.5 systems ost systems with zfs
#written by: Kurt J. Strosahl (strosahl@jlab.org)
#Written: 18MAR15
#

HELP="
 To create a new ost increment the index, update the zpool name, and ensure that the VDEVS list points to the data disks on the system
 the vdev aliases are found in /dev/disk/by-vdev, and it is built by the following
 create /etc/zfs/vdev_id.conf and populate it by looking at the /dev/disk/by-path/ directory.
 Create an alias for all disks, then comment out aliases that point to non-data disks
 after the alias file is fully populated use the command udevadmn trigger to populate the /dev/disk/by-vdev directory
 then verify that only data disks are listed by using fdisk -l /dev/disk/by-vdev/* (this assumes that the data disks are all the same size,
 and that that size differs from other disks on the sytem).
 
 After that is done then this script can be run, generating the ldev.conf file used by luster as /tmp/new.ldev.conf
 assuming no errors are encountered then /tmp/new.ldev.conf can be moved to /etc/ldev.conf
 then lustre can be started using /etc/init.d/lustre start

 note that due to pathing issues the service command cannot be used to start lustre.

 use syntax:
"

if [[ $1 == "-h" || $1 =="--help" ]]; then
	echo $HELP
fi

#sourcing config file
[ -f ost.conf ] && . ost.conf

#setting up log file
TIMESTAMP=`date +%d%^b%y`
LOGNAME=${LOG_NAME:-"/tmp/ost_build"}-$TIMESTAMP".log"

#variable list

#File system name, static
FSNAME=${FILESYSTEM_NAME:-""}

#index, sould be one higher then index of last installed ost
INDEX=${OST_INDEX:-""}

#setting reformat flag, used only to redo the process
REFORMAT=${SET_REFORMAT:-""}

#sets hex index for use in ldev.conf, then pads it with a zero if it is a single digit
HEXINDEX=`echo "obase=16; $INDEX" | bc`
if (( ${#HEXINDEX} == 1 )); then
        HEXINDEX="0"$HEXINDEX
fi

#pool name, based on index
ZPOOLNAME="lustre-ost$INDEX/ost$INDEX"
MOUNTDIR=${MOUNT_DIRECTORY:-"/ost$INDEX"}

#list of disk aliases from /etc/zfs/vdev_id.conf
#VDEVS="disk2 disk3 disk4 disk5 disk6 disk7 disk8 disk9 disk10 disk11 disk12 disk13 disk14 disk15 disk16 disk17 disk18 disk19 disk20 disk21 disk22 disk23 disk24 disk25 disk26 disk27 disk28 disk29 disk30 disk31"
#test of easier way...
VDEVS=${VDEV_LIST:-""}

#head mds head nodes
MGSNODE=${MGS_NODE:-""}
FAILNODE=${FAILOVER_NODE:-""}

#backend file system
BACKENDFS=${BACKEND_FILESYSTEM:-"zfs"}

#raid level
RAIDLVL=${RAID_LEVEL:-""}

#node name
NODENAME=`uname -n`

#new ldev.conf file
LDEVCONF=${LDEV_CONF:-"/tmp/new.ldev.conf"}

#lustre configuration file
LUSTRECONF=${LUSTRE_CONFIG:-"/etc/sysconfig/lustre"}

#logfile initialization
cat > LOGNAME <<EOF
ost creation log
DATE: $TIMESTAMP
Filesystem name used: $FSNAME
Reformat flag: $REFORMAT
Backend file system: $BACKENDFS
Index provided: $INDEX
MGS node: $MGSNODE
Failover node: $FAILNODE
ZPool name: $ZPOOL
Raid level: $RAIDLVL
list of disk for the zpool: $VDEVS
ost mount directory: $MOUNTDIR
new ldev file: $LDEVCONF
EOF

#create local directory structure
if [ ! -d "$MOUNTDIR" ]
then
	mkdir $MOUNTDIR
	echo "appending mount directory $MOUNTDIR to $LUSTRECONF"
	echo "LOCAL_MOUNT_DIR=$MOUNTDIR" >> $LUSTRECONF
else
	echo "$MOUTDIR already exists, skipping directory creation and appending to $LUSTRECONF"
fi

#create the entries in /etc/ldev.conf
cat > $LDEVCONF <<EOF
# example /etc/ldev.conf
#
#local  foreign/-  label       [md|zfs:]device-path   [journal-path]/- [raidtab]
#
# entries for $NODENAME
$NODENAME - $FSNAME-OST00$HEXINDEX zfs:$ZPOOLNAME
EOF

#build the file system
mkfs.lustre --fsname=$FSNAME $REFORMAT --ost --backfstype=$BACKENDFS --index=$INDEX --mgsnode=$MGSNODE --failnode=$FAILNODE $ZPOOLNAME $RAIDLVL $VDEVS 1>> $LOGNAME 2>&1


