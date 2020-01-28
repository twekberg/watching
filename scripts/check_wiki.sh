#!/bin/bash
#
# Look at wikis for a user
#
#-------------------------------------------------------------------------------

# Output arg1 if json=yes.
function test_json {
    if [ "$json" = "yes" ]; then
	echo $1
    fi
}

cd /home/moinmoin
json=yes

for uwnetid in $*; do
    count=0
    n_times=0
    test_json ",{"
    if [ "$json" = "yes" ]; then
	echo "\"uwnetid\": \"$uwnetid\""
    else
	echo $uwnetid
	echo "  Wikis"
    fi
    test_json ",\"wiki\": ["
    # Look in the *Group and *Reviewers* files.
    for current in $(find . '(' -wholename "*/*Group/current" \
			     -o -wholename "*/*Reviewers*/current" ')' -type f | sort); do
	up1=$(dirname $current)
	page=$(cat $current)
	awk_scr=$(mktemp /tmp/wiki-awk.XXXXXXXXXX)
	echo "{print \"$up1 \"\$0}" > $awk_scr
	grep_out=$(mktemp /tmp/wiki-grep.XXXXXXXXXX)
	# Deleted pages have current pointing one beyond the last revision.
	if [ -f $up1/revisions/$page ]; then
	    grep -P "\b$uwnetid\b" $up1/revisions/$page | awk -f $awk_scr > $grep_out
	    if [ -s $grep_out ]; then
		if [ "$json" = "yes" ]; then
		    cat $grep_out | awk -v count=$count '
					 {
					   if ( count > 0 ) {
					     count++;
					     comma=",";
					   }
					   print comma"\""$1"\"";
					 }'
		else
		    cat $grep_out | awk '{print "    "$0}'
		fi
		n_times=$(cat $grep_out | wc -l)
		count=$(expr $count \+ $n_times)
	    fi
	fi
	rm $grep_out
	rm $awk_scr
    done

    admin_page='labmanual/data/pages/IT(2e)PR(2e)A(2e)GEN(20)Administering(20)Web(20)Applications'
    page=$(cat "$admin_page/current")
    grep_out=$(mktemp /tmp/wiki-labmanual.XXXXXXXXXX)
    grep -P -c "\b$uwnetid\b" "$admin_page/revisions/$page" > $grep_out
    status=$?
    if [ $status -eq 0 ]; then
        # Found a match
	if [ "$json" = "yes" ]; then
	    comma=
	    if [ $count -gt 0 ]; then
		comma=","
	    fi
	    echo "$comma\"$admin_page\""
	else
            echo "    ./$admin_page $uwnetid $(cat $grep_out)" | sed 's/(20)/ /g' | sed 's/(2e)/./g'
	fi
        count=$(expr $count \+ $n_times)
    fi
    rm $grep_out

    config_farm=farmconfig.py
    if [ ! -f "$config_farm" ]; then
	echo "Unable to find moinlm/config/farmconfig.py file."
    else
	grep_out=$(mktemp /tmp/wiki-farm.XXXXXXXXXX)
	grep -P -c "\b$uwnetid\b" "$config_farm" > $grep_out
	status=$?
	if [ $status -eq 0 ]; then
            # Found a match
	    if [ "$json" = "yes" ]; then
		comma=
		if [ $count -gt 0 ]; then
		    comma=","
		fi
		echo "$comma\"$config_farm\""
	    else
		echo "    $config_farm $uwnetid"
	    fi
            count=`expr $count \+ 1`
	fi
	rm $grep_out
    fi
    test_json "]"
    test_json "}"
    if [ "$count" = "0" ]; then
	if [ "$json" = "no" ]; then
	    echo "    No access"
	fi
    fi
done
