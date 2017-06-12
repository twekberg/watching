#!/bin/bash
#
# Look at the database for a residents user.
#
# Should be run on tracker host.
#
#-------------------------------------------------------------------------------

json=yes

# Output arg1 if json=yes.
function test_json {
    if [ "$json" = "yes" ]; then
	echo $1
    fi
}
db_host='db1.labmed.washington.edu'

for uwnetid in $*; do
    count=0
    test_json ",{"
    if [ "$json" = "yes" ]; then
	echo "\"uwnetid\": \"$uwnetid\""
    else
	echo "  Trackers"
    fi
    test_json ",\"residents_db\": {\"users\": ["

    sql_out=$(mktemp /tmp/residents.XXXXXXXXXX)
    sql="SELECT id,networkid,auth_level FROM users WHERE networkid='$uwnetid';"
    psql -U residents --d labmed -h $db_host --quiet --tuples-only --command="$sql" > $sql_out
    if [ $(cat $sql_out | wc -l) -gt 1 ]; then
	if [ "$json" = "yes" ]; then
	    cat $sql_out | awk '-F|' '
                                      {
                                        if ($1 != "") {
                                          gsub(/ /, "", $2);
                                          printf("{\"id\":%s, \"user\":\"%s\", \"auth_level\":%s}\n", $1, $2, $3)
                                        }
                                      }'
	    count=`expr $count \+ 1`
	else
	    if [ $(cat $sql_out | wc -l) -gt 1 ]; then
		cat $sql_out | awk '-F|' '{if ($1 != "") {printf("  %s|%s|%s\n", $1, $2, $3)}}'
		count=`expr $count \+ 1`
	    fi
	fi
    fi
    rm $sql_out
    if [ $count -eq 0 ]; then
	if [ "$json" = "yes" ]; then
	    echo "{}"
	else
            echo "    No access"
	fi
    fi
    test_json "]}}"
done
