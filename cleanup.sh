#!/bin/bash

### Config:
dir="$(dirname $0)"
if ! . $dir/conf.sh
then
	echo "Unable to load configuration file $dir/conf.sh!  Aborting..."
	exit 1
fi
###

# This needs root
if [[ $EUID -ne 0 ]]
then
	echo "This script must be run as root."
	echo
	echo "RHEL/CentOS:  execute 'su -' and then run this script again"
	echo "Ubuntu:       run 'sudo $0'"
fi

echo ; echo ; echo
echo You are about to remove any existing log data that has been generated.
echo This will remove data from HDFS and the host filesystem
echo
echo THIS CANNOT BE UNDONE.
echo
read -p "Continue? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Kill host filesystem paths
	paths=( "$webaccesslog" "$weberrorlog" )
	tables=( "$hiveaccesslog" "$hiveerrorlog" )
	for p in "${paths[@]}"
	do
		if [ -e "$p"]
		then
			echo "Removing $p"
			if ! rm "$p" then echo "Failed!  Aborting..." && exit 1 ; fi
		else
			echo "NOTICE: $p does not exist (already removed?)"
		fi
	done

	# Drop hive tables
	for t in "${tables[@]}"
	do
		if ! hive -e "DROP TABLE $t;" then echo "Unable to drop table $t!  Aborting..." && exit 1 ; fi
	done
fi