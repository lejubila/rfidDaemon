#!/bin/bash
#
# Driver per lettura da rfid reader collegato in emulazione di tastiera su Raspberry Pi.
# Il codice viene letto da /dev/console. Per un corretto funzionamento devono essere diasbilitati
# in /etc/inittab i runlevel relativi alle console ttyx che eseguono getty.
# E' stato testato su Raspberry Pi ver B
#
if [ -z $1 ]; then
    echo `sudo $0 run`
elif [ $1 == "run" ]; then
    read -e -s RFID < /dev/console
    echo $RFID
fi

