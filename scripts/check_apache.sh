#!/bin/bash
#
# Look at the .htgroup file for a user.
#
# Should be run on apps.
#
#-------------------------------------------------------------------------------

json=yes

# Output arg1 if json=yes.
function test_json {
    if [ "$json" = "yes" ]; then
	echo $1
    fi
}
test_json "["
first_time="yes"
for uwnetid in $*; do
    comma=
    if [ "$first_time" = "no" ]; then
	comma=","
    fi
    test_json "$comma{"
    first_time="no"
    if [ "$json" = "yes" ]; then
	echo "\"uwnetid\": \"$uwnetid\""
    else
	echo "$uwnetid"
	echo "  Apache groups"
    fi

    test_json ",\"apache\": ["

    # Implementation note: all calls to mktemp have their own name in case
    # the file is not deleted.
    grep_out=$(mktemp /tmp/apache.XXXXXXXXXX)
    grep -H -P "\b$uwnetid\b" /etc/apache2/.htgroup | grep -v ':#' | cut "-d " -f1 > $grep_out
    if [ "$json" = "yes" ]; then
	if [ -s $grep_out ]; then
	    cat $grep_out | awk '-F:' '{
				   if ( done_first == 0 ) {
				     done_first = 1;
				     comma="";
				   } else {
				     comma=",";
				   }
				   print comma"\""$2"\"";
				 }'
	fi    
    else
	if [ -s $grep_out ]; then
	    cat $grep_out | awk '{print "    "$0}'
	else
	    echo "    No access"
	fi
    fi
    test_json "]"
    test_json "}"
    rm $grep_out
done
