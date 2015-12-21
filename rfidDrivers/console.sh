#!/bin/bash
#
# Driver per lettura da rfid reader in emulazione di tastiera.
# Il codice viene letto da /dev/console. Per un corretto funzionamento devono essere diasbilitati
# in /etc/inittab i runlevel relativi alle console ttyx che eseguono getty
#
if [ -z $1 ]; then
    echo `sudo $0 run`
elif [ $1 == "run" ]; then
    read -e -s RFID < /dev/console
    echo $RFID
fi

