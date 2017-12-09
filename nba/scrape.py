import csv
import requests
import settings

from tqdm import tqdm
from bs4 import BeautifulSoup

GAMELOGS_URL = 'https://www.basketball-reference.com/teams/{}/{}_games.html'
TEAMS_URL = 'https://www.basketball-reference.com/teams/{}/'

teams = settings.read_csv('scrape/sportsref-teams.psv', delimiter='|')

gamelogs = []
coaches = []

for tm in tqdm(teams, desc='teams'):

    # scrape game logs for specified seasons

    for y in tqdm(settings.YEARS_TO_SCRAPE, desc='years'):
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

        gamelogreq = requests.get(GAMELOGS_URL.format(s, y))
        gamelogsoup = BeautifulSoup(gamelogreq.text, "html5lib")

        tbl = gamelogsoup.find("table", id="games").tbody.find_all('tr')
        for t in tbl:
            if not t.get('class'):
                gamelogres = {}
                gamelogres['franchise'] = f
                gamelogres['team'] = s
                gamelogres['season'] = y
                gamelogres['game_num'] = t.find(attrs={"data-stat": "g"}).text
                gamelogres['date'] = t.find(attrs={"data-stat": "date_game"})['csk']
                gamelogres['result'] = t.find(attrs={"data-stat": "game_result"}).text
                gamelogs.append(gamelogres)

    # scrape all coaches for a team
    
    teamreq = requests.get(TEAMS_URL.format(tm['slug']))
    teamsoup = BeautifulSoup(teamreq.text, "html5lib")

    tbl = teamsoup.find("table", "stats_table").tbody.find_all('tr')
    for t in tbl:
        if not t.get('class'):
            coachres = {}
            coachres['year'] = int(t.find(attrs={"data-stat": "season"}).text[:4]) + 1
            y = coachres['year']

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
            
            coachres['team'] = s
            coachres['franchise'] = f
            coachres['coaches_text'] = t.find(attrs={"data-stat": "coaches"}).text
            coaches.append(coachres)


settings.write_csv(
    gamelogs,
    'scrape/sportsref-gamelogs.csv',
    ['franchise','team','season','game_num','date','result']
)

settings.write_csv(
    coaches,
    'scrape/sportsref-coaches.csv',
    ['franchise','team','year','coaches_text']
)