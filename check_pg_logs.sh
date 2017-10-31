#!/bin/bash

SLOW_WARNING=1
SLOW_CRITICAL=5


MINUTES=5

# Get pg version
PG_VERSION=$(ps faux | grep postgresql.conf | egrep -o 'postgresql/.*/main' | cut -d '/' -f 2)

LOGFILE=/var/log/postgresql/postgresql-$PG_VERSION-main.log

# Try pgbadger
pgbadger=$(pgbadger -x text -o - -v $LOGFILE -x text --begin "$(date --date="$MINUTES minutes ago" '+%Y-%m-%d %H:%M:%S')" 2>/dev/null)

ret=$?

if ! [ $ret -eq 0 ]; then
    echo "UNKNOWN: pgbadger returned $ret"
    exit 3
fi

# Get counters
total=$(echo "$pgbadger" | grep '^Number of queries:' | cut -d ' ' -f 4 | sed 's/,//')
if [ "$total" -eq 0 ]; then
    select_per_m=0
    insert_per_m=0
    update_per_m=0
    delete_per_m=0
    others_per_m=0
else
    nb_select=$(echo "$pgbadger" | grep '^SELECT:'| cut -d ' ' -f 2 | sed 's/,//')
    nb_insert=$(echo "$pgbadger" | grep '^INSERT:'| cut -d ' ' -f 2 | sed 's/,//')
    nb_update=$(echo "$pgbadger" | grep '^UPDATE:'| cut -d ' ' -f 2 | sed 's/,//')
    nb_delete=$(echo "$pgbadger" | grep '^DELETE:'| cut -d ' ' -f 2 | sed 's/,//')
    nb_others=$(echo "$pgbadger" | grep '^OTHERS:'| cut -d ' ' -f 2 | sed 's/,//')

    # Convert to frequency per minute
    select_per_m=$(echo "scale=1;$nb_select/5" | bc)
    insert_per_m=$(echo "scale=1;$nb_insert/5" | bc)
    update_per_m=$(echo "scale=1;$nb_update/5" | bc)
    delete_per_m=$(echo "scale=1;$nb_delete/5" | bc)
    others_per_m=$(echo "scale=1;$nb_others/5" | bc)
fi
peak=$(echo "$pgbadger" | grep '^Query peak:' | cut -d ' ' -f 3 | sed 's/,//')


# Count slow queries (more than 1000ms)
nb_slow=$(dategrep $LOGFILE --last-minutes $MINUTES --format '%Y-%m-%d %H:%M:%S' 2>/dev/null | egrep 'duration: [0-9]{4,}\.' -o | wc -l)
slow_per_s=$(echo "scale=1;$nb_slow/5/60" | bc)


msg="$total queries loggued on last $MINUTES minutes | select=${select_per_m}req/m insert=${insert_per_m}req/m update=${update_per_m}req/m delete=${delete_per_m}req/m others=${others_per_m}req/m peak=${peak}req/s slow=${slow_per_s}req/s;$SLOW_WARNING;$SLOW_CRITICAL;"


if [ "$slow_per_s" -gt "$SLOW_CRITICAL" ]; then
    echo "CRITICAL - $slow_per_s slow queries over $msg"
    exit 2
elif [ "$slow_per_s" -gt "$SLOW_WARNING" ]; then
    echo "WARNING - $slow_per_s slow queries over $msg"
    exit 1
else
    echo "OK - $msg"
    exit 0
fi

