#!/bin/bash
#Transmission - Seed for 3 weeks, then stop torrent.
#Log progress in the meantime each night.

date >> torrentlog.log

TORRENTLIST=`transmission-remote -n $TR_ADMIN:"$TR_PASSWORD" -l | sed -e '1d;$d;s/^ *//' | cut -s -d " " -f1`
for TORRENTID in $TORRENTLIST
do
        TIME=`transmission-remote localhost:9091 --torrent $TORRENTID --info | grep "Seeding Time" | awk -F '[()]' '{print $2}' | sed 's/ seconds//g'`
        NAME=`transmission-remote localhost:9091 --torrent $TORRENTID --info | grep "Name"`

        if [ "$TIME" -gt "1814400" ]
        then
                echo "Stopping Torrent ${NAME} after ${TIME} seconds" >> torrentlog.log
                transmission-remote localhost:9091 -t $TORRENTID --stop &
        elif [ -z "$TIME" ]
        then
                PCT=`transmission-remote localhost:9091 --torrent $TORRENTID --info | grep "Percent Done"`
                echo "${NAME} is ${PCT}" >> torrentlog.log
        else
                echo "${NAME} has been running for ${TIME} seconds" >> torrentlog.log
        fi

done
