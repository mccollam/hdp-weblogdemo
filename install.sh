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

sitename=`echo $sitetitle | sed s/\ //g`

# Figure out our distro
# TODO: SuSE support
distro=""
if grep -i centos /etc/redhat-release &> /dev/null
then
	distro=centos
fi
if grep -i red /etc/redhat-release &> /dev/null
then
	distro=rhel
fi
if grep -i ubuntu /etc/lsb-release &> /dev/null
then
	distro=ubuntu
fi

if [[ $distro = "" ]]
then
	echo "Unknown distro:"
	cat /etc/lsb-release
	exit 1
fi

case $distro in
	centos | rhel)
		apache_base=/etc/httpd
		apache_pkg=httpd
		apache_conf_dir="$apache_base/conf.d"
		apache_restart_cmd="service httpd restart"
		install_cmd="yum install"
		enable_site_cmd="true" # No site management on Red Hat :(
		#webaccesslog=/var/log/httpd/access_log
		#weberrorlog=/var/log/httpd/error_log
		;;
	ubuntu)
		apache_base=/etc/apache2
		apackhe_pkg=apache2
		apache_conf_dir="$apache_base/sites_available"
		apache_restart_cmd="service apache2 restart"
		install_cmd="apt-get install"
		enable_site_cmd="a2ensite"
		#webaccesslog=/var/log/apache2/access.log
		#weberrorlog=/var/log/apache2/error.log
		;;
	*)
		echo "Error -- unknown distribution $distro!  Aborting...";
		exit 1
		;;
esac

webaccesslog="/opt/$sitename/weblogs/access.log"
weberrorlog="/opt/$sitename/weblogs/error.log"

##### Make sure packages are installed
if ! $install_cmd $apache_pkg
then
	echo "Error installing $apache_pkg!  Aborting..."
	exit 1
fi

##### Set up a new site
if ! mkdir -p "/opt/$sitename/www"
then
	echo "Error creating /opt/$sitename/www!  Aborting..."
	exit 1
fi

if ! mkdir -p "/opt/$sitename/weblogs"
then
	echo "Error creating /opt/$sitename/weblogs!  Aborting..."
	exit 1
fi

if ! cp -r bootstrap/* "/opt/$sitename/www/"
then
	echo "Error copying Bootstrap Framework to /opt/$sitename/www!  Aborting..."
	exit 1
fi

cat << EOF > "$apache_conf_dir/$sitename.conf"
# Setup for $sitename
Listen $port
<VirtualHost *:$port>
  DocumentRoot /opt/$sitename/www
  ErrorLog $weberrorlog
  CustomLog $webaccesslog common
</VirtualHost>
EOF

cat << EOF > "/opt/$sitename/www/index.html"
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>$sitename</title>

    <!-- Bootstrap -->
    <link href="css/bootstrap.min.css" rel="stylesheet">
    <link href="css/custom.css" rel="stylesheet">

    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
	<script>
		function handleButton(btn) {
			var url = "btn.html?btn=" + btn;

			var xmlHttp = new XMLHttpRequest();
			xmlHttp.open("GET", url, false);
			xmlHttp.send(null);
		}
	</script>
  </head>
  <body>
    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="js/bootstrap.min.js"></script>

	<div class="jumbotron">
		<div class="container">
			<div class="row text-center" id="rowtime">
				<strong><h1>Welcome to $sitetitle</h1></strong>
				<h2>$sitedesc</h2>
			</div>
		</div>
	</div>

	<div class="container">
		<div class="row text-center"><h2>$category1:</h2></div>
		<div class="row">
			<div class="column col-md-4 text-left">
				<button class="btn btn-lg btn-block btn-primary" onClick="handleButton('$c1btn1');">$c1btn1</button>
			</div>
			<div class="column col-md-4 text-center">
				<button class="btn btn-lg btn-block btn-warning" onClick="handleButton('$c1btn2');">$c1btn2</button>
			</div>
			<div class="column col-md-4 text-right">
				<button class="btn btn-lg btn-block btn-danger" onClick="handleButton('$c1btn3');">$c1btn3</button>
			</div>
		</div>
		<div class="row text-center"><h2>$category2:</h2></div>
		<div class="row">
			<div class="column col-md-4 text-left">
				<button class="btn btn-lg btn-block btn-success" onClick="handleButton('$c2btn1');">$c2btn1</button>
			</div>
			<div class="column col-md-4 text-center">
				<button class="btn btn-lg btn-block btn-info" onClick="handleButton('$c2btn2');">$c2btn2</button>
			</div>
			<div class="column col-md-4 text-right">
				<button class="btn btn-lg btn-block btn-default" onClick="handleButton('$c2btn3');">$c2btn3</button>
			</div>
		</div>
		<div class="row text-center"><h2>Broken links:</h2></div>
		<div class="row">
			<div class="column col-md-3">&nbsp;</div>
			<div class="column col-md-3 text-left"><a href="badpage1.html">Broken link 1</a></div>
			<div class="column col-md-3 text-right"><a href="badpage2.html">Broken link 2</a></div>
			<div class="column col-md-3">&nbsp;</div>
		</div>
	</div>

  </body>
</html>
EOF

cat << EOF > "/opt/$sitename/www/btn.html"
<html>
<head><title>Button Handler</title></head>
<body>This space intentionally left blank.</body>
</html>
EOF

if ! $enable_site_cmd $sitename
then
	echo "Unable to enable $sitename site!  Aborting..."
	exit 1
fi

if ! $apache_restart_cmd
then
	echo "Unable to restart apache!  Aborting..."
	exit 1
fi

##### Set up flume
if ! mkdir -p "/opt/$sitename/flume/flume.out"
then
	echo "Unable to create /opt/$sitename/flume/flume.out!  Aborting..."
	exit 1
fi

cat << EOF > "/opt/$sitename/flume/avroaccess.conf"
#http://flume.apache.org/FlumeUserGuide.html#avro-source
collector.sources = AvroIn
collector.sources.AvroIn.type = avro
collector.sources.AvroIn.bind = 0.0.0.0
collector.sources.AvroIn.port = 4545
collector.sources.AvroIn.channels = mc1 mc2

## Channels ##
## Source writes to 2 channels, one for each sink
collector.channels = mc1 mc2

#http://flume.apache.org/FlumeUserGuide.html#memory-channel

collector.channels.mc1.type = memory
collector.channels.mc1.capacity = 100

collector.channels.mc2.type = memory
collector.channels.mc2.capacity = 100

## Sinks ##
collector.sinks = LocalOut HadoopOut

## Write copy to Local Filesystem
#http://flume.apache.org/FlumeUserGuide.html#file-roll-sink
collector.sinks.LocalOut.type = file_roll
collector.sinks.LocalOut.sink.directory = /opt/$sitename/flume/flume.out
collector.sinks.LocalOut.sink.rollInterval = 0
collector.sinks.LocalOut.channel = mc1

## Write to HDFS
#http://flume.apache.org/FlumeUserGuide.html#hdfs-sink
collector.sinks.HadoopOut.type = hdfs
collector.sinks.HadoopOut.channel = mc2
#collector.sinks.HadoopOut.hdfs.path = /user/$hadoopuser/web-access-logs/%{log_type}/%y%m%d
collector.sinks.HadoopOut.hdfs.path = /user/$hadoopuser/web-access-logs/%y%m%d
collector.sinks.HadoopOut.hdfs.fileType = DataStream
collector.sinks.HadoopOut.hdfs.writeFormat = Text
collector.sinks.HadoopOut.hdfs.rollSize = 0
collector.sinks.HadoopOut.hdfs.rollCount = 10000
collector.sinks.HadoopOut.hdfs.rollInterval = 600
EOF

cat << EOF > "/opt/$sitename/flume/avroerror.conf"
#http://flume.apache.org/FlumeUserGuide.html#avro-source
collector.sources = AvroIn
collector.sources.AvroIn.type = avro
collector.sources.AvroIn.bind = 0.0.0.0
collector.sources.AvroIn.port = 4546
collector.sources.AvroIn.channels = mc1 mc2

## Channels ##
## Source writes to 2 channels, one for each sink
collector.channels = mc1 mc2

#http://flume.apache.org/FlumeUserGuide.html#memory-channel

collector.channels.mc1.type = memory
collector.channels.mc1.capacity = 100

collector.channels.mc2.type = memory
collector.channels.mc2.capacity = 100

## Sinks ##
collector.sinks = LocalOut HadoopOut

## Write copy to Local Filesystem
#http://flume.apache.org/FlumeUserGuide.html#file-roll-sink
collector.sinks.LocalOut.type = file_roll
collector.sinks.LocalOut.sink.directory = /opt/$sitename/flume/flume.out
collector.sinks.LocalOut.sink.rollInterval = 0
collector.sinks.LocalOut.channel = mc1

## Write to HDFS
#http://flume.apache.org/FlumeUserGuide.html#hdfs-sink
collector.sinks.HadoopOut.type = hdfs
collector.sinks.HadoopOut.channel = mc2
#collector.sinks.HadoopOut.hdfs.path = /user/$hadoopuser/web-error-logs/%{log_type}/%y%m%d
collector.sinks.HadoopOut.hdfs.path = /user/$hadoopuser/web-error-logs/%y%m%d
collector.sinks.HadoopOut.hdfs.fileType = DataStream
collector.sinks.HadoopOut.hdfs.writeFormat = Text
collector.sinks.HadoopOut.hdfs.rollSize = 0
collector.sinks.HadoopOut.hdfs.rollCount = 10000
collector.sinks.HadoopOut.hdfs.rollInterval = 600
EOF


cat << EOF > "/opt/$sitename/flume/access.conf"
# http://flume.apache.org/FlumeUserGuide.html#exec-source
source_agent.sources = apache_server
source_agent.sources.apache_server.type = exec
source_agent.sources.apache_server.command = tail -f $webaccesslog
source_agent.sources.apache_server.batchSize = 1
source_agent.sources.apache_server.channels = memoryChannel
source_agent.sources.apache_server.interceptors = itime ihost itype

# http://flume.apache.org/FlumeUserGuide.html#timestamp-interceptor
source_agent.sources.apache_server.interceptors.itime.type = timestamp

# http://flume.apache.org/FlumeUserGuide.html#host-interceptor
source_agent.sources.apache_server.interceptors.ihost.type = host
source_agent.sources.apache_server.interceptors.ihost.useIP = false
source_agent.sources.apache_server.interceptors.ihost.hostHeader = host

# http://flume.apache.org/FlumeUserGuide.html#static-interceptor
source_agent.sources.apache_server.interceptors.itype.type = static
source_agent.sources.apache_server.interceptors.itype.key = log_type
source_agent.sources.apache_server.interceptors.itype.value = apache_access_combined

# http://flume.apache.org/FlumeUserGuide.html#memory-channel
source_agent.channels = memoryChannel
source_agent.channels.memoryChannel.type = memory
source_agent.channels.memoryChannel.capacity = 100

## Send to Flume Collector on Hadoop Node
# http://flume.apache.org/FlumeUserGuide.html#avro-sink
source_agent.sinks = avro_sink
source_agent.sinks.avro_sink.type = avro
source_agent.sinks.avro_sink.channel = memoryChannel
source_agent.sinks.avro_sink.hostname = localhost
source_agent.sinks.avro_sink.port = 4545
EOF

cat << EOF > "/opt/$sitename/flume/error.conf"
# http://flume.apache.org/FlumeUserGuide.html#exec-source
source_agent.sources = apache_server
source_agent.sources.apache_server.type = exec
source_agent.sources.apache_server.command = tail -f $weberrorlog
source_agent.sources.apache_server.batchSize = 1
source_agent.sources.apache_server.channels = memoryChannel
source_agent.sources.apache_server.interceptors = itime ihost itype

# http://flume.apache.org/FlumeUserGuide.html#timestamp-interceptor
source_agent.sources.apache_server.interceptors.itime.type = timestamp

# http://flume.apache.org/FlumeUserGuide.html#host-interceptor
source_agent.sources.apache_server.interceptors.ihost.type = host
source_agent.sources.apache_server.interceptors.ihost.useIP = false
source_agent.sources.apache_server.interceptors.ihost.hostHeader = host

# http://flume.apache.org/FlumeUserGuide.html#static-interceptor
source_agent.sources.apache_server.interceptors.itype.type = static
source_agent.sources.apache_server.interceptors.itype.key = log_type
source_agent.sources.apache_server.interceptors.itype.value = apache_access_combined

# http://flume.apache.org/FlumeUserGuide.html#memory-channel
source_agent.channels = memoryChannel
source_agent.channels.memoryChannel.type = memory
source_agent.channels.memoryChannel.capacity = 100

## Send to Flume Collector on Hadoop Node
# http://flume.apache.org/FlumeUserGuide.html#avro-sink
source_agent.sinks = avro_sink
source_agent.sinks.avro_sink.type = avro
source_agent.sinks.avro_sink.channel = memoryChannel
source_agent.sinks.avro_sink.hostname = localhost
source_agent.sinks.avro_sink.port = 4546
EOF

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
echo "Logs output to HDFS location /user/$hadoopuser/web-access-logs and /user/$hadoopuser/web-error-logs"
echo
