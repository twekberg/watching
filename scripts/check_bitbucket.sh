#!/bin/bash
#
# Look at bitbucket for membership.
#
# Should be run locally.
#
# Usage:
#   check_bitbucket.sh bb_json uwnetid...
#   bb_json - filename of bitbucket user list
#   uwnetid - one or more uwnetids.
#-------------------------------------------------------------------------------

json=yes

bb_json=/tmp/bb.json
# Output arg1 if json=yes.
function test_json {
    if [ "$json" = "yes" ]; then
	echo $1
    fi
}
bb_json=$1
shift
if [ ! -f "$bb_json" ]; then
    echo "Unable to read bitbucket file: $bb_json"
    exit 1
fi
if [ ! -s "$bb_json" ]; then
    echo "Bitbucket file is empty: $bb_json"
    exit 1
fi
for uwnetid in $*; do
    count=0
    test_json ",{"
    if [ "$json" = "yes" ]; then
	echo "\"uwnetid\": \"$uwnetid\""
    else
	echo "  Bitbucket"
    fi
    test_json ",\"bitbucket\": {"

    bb_out=$(mktemp /tmp/bb-out.XXXXXXXXXX)
    python scripts/where-bitbucket.py $uwnetid $bb_json > $bb_out
    status=$?
    if [ $status -eq 0 ]; then
	if [ "$json" = "yes" ]; then
	    echo "\"team_member\": true"
	    cat $bb_out | awk '{printf(", \"user\": \"%s\"", $2)}'
	else
            cat $bb_out | awk "/$uwnetid/{print \"    \"\$0}"
	fi
    else
	if [ "$json" = "yes" ]; then
	    echo "\"bitbucket_team_member\": false"
	else
            echo "    No access"
	fi
    fi
    rm $bb_out
    test_json "}}"
done
