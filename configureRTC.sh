#!/bin/bash
# 
#
###############################################################################
# $Copyright:
# Copyright (C) PECIH Electronics and Software Systems LLP 2015
# All rights reserved
# $
# 	Script Name: configureRTC.sh
# 	Purpose: Configure RTC as hardware clock on Raspberry Pi Rev 1.0 and Rev 2.0
# 	Author: Omar Ibrahim Hussain M
# 	www.photoelectricchefs.org
#
# 	Parameters:
#	Date to be set for RTC must be given as parameters
#	$1 - DATE: dd format
#	$2 - MONTH: mm format
#	$3 - YEAR: yyyy format
#	$4 - HOUR: HH format
#	$5 - MINUTE: MM format
#	$6 - SECONDS: SS format
# 	Time zone is assumed as Asia/Calcutta
###############################################################################

NOW=`date +%Y-%m-%d-%H:%M:%S`
LOGFILE=/root/configureRTC_$NOW.log

DATE=$1
MONTH=$2
YEAR=$3
HOUR=$4
MINUTE=$5
SECOND=$6


logmsg()
{
	echo "`date \"+%y/%m/%d %H:%M:%S\"` : $1" | tee -a $LOGFILE
}

usage()
{
echo "
Usage:
configureRTC.sh <dd> <mm> <yyyy> <HH> <MM> <SS>
dd   : DATE
mm   : MONTH
yyyy : YEAR
HH   : HOUR
MM   : MINUTES
SS   : SECONDS

Note: To be executed as root user.
"
}

if [ $USER != "root" ]
then
	echo "ERROR!!! This script has to be executed as root!"
	exit 1
fi

if [ $# -ne 6 ]
then
	echo "
ERROR!!! Incorrect number of parameters!"
	usage
	exit 1
fi



# check if user is root, else exit

# I2C setup/usr/sbin/i2cdetect

/bin/mkdir ~/i2c
if [ ! -f i2c-tools-3.1.1.tar.bz2 ]
then
	logmsg "ERROR! Could not locate i2c-tools-3.1.1.tar.bz2!"
	exit 1 
fi

logmsg "Extracting i2c tools..."
tar -xf i2c-tools-3.1.1.tar.bz2 -C ~/i2c
cd ~/i2c/i2c-tools-3.1.1/
/usr/bin/make
make install

/usr/bin/which i2cdetect
if [ $? -ne 0 ]
then
	logmsg "ERROR: i2c tools installation failed!"\
	exit 1
fi

grep "i2c-dev" /etc/modules
if [ $? -ne 0 ]
then
	logmsg "Adding i2c kernel module i2c-dev for auto-load on reboot..."
	echo "i2c-dev" >> /etc/modules
	if [ $? -ne 0 ]
	then
		logmsg "ERROR!!! Could not modify /etc/modules"
		exit 1
	fi
fi

grep "i2c-bcm2708" /etc/modules
if [ $? -ne 0 ]
then
	logmsg "Adding i2c kernel module i2c-bcm2708 for auto-load on reboot..."
	echo "i2c-bcm2708" >> /etc/modules
	if [ $? -ne 0 ]
	then
		logmsg "ERROR!!! Could not modify /etc/modules"
		exit 1
	fi
else
	logmsg "Already present: i2c kernel module i2c-bcm2708 for auto-load"
fi
	
if [ -f "/etc/modprobe.d/raspi-blacklist.conf" ]
then
	grep "i2c-bcm2708" /etc/modprobe.d/raspi-blacklist.conf
	if [ $? -eq 0 ]
	then
		logmsg "Removing i2c from kernel modules blacklist, so that they are considered by kernel..."
		/bin/sed -i '/blacklist i2c-bcm2708/c\\#blacklist i2c-bcm2708' /etc/modprobe.d/raspi-blacklist.conf
		if [ $? -ne 0 ]
		then
			logmsg "ERROR!!! Failed to remove bcm from blacklist!"
			exit 1
		fi
	fi
	
		
fi

grep "dtparam=i2c1=on" /boot/config.txt
if [ $?	-ne 0 ]
then
	logmsg "Updating boot configuration..."
	
	echo "
dtparam=i2c1=on
dtparam=i2c_arm=on" >> /boot/config.txt

	if [ $? -ne 0 ]
	then
		logmsg "ERROR!!! Could not modify /etc/modules"
		exit 1
	fi
fi



#Checking the i2c bus address
modprobe i2c-dev
modprobe i2c-bcm2708

logmsg "Checking the i2c bus address for RTC..."

BUS_FOUND=0
BUS_ADDRESS=2
i2cdetect -y 0 | grep 68
if [ $? -eq 0 ]
then
	logmsg "I2C bus address detected: 0."
	BUS_ADDRESS=0
	BUS_FOUND=1
fi

i2cdetect -y 1 | grep 68
if [ $? -eq 0 ]
then
	logmsg "I2C bus address detected: 1."
	BUS_ADDRESS=1
	BUS_FOUND=1
fi

RTC_ADDED=0
if [ $BUS_FOUND -eq 0 ]
then
	ls -l /dev/rtc*
	if [ $? -eq 0 ]
	then
		RTC_ADDED=1
		logmsg "RTC device already detected. Skipping detection"
	else
		logmsg "ERROR!!!I2C bus address for RTC not detected!! Please check RTC connections."
		exit 1
	fi
fi

modprobe rtc-ds1307
lsmod | grep rtc_ds1307
if [ $? -ne 0 ]
then
	logmsg "ERROR!!! Failed loading kernel module for DS1307 RTC"
	exit 1
fi

if [ $RTC_ADDED -ne 1 ]
then
	if [ $BUS_ADDRESS -eq 0 ]
	then
		echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-0/new_device
		if [ $? -ne 0 ]
		then
			logmsg "ERROR!!! Failed to set set new sys device!"
			exit 1
		fi
			
	else
		echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-1/new_device
		if [ $? -ne 0 ]
		then
			logmsg "ERROR!!! Failed to set set new sys device!"
			exit 1
		fi
	fi
else
	logmsg "RTC device already added!. Skipping new device add"
fi
#take inputs from user for system time


#set system time
logmsg "Setting System Date and time..."
date $MONTH$DATE$HOUR$MINUTE$YEAR.$SECOND
if [ $? -ne 0 ]
then	
	logmsg "ERROR!!! Could not set system date!"
	exit 1
fi

# Read hardware clock
#hwclock -r

logmsg "Setting RTC date/time..."
#Set hwclock to system time
hwclock --systohc -D --noadjfile --utc 

#Add to auto-load list
logmsg "Adding HW clock sync to startup for auto sync up on boot."

grep 'rtc-ds1307' /etc/modules
if [ $? -ne 0 ]
then
	echo "rtc-ds1307" >> /etc/modules
fi

if [ $BUS_ADDRESS -eq 0 ]
then
	grep 'ds1307 0x68' /etc/rc.local
	if [ $? -ne 0 ]
	then
		echo 'echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-0/new_device' >> /etc/rc.local	
	fi
	grep 'hwclock -s' /etc/rc.local
	if [ $? -ne 0 ]
	then
		echo 'hwclock -s' >> /etc/rc.local
	fi
else
	grep 'ds1307 0x68' /etc/rc.local
	if [ $? -ne 0 ]
	then
		echo 'echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-1/new_device' >> /etc/rc.local	
	fi
	grep 'hwclock -s' /etc/rc.local
	if [ $? -ne 0 ]
	then
		echo 'hwclock -s' >> /etc/rc.local
	fi
fi

grep 'exit' /etc/rc.local
if [ $? -eq 0 ]
then
	/bin/sed -i '/exit 0/c\\#exit 0' /etc/rc.local
	echo 'exit 0' >> /etc/rc.local
fi

logmsg "Checking time on RTC..."
hwclock -r
if [ $? -ne 0 ]
then
	logmsg "ERROR!!! Could not read time from RTC!"
	exit 1
fi

logmsg "Syncing RTC and system time..."
hwclock -s
if [ $? -ne 0 ]
then
	logmsg "ERROR!!! Failed to sync RTC time and system time"
	exit 1
fi

logmsg "Setting timezone as IST"
ln -sf /usr/share/zoneinfo/Asia/Calcutta /etc/localtime


logmsg "##############################"
logmsg "#  CONFIGURATION SUCCESSFUL  #"
logmsg "##############################"

logmsg "Please reboot the system using 'reboot -f' command."
