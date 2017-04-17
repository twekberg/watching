#!/bin/bash
#
# Look at wikis for a user
#
#-------------------------------------------------------------------------------

cd /home/moinmoin
json=no

for uwnetid in $*; do
    echo $user
    # Look in the *Group and *Reviewers* files.
    for current in $(find . '(' -wholename "*/*Group/current" \
			     -o -wholename "*/*Reviewers*/current" ')' -type f | sort); do
	up1=`dirname $current`
	page=`cat $current`
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
		n_times=`cat $grep_out | wc -l`
		count=`expr $count \+ $n_times`
	    fi
	fi
	rm $grep_out
	rm $awk_scr
    done
done
