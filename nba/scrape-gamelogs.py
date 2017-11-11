import csv
import time
import requests
from tqdm import tqdm
from bs4 import BeautifulSoup

URL = 'https://www.basketball-reference.com/teams/{}/{}_games.html'

teams = []
with open('sportsref-teams.psv') as csvfile:
    reader = csv.DictReader(csvfile, delimiter='|')
    for row in reader:
        teams.append(row)

results = []
years = range(2001, 2017)

for tm in tqdm(teams):
    for y in years:
        # time.sleep(0.1)
        s = tm['slug']
        f = s

        if s == 'OKC':
            f = 'SEAOKC'
            if y <= 2008:
                s = 'SEA'
        elif s == 'MEM':
            f = 'VANMEM'
            if y <= 2001:
                s = 'VAN'
        elif s == 'NJN':
            f = 'NJNBRK'
            if y >= 2013:
                s = 'BRK'
        elif s == 'CHA':
            f = 'CHARBH'
            if y >= 2015:
                s = 'CHO'
            elif y < 2005:
                continue
        elif s == 'NOH':
            f = 'NORLHP'
            if y >= 2014:
                s = 'NOP'
            elif y <= 2002:
                s = 'CHH'
            elif y == 2006 or y == 2007:
                s = 'NOK'

        req = requests.get(URL.format(s, y))
        soup = BeautifulSoup(req.text, "html5lib")

        tbl = soup.find("table", id="games").tbody.find_all('tr')
        for t in tbl:
            if not t.get('class'):
                res = {}
                res['franchise'] = f
                res['team'] = s
                res['season'] = y
                res['game_num'] = t.find(attrs={"data-stat": "g"}).text
                res['date'] = t.find(attrs={"data-stat": "date_game"})['csk']
                res['result'] = t.find(attrs={"data-stat": "game_result"}).text
                results.append(res)

headers = ['franchise','team','season','game_num','date','result']
with open('sportsref-gamelogs.csv', 'w') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=headers)
    writer.writeheader()
    writer.writerows(results)
