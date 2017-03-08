#!/bin/bash

total=$(/var/qmail/bin/qmail-qstat | grep 'messages in queue:' | cut -d ':' -f 2)
not_processed=$(/var/qmail/bin/qmail-qstat | grep 'messages in queue but not yet preprocessed:' | cut -d ':' -f 2)

msg="$total messages in queue ($not_processed not processed) | total=$total;;;;; notprocessed=$not_processed;;;;;"

if [[ $total < '10' ]] ; then
    echo "OK: $msg"
    exit 0
elif [[ $total < '50' ]] ; then
    echo "WARNING: $msg"
    exit 1
else
    echo "CRITICAL: $msg"
    exit 2
fi