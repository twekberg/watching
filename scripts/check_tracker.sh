#!/bin/bash
#
# Look at the database for a tracker user.
#
# Should be run on tracker.
#
#-------------------------------------------------------------------------------

json=no

# Output arg1 if json=yes.
function test_json {
    if [ "$json" = "yes" ]; then
	echo $1
    fi
}
db_host='db1.labmed.washington.edu'
count=0

for uwnetid in $*; do
    echo $uwnetid
    if [ ! -d /var/www/html/it ]; then
	if [ "$json" = "no" ]; then
            echo "    >> Log into tracker host to check tracker users."
	fi
        return 0
    fi
    if [ "$json" = "no" ]; then
	echo "  Trackers"
    fi
    test_json ",\"tracker\": {\"users\": ["

    for db in `psql  -U roundup -h $db_host --dbname it --list --quiet --tuples-only | \
      grep ' roundup ' | \
      cut '-d ' -f2`; do
        sql_out=$(mktemp /tmp/tracker.XXXXXXXXXX)
	sql="SELECT id,_username FROM _user WHERE _username='$uwnetid' and __retired__=0;"
        psql -U roundup --dbname $db -h $db_host --quiet --tuples-only --command="$sql" > $sql_out
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
    test_json "], \"page_references\": ["
    # Look at the automatic nosy list.
    grep "nosy_people.*$uwnetid" /var/www/html/*/detectors/nosy-issue-people.py | \
        awk '{print "    "$0}'
    # Look at the ulist variable in some trackers. This is a hardcoded list of some UWNetIDs.
    first="yes"
    for tracker in `echo 'it'; echo 'it_test'`; do
        for user_list in `echo 'ulist'; echo 'cast_list'`; do
            grep "$user_list python" /var/www/html/$tracker/html/page.html | grep -P "\s$uwnetid'|'$uwnetid\s|\s$uwnetid\s" > /dev/null
            status=$?
            if [ $status -eq 0 ]; then
                # Found a match there.
                count=`expr $count \+ 1`
		if [ "$json" = "yes" ]; then
		    if [ "$first" = "yes" ]; then
			first=no
			comma=""
		    else
			comma=","
		    fi
		    echo "$comma{\"page\": \"page.html\", \"variable\": \"$user_list\", \"tracker\": \"$tracker\"}"
		else
                    echo "    page.html $user_list in $tracker tracker"
		fi
            fi
        done
	# issue.item.html has a user list too.
        user_list="compstaff_ulist"
        grep "$user_list python" /var/www/html/$tracker/html/issue.item.html | grep -P "'$uwnetid,|,$uwnetid'|,$uwnetid," > /dev/null
        status=$?
        if [ $status -eq 0 ]; then
            # Found a match there.
            count=$(expr $count \+ 1)
	    if [ "$json" = "yes" ]; then
		if [ "$first" = "yes" ]; then
		    first=no
		    comma=""
		else
		    comma=","
		fi
		echo "$comma{\"page\": \"issue.item.html\", \"variable\": \"$user_list\", \"tracker\": \"$tracker\"}"
	    else
		echo "    issue.item.html $user_list in $tracker tracker"
	    fi
        fi
    done
    if [ $count -eq 0 ]; then
	if [ "$json" = "no" ]; then
            echo "    No access"
	fi
    fi
    test_json "]}"
done
