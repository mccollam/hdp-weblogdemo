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

paths=( "$webaccesslog" "$weberrorlog" )
hdfspaths=( "$hdfsaccesspath" "$hdfserrorpath")
tables=( "$hiveaccesslog" "$hiveerrorlog" )
procs=$(ps ax | grep -i flume | grep -v grep | awk '{ print $1 }')

echo ; echo ; echo
echo You are about to remove any existing log data that has been generated.
echo This will remove data from HDFS and the host filesystem!
echo
echo Actions that will be taken:
echo "   Delete files:"
for p in "${paths[@]}" ; do echo "     $p" ; done
echo
echo "   Delete all data from HDFS paths:"
for h in "${hdfspaths[@]}" ; do echo "     $h" ; done
echoecho "   Drop Hive tables:"
for t in "${tables[@]}" ; do echo "      $t" ; done
echo
echo "   Processes terminated:"
for p in $procs ; do echo "      $p" ; done
if [[ $procs = "" ]] ; then echo "      (none)" ; fi
echo ; echo
echo THIS CANNOT BE UNDONE.
echo ; echo
read -p "Continue? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Kill the processes
	if [[ $procs != "" ]]
	then
		if ! kill $procs
		then
			echo "Unable to kill Flume/Avro processes!  Aborting..."
			exit 1
		fi
	fi

	# Delete host filesystem paths
	for p in "${paths[@]}"
	do
		if [ -e "$p" ]
		then
			echo "Removing $p"
			if ! rm "$p" ; then echo "Failed!  Aborting..." && exit 1 ; fi
		else
			echo "NOTICE: $p does not exist (already removed?)"
		fi
	done

	# Drop hive tables
	for t in "${tables[@]}"
	do
		if ! hive -e "DROP TABLE $t;" ; then echo "Unable to drop table $t!  Aborting..." && exit 1 ; fi
	done

	# Clean up HDFS
	for h in "${hdfspaths[@]}"
	do
		if ! hdfs dfs -rm $h/*
		then
			echo "NOTICE: Unable to remove files from HDFS path $h!"
		fi
	done
else
	echo "Aborting cleanup."
	exit 0
fi

echo ; echo ; echo
echo Cleanup complete!  You can now run \"install.sh\" and then \"run.sh\" to re-deploy the demo.