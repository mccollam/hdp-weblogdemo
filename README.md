# hdp-weblogdemo
A demo for ingesting web logs within HDP

Prerequisites
-------------
This requires a Hortonworks sandbox image, which can be downloaded from [the Hortonworks website] (http://hortonworks.com/hdp/downloads).

Configuration
-------------
Edit the file 'conf.sh' to configure the deployed environment.  The defaults should work in a standard sandbox.

Deployment
----------
Copy the contents of this repository to the running sandbox VM and run 'install.sh'.

Use
---
After installation, use 'run.sh' to start the demo.

The script will create a set of Flume services and an instance of Apache with a sample website.  (By default this runs on port 81).  If you are running the sandbox in VirtualBox you will need to forward a local port to port 81 in the sandbox in order to access this website.

Click around on the website, and web logs will be generated.  Clicking one of the (intentionally) broken links at the bottom of the page will generate errors that will go into the error log.  The log data is ingested by Flume and will appear in HDFS in the user directory configured in conf.sh.

The following external tables are created in Hive and pointed to the logs ingested by Flume:
* access_log - Web access logs
* error_log - Web error logs

Cleaning up
-----------
Once you are finished, run 'cleanup.sh' to remove any generated log and hive data and prep the environment for the next time.  (Not cleaning up won't cause any issues, but will cause you to have older data already in the hive tables when starting next time.)