#!/bin/bash
#
# Look at db1 for a user.
#
# Should be run on tracker.
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

function check_db1_mysql_user {
     if [ ! -f /home/tekberg/.bashrc -o $(grep myvir /home/tekberg/.bashrc | wc -l) -eq 0 ]; then
	echo "Unable to check db1 mysql users"
    else
	db_user=$(grep myvir /home/tekberg/.bashrc | cut '-d ' -f4)
	db_password=$(grep myvir /home/tekberg/.bashrc | cut '-d ' -f5 | cut -d= -f2)
	db_name=mysql
	source=$(mktemp /tmp/db1-my.XXXXXXXXXX)
	echo "SELECT \`User\` FROM \`user\` WHERE \`User\` = '$uwnetid';" > $source
	my_out=$(mktemp /tmp/db1-out.XXXXXXXXXX)
	mysql -u $db_user --password=$db_password --database=$db_name -h $db_host --execute "source $source" > $my_out
	if [ -s $my_out ]; then
	    if [ "$json" = "yes" ]; then
		echo "\"db1_mysql_user\": true,"
	    else
		cat $my_out | uniq | awk "/$uwnetid/{print \"      \"\$0}"
	    fi
	else
	    if [ "$json" = "yes" ]; then
		echo "\"db1_mysql_user\": false,"
	    else
		echo "      No access"
	    fi
	fi
	rm $source
	rm $my_out
    fi
}

function check_db1_pg_user {
    count=0
    sql_out=$(mktemp /tmp/db1-pg-user.XXXXXXXXXX)
    sql="SELECT usename FROM pg_catalog.pg_user WHERE usename='$uwnetid';"
    psql -U residents --d labmed -h $db_host --quiet --tuples-only --command="$sql" > $sql_out
    if [ $(cat $sql_out | wc -l) -gt 1 ]; then
	if [ "$json" = "yes" ]; then
	    echo "\"db1_pg_user\": true,"
	else
	    cat $sql_out | awk '-F|' '{if ($1 != "") {printf("     %s\n", $1)}}'
	fi
        count=`expr $count \+ 1`
    fi
    rm $sql_out
    if [ $count -eq 0 ]; then
	if [ "$json" = "yes" ]; then
	    echo "\"db1_pg_user\": false,"
	else
            echo "      No access"
	fi
    fi
}

function check_db1_hba {
    if [ "$json" = "no" ]; then
	echo "    pg_hba.conf"
    fi
    db_host='db1.labmed.washington.edu'
    cd /home/transfers
    . ssh-agent-env.txt
    grep_out=$(mktemp /tmp/db1-hba.XXXXXXXXXX)
    ssh -T transfers@$db_host > $grep_out <<EOF
grep -P -c "\b$uwnetid\b" /var/lib/pgsql/data/pg_hba.conf 2> /dev/null
EOF
    if [[ -s $grep_out && $(cat $grep_out | tail -1) -gt 0 ]]; then
	if [ "$json" = "yes" ]; then
	    echo "\"db1_hba_conf\": true"
	else
	    echo "      $(cat $grep_out | tail -1)"
	fi
    else
	if [ "$json" = "yes" ]; then
	    echo "\"db1_hba_conf\": false"
	else
            echo "      No access"
	fi
    fi
    rm $grep_out
}

for uwnetid in $*; do
    count=0
    test_json ",{"
    if [ "$json" = "yes" ]; then
	echo "\"uwnetid\": \"$uwnetid\","
    else
	echo "  db1"
    fi
    check_db1_mysql_user
    check_db1_pg_user
    check_db1_hba
    test_json "}"
done

