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

TIMESTAMP=`date +%d%^b%y`
LOGNAME=${LOG_NAME:-"ost_build"}-$TIMESTAMP".log"

#sourcing config file
[ -f ost.conf ] && . ost.conf

#variable list

#index, sould be one higher then index of last installed ost
INDEX=$OST_INDEX

#sets hex index for use in ldev.conf, then pads it with a zero if it is a single digit
HEXINDEX=`echo "obase=16; $INDEX" | bc`
if (( ${#HEXINDEX} == 1 )); then
        HEXINDEX="0"$HEXINDEX
fi

#pool name, based on index
ZPOOLNAME="lustre-ost$INDEX/ost$INDEX"

#list of disk aliases from /etc/zfs/vdev_id.conf
#VDEVS="disk2 disk3 disk4 disk5 disk6 disk7 disk8 disk9 disk10 disk11 disk12 disk13 disk14 disk15 disk16 disk17 disk18 disk19 disk20 disk21 disk22 disk23 disk24 disk25 disk26 disk27 disk28 disk29 disk30 disk31"
#test of easier way...
VDEVS=$VDEV_LIST

#File system name, static
FSNAME=${FILESYSTEM_NAME:-"lustre2"}

#head mds head nodes
MGSNODE=$MGS_NODE
FAILNODE=$FAILOVER_NODE
#MGSNODE="172.17.4.125@o2ib"
#FAILNODE="172.17.4.126@o2ib"

#raid level
RAIDLVL=${RAID_LEVEL:-"raidz2"}

#node name
NODENAME=`uname -n`

#create the entries in /etc/ldev.conf
cat > /tmp/new.ldev.conf <<EOF
# example /etc/ldev.conf
#
#local  foreign/-  label       [md|zfs:]device-path   [journal-path]/- [raidtab]
#
# entries for $NODENAME
$NODENAME - $FSNAME-OST00$HEXINDEX zfs:$ZPOOLNAME
EOF

#build the file system
mkfs.lustre --fsname=$FSNAME --ost --backfstype=zfs --index=$INDEX --mgsnode=$MGSNODE --failnode=$FAILNODE $ZPOOLNAME $RAIDLVL $VDEVS


