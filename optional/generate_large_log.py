#!/usr/bin/env python

# Generate a sample Apache weblog
# 2015-06-02 Ronald McCollam <rmccollam@hortonworks.com>

# TODO: Accept command-line arguments to configure behavior rather than hard-coding things in variables

from datetime import datetime, timedelta
from random import randint, choice
import sys

# Number of days to go back for generating a log:
log_length = 30
# Number of events per day:
events_per_day = 100000
# Log file name
logfile = 'apache.log'
# Response codes, "weighted" by frequency in the array (yeah I know, but it's easy)
responses = [
	'200', '200', '200', '200', '200', '200', '200', '200', '200', '200', '200',
	'404', '404', '404', '404',
	'302', '302',
	'500'
]
# Pages that are 'served' by the site
pages_200 = [
	'/',
	'/about',
	'/images/bg.png',
	'/css/content.css',
	'/images/button.png',
	'/products',
	'/products/product1',
	'/products/product2',
	'/products/product3'
]
pages_404 = [
	'favicon.ico',
	'/about/schmidt',
	'/js/lib.js'
]
pages_302 = [
	'/contact',
	'/careers',
	'/jobs'
]
pages_500 = [
	'/products/add'
]
# Site referers (sic)
referers = [
	'', '', '',
	'http://www.google.com/', 'http://www.google.com/',
	'http://www.example.com'
]
# User agent strings
useragents = [
	'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:24.0) Gecko/20100101 Firefox/24.0',
	'Googlebot/2.1 (+http://www.googlebot.com/bot.html)',
	'Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)',
	'Opera/12.02 (Android 4.1; Linux; Opera Mobi/ADR-1111101157; U; en-US) Presto/2.9.201 Version/12.02',
	'Opera/9.80 (X11; Linux i686; Ubuntu/14.10) Presto/2.12.388 Version/12.16',
	'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36',
	'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.1 Safari/537.36',
	'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2226.0 Safari/537.36',
	'Mozilla/4.0 WebTV/2.6 (compatible; MSIE 4.0)' # tee hee
]

### End of configuration

now = datetime.now()
start = now + timedelta(days=-log_length)

# 86400000000 microseconds in a day / number of events per day
# gives us how often we should see an event
# TODO: Randomize this so we get event clustering rather than an even spread
event_frequency = 86400000000 / events_per_day

# Now we just start at the start time and generate an event every
# event_frequency until we get to the current time...
f = open(logfile, 'w')
cur = start
ctr = 0
interval = int((events_per_day * log_length) / 10)
print "Log will be written to", logfile, "starting at", start, "ending at", now
while (cur < now):
	cur += timedelta(microseconds=event_frequency)

	ip = str(randint(1,254)) + "." + str(randint(0,254)) + "." + str(randint(0,254)) + "." + str(randint(0,254))
	date = cur.strftime('[%d/%b/%Y:%H:%M:%S +0000]')
	status = choice(responses)
	bytes_returned = str(randint(1, 8192))
	referer = choice(referers)
	useragent = choice(useragents)

	if (status == '200'):
		page = choice(pages_200)
	elif (status == '404'):
		page = choice(pages_404)
	elif (status == '302'):
		page = choice(pages_302)
	elif (status == '500'):
		page = choice(pages_500)
	else:
		# This should never happen
		page = choice(pages_200)

	line = ip, "- -", date, '"GET', page, 'HTTP/1.1"', status, bytes_returned, '"' + referer + '"', '"' + useragent + '"'
	f.write(' '.join(line) + '\n')

	ctr += 1
	if ((ctr % interval) == 0):
		print str(ctr / interval) + "0%...",
		sys.stdout.flush()
f.close

print "Done!"