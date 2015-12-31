#!/bin/bash
#
# Simple daemon for RFID reader. Running a custom script based on the RFID code that is read.
# Author: david.bigagli@gmail.com
# Url: https://github.com/lejubila/rfidDaemon
#

DIR_SCRIPT=`dirname $0`
NAME_SCRIPT=${0##*/}
CONFIG_ETC="/etc/rfidDaemon.conf"
PID_FILE="/tmp/rfidDaemon.pid"
PID_SCRIPT=$$

#
# Scrive un messaggio nel file di log
# $1 log da scrivere
#
function log_write {
	if [ -e "$LOG_FILE" ]; then
		local actualsize=$($WC -c <"$LOG_FILE")
		if [ $actualsize -ge $LOG_FILE_MAX_SIZE ]; then
			$GZIP $LOG_FILE
			$MV $LOG_FILE.gz $LOG_FILE.`date +%Y%m%d%H%M`.gz	
		fi
	fi

	echo -e "`date`\t\t$1" >> $LOG_FILE
}


function show_usage {
	echo -e "Usage:"
	echo -e "\t$NAME_SCRIPT start [log file name]\tStart reader rfid daemon"
	echo -e "\t$NAME_SCRIPT stop\t\t\tStop reader rfid daemon"
	echo -e "\t$NAME_SCRIPT simulate {rfidCode}\tSimulate to read any rfid code"
}

#
# Start daemon
# $1 name of file log
#
function startDaemon {

	if [ -n "$1" ]; then
		LOG_FILE="$1"
	fi

	echo $PID_SCRIPT > "$PID_FILE"

	while true; do

		local rfid_code=""
		
		# read rfid code
		RFID_DRIVER="$DIR_SCRIPT/rfidDrivers/$RFID_TYPE.sh"
		if [ -f "$RFID_DRIVER" ]; then
			local RFID_CODE=`exec "$RFID_DRIVER"`
			rfid_launch "$RFID_CODE"
		else
			echo "Driver rfid reader not found ($RFID_DRIVER)" > /tmp/rfidDaemon.err
			sleep 5;
		fi
	done

}

#
# Stop the daemon
#
function stopDaemon {

	if [ ! -f "$PID_FILE" ]; then
		echo "Daemon is not running"
		exit 1
	fi

	kill -9 $(list_descendants `cat "$PID_FILE"`)
	kill -9 `cat "$PID_FILE"`
	rm -f "$PID_FILE"

}

#
# Simulate to read a rfid code
# $1 rfid code
#
function simulate {

	if [ -z $1 ]; then
		echo "No code RFID as an argument"
		exit 1
	fi

	rfid_launch "$1"

}

#
# Launch script for an rfid code
# $1 rfid code
#
function rfid_launch {

	if [ -z $1 ]; then
		log_write "rfid code is empty"
	else
		local name_rfid_all_script="$DIR_SCRIPT/rfidScripts/rfid-all.sh"
		local name_rfid_script="$DIR_SCRIPT/rfidScripts/rfid-$1.sh"

		if [ -f "$name_rfid_all_script" ]; then
			log_write "rfid code: $1 - launched $name_rfid_all_script"
			sh "$name_rfid_all_script" "$1"
		fi

		if [ -f "$name_rfid_script" ]; then
			log_write "rfid code: $1 - launched $name_rfid_script"
			sh "$name_rfid_script"
		fi
	fi

}

list_descendants ()
{
  local children=$(ps -o pid= --ppid "$1")

  for pid in $children
  do
    list_descendants "$pid"
  done

  echo "$children"
}

if [ -f $CONFIG_ETC ]; then
	. $CONFIG_ETC
else
	echo -e "Config file not found in $CONFIG_ETC"
	exit 1
fi

case "$1" in
	start) 
		if [ -f "$PID_FILE" ]; then
			echo "Daemon is already running, use \"rfidDaemin.sh stop\" to stop the service"
			exit 1
		fi

		nohup $0 startDaemon $2 > /dev/null 2>&1 &
		echo "Daemon is started widh pid $!"

		;;

	startDaemon)
		startDaemon $2
		;;		

	stop)
		stopDaemon
		;;

	simulate)
		simulate $2
		;;

	*) 
		show_usage
		exit 1
		;;
esac




