import csv
import time
import requests
from tqdm import tqdm
from bs4 import BeautifulSoup

URL = 'https://www.sports-reference.com/cfb/schools/{}/{}/gamelog'

teams = []
with open('sportsref-teams.psv') as csvfile:
    reader = csv.DictReader(csvfile, delimiter='|')
    for row in reader:
        if row['category'] == 'major':
            teams.append(row)

results = []
years = range(2000, 2017)

for tm in tqdm(teams):
    for y in years:
        # time.sleep(0.1)
        r = requests.get(URL.format(tm['slug'], y))
        soup = BeautifulSoup(r.text, "html5lib")

        tbl = soup.find("table", id="offense").tbody.find_all('tr')
        for t in tbl:
            res = {}
            res['team'] = tm['slug']
            res['season'] = y
            res['game_num'] = t.find(attrs={"data-stat": "ranker"}).text
            res['date'] = t.find(attrs={"data-stat": "date_game"}).text
            res['result'] = t.find(attrs={"data-stat": "game_result"}).text[:1]
            results.append(res)

headers = ['team','season','game_num','date','result']
with open('sportsref-gamelogs.csv', 'w') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=headers)
    writer.writeheader()
    writer.writerows(results)
