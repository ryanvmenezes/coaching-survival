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
            res['year'] = int(t.find(attrs={"data-stat": "season"}).text[:4]) + 1
            y = res['year']

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
                elif y > 2002 and y < 2005:
                    continue
                elif y <= 2002:
                    f = 'NORLHP'
                    s = 'CHH'
            elif s == 'NOH':
                f = 'NORLHP'
                if y >= 2014:
                    s = 'NOP'
                # elif y <= 2002:
                #     s = 'CHH'
                elif y == 2006 or y == 2007:
                    s = 'NOK'
            res['team'] = s
            res['franchise'] = f
            res['coaches_text'] = t.find(attrs={"data-stat": "coaches"}).text
            results.append(res)

    # time.sleep(0.5)

headers = ['franchise','team','year','coaches_text']
with open('sportsref-coaches.csv', 'w') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=headers)
    writer.writeheader()
    writer.writerows(results)
