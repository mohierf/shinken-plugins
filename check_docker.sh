#!/bin/sh

docker="$(docker ps -q 2>/dev/null)"
ret=$?

if [ $ret -eq 0 ]; then
    count=$(echo "$docker" | wc -l)
    if [ $count -eq 0 ]; then
        echo "WARNING - no docker container running"
        exit 1
    else
        echo "OK - running $count docker container(s)"
        exit 0
    fi
else
    echo "CRITICAL - 'docker ps' returned $ret"
    exit 2
fi