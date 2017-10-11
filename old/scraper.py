import requests
import csv
from bs4 import BeautifulSoup
from time import sleep

leagues = {
	'basketball': 62,
	# 'football': 171,
	# 'baseball': 151,
	# 'hockey': 84,
}

url = "http://www.prosportstransactions.com/{}/Search/SearchResults.php?Player=coach&Team=&BeginDate=2000-07-01&EndDate=&PlayerMovementChkBx=yes&Submit=Search&start={}"

for sport, maxpages in leagues.iteritems():
	with open('data/coaching_changes_{}_00.psv'.format(sport),'w') as csvfile:
		csv_writer = csv.writer(csvfile,delimiter='|')
		csv_writer.writerow(['date','team','acquired','relinquished','notes'])
		for i in range(0, maxpages):
			if sport == 'baseball':
				r = requests.get(url.replace('coach','manager').format(sport, i*25))
			else:
				r = requests.get(url.format(sport, i*25))
			soup = BeautifulSoup(r.text)
			rows = soup.find('table',{'class':'datatable center'}).findAll('tr')
			for r in rows[1:]:
				csv_writer.writerow([s.string.encode('ascii','ignore').strip() if s.string is not None else '' for s in r.findAll('td')])
			sleep(2)
			print "done with {} page {}".format(sport, i)
