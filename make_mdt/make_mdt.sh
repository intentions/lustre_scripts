#!/bin/bash
#
#script to build the mgs / mdt server
#written by: Kurt J. Strosahl (strosahl@jlab.org)
#written: 06APR15
#

HELP=""

#user check

#user check
if [[ `whoami` -ne "root" ]]
then
        echo "this must be run as root"
        exit
fi

if [[ $1 == "-h" || $1 == "--help" || ! $1 ]]; then
        printf '%s\n' "$HELP"
        exit
fi

if [[ $1 == "-c" || $1 = "--conf" ]]; then
        CONFIGFILE=$2
else
        echo "no config file passed, please pass a config file"
        exit
fi

#sourcing config file
[ -f $CONFIGFILE ] && . $CONFIGFILE

#variable list

#Filesystem name
FSNAME=${:-""}

#IPs for the head nodes
MGSNODE1=${:-""}
MGSNODE2=${:-""}

SET_MGS=${:-""}
SET_MDT=${:-""}

LVDISK=${:-""}

mkfs.lustre $REFORMAT --fsname=$FSNAME --mgsnode=$MGSNODES --servicenode=$MGSNODE1 --servicenode=$MGSNODE2 $SET_MGS $SET_MDT $LVDISK
