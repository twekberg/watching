#!/bin/bash
#
# Look at the database for a tracker user.
#
# Should be run on tracker host.
#
#-------------------------------------------------------------------------------
logging=no
# Append timestamp and arg1 to log file if logging=yes, 
function log {
    if [ "$logging" = "yes" ]; then
	echo "$(date +%Y-%m-%d.%H:%M:%S) $1" >> /tmp/watch-log.txt
    fi
}
log "Start"

json=yes

# Output arg1 if json=yes.
function test_json {
    if [ "$json" = "yes" ]; then
	echo $1
    fi
}
# This host has all of the trackers so we can
# do a query there to find them.
db_host='db3.labmed.uw.edu'

TRACKER_HOME=/mnt/trackers

for uwnetid in $*; do
    log "working on user $uwnetid"
    count=0
    if [ ! -d $TRACKER_HOME/it ]; then
	if [ "$json" = "no" ]; then
            echo "    >> Log into tracker host to check tracker users."
	fi
        return 0
    fi
    test_json ",{"
    if [ "$json" = "yes" ]; then
	echo "\"uwnetid\": \"$uwnetid\""
    else
	echo "  Trackers"
    fi
    test_json ",\"tracker\": {\"users\": ["

    log "before tracker db loop"
    # We don't really care about the it tracker. We just need a place to run
    # the --list command.
    for db in `psql  -U roundup -h $db_host --dbname it --list --quiet --tuples-only | \
      grep ' roundup ' | \
      cut '-d ' -f2`; do
	# Locate the config.ini file. Some have it in the chem/ directory.
	if [ -f $TRACKER_HOME/$db/config.ini ]; then
	    config=$TRACKER_HOME/$db/config.ini
	else
	    if [ -f $TRACKER_HOME/chem/$db/config.ini ]; then
		config=$TRACKER_HOME/chem/$db/config.ini
	    else
		echo "Unable to find config.ini for $db" > /dev/stderr
		continue
	    fi
	fi
	# This is the DB host used by the tracker.
	tracker_db_host=$(grep '^host = ' $config |grep -P -v '^#'|grep -v localhost|cut '-d ' -f3)
	maybe_db_host=$(grep $tracker_db_host /etc/hosts | awk '{print $2}')
	if [ "$maybe_db_host" = "" ]; then
	  # Translate that host, which could be an IP address or ssh alias into a
	  # fully qualified domain name. This is needed for the .pgpass file.
	  tracker_db_host=$(nslookup $tracker_db_host | grep -i name | awk '{print $(NF)}' | sed 's/\.$//')
	else
	    # maybe_db_host is the fully qualified name.
	    tracker_db_host="$maybe_db_host"
	fi
	# The DB user isn't always roundup.
	tracker_user=$(grep 'user' $config | grep roundup | cut '-d ' -f3)
	log "for tracker $db db host=$tracker_db_host, db user=tracker_user"
        sql_out=$(mktemp /tmp/tracker.XXXXXXXXXX)
	sql="SELECT id,_username FROM _user WHERE _username='$uwnetid' and __retired__=0;"
        psql -U $tracker_user --dbname $db -h $tracker_db_host --quiet --tuples-only --command="$sql" > $sql_out
	if [ $(cat $sql_out | wc -l) -gt 1 ]; then
	    if [ "$json" = "yes" ]; then
		comma=""
		if [ $count -gt 0 ]; then
		    comma=","
		fi
		echo "$comma\"$db\""
	    else
		awk '-F|' -v db=$db '{if ($1 != "") {printf("   %s|%s | %s\n", $1, $2, db)}}' < $sql_out
	    fi
            count=`expr $count \+ 1`
	fi
        rm $sql_out
    done
    test_json "]"
    if [ $count -eq 0 ]; then
	if [ "$json" = "no" ]; then
            echo "    No access"
	fi
    fi
    test_json "}}"
done
