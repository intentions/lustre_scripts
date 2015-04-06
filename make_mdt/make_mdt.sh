#!/bin/bash

#script to build the mgs / mdt server




mkfs.lustre $REFORMAT --fsname=$FSNAME --mgsnode=$MGSNODES --servicenode=$MGSNODE1 --servicenode=$MGSNODE2 $SET_MGS $SET_MDT $LVDISK
