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

### Start up Flume
echo
echo "About to start flume; wait until the logs stop scrolling quite so"
echo "insanely and then you can view the incoming logs in HDFS in"
echo "/user/$hadoopuser/web-access-logs and /user/$hadoopuser/web-error-logs."
echo
for (( i=5; i>0; i-- ))
do
	echo -n "$i... "
	sleep 1
done
echo "Here we go!"

if ! flume-ng agent -c conf -f /opt/$sitename/flume/avroaccess.conf -n collector &
then
	echo "Unable to start access log collector!  Aborting..."
	exit 1
fi
sleep 10

if ! flume-ng agent -c conf -f /opt/$sitename/flume/avroerror.conf -n collector &
then
	echo "Unable to start error log collector!  Aborting..."
	exit 1
fi
sleep 10

if ! flume-ng agent -c conf -f /opt/$sitename/flume/access.conf -n source_agent &
then
	echo "Unable to start access log source!  Aborting..."
	exit 1
fi
sleep 5

if ! flume-ng agent -c conf -f /opt/$sitename/flume/error.conf -n source_agent &
then
	echo "Unable to start error log source!  Aborting..."
	exit 1
fi

sleep 30

ip=`ifconfig eth0 | grep inet | grep -v inet6 | awk '{ print $2 }' | sed s/addr://` # Yeah yeah, but it's easy
echo
echo
echo "You should now be able to access the following:"
echo "http://$ip:$port/"
echo "(If using VirtualBox you will need to forward a port from localhost to port $port"
echo "and use that instead.)"
echo
echo "Logs output to HDFS location /user/$hadoopuser/web-access-logs and"
echo "/user/$hadoopuser/web-error-logs"
echo