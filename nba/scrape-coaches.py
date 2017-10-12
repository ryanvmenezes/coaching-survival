import csv
import time
import requests
from tqdm import tqdm
from bs4 import BeautifulSoup

URL = 'https://www.basketball-reference.com/teams/{}/'

teams = []
with open('sportsref-teams.psv') as csvfile:
    reader = csv.DictReader(csvfile, delimiter='|')
    for row in reader:
        teams.append(row)

results = []
for tm in tqdm(teams):
    r = requests.get(URL.format(tm['slug']))
    soup = BeautifulSoup(r.text, "html5lib")

    tbl = soup.find("table", "stats_table").tbody.find_all('tr')
    for t in tbl:
        if not t.get('class'):
            res = {}
            res['team'] = tm['slug']
            res['year'] = t.find(attrs={"data-stat": "season"}).text
            res['coaches_text'] = t.find(attrs={"data-stat": "coaches"}).text
            results.append(res)

    # time.sleep(0.5)

headers = ['team','year','coaches_text']
with open('sportsref-coaches.csv', 'w') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=headers)
    writer.writeheader()
    writer.writerows(results)
