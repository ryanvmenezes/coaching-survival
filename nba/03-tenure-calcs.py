import csv
import json
import settings

games = settings.read_csv('data/gamelogs-coaches.csv')
games = sorted(games, key=lambda x: (x['franchise'], x['date']))

with open('scrape/sportsref-coach-master-list.py','r') as f:
    txt = f.read()
name_look = json.loads(txt)

class Tenure(object):
    def __init__(self, info):
        self.coach_id = info['coach']
        self.coach = name_look[info['coach']]
        self.results = []
        self.currszn = info['season']
        self.seasons = 1
        self.franchise = info['franchise']
        self.min_date = info['date']
        self.max_date = None
        self.left_truncated = (info['game_num'] == '1') and (info['season'] == '2001')

    def win(self):
        self.results.append(True)

    def loss(self):
        self.results.append(False)

    def add_szn(self):
        self.seasons += 1

    def cumulative_record(self, gmnum):
        return {
            'slug': self.slugify(),
            'games': gmnum,
            'wins': sum(self.results[:i]),
            'pct': sum(self.results[:i]) / float(i),
            'last_game': True if gmnum == len(self.results) else None
        }

    def slugify(self):
        return "{}|{}|{}|{}".format(
            self.coach_id,
            self.min_date[2:4],
            self.max_date[2:4] if self.max_date is not None else 'xx',
            self.franchise
        )

    def summarize(self):
        return {
            'coach': self.coach,
            'coach_id': self.coach_id,
            # 'results': self.results,
            'games': len(self.results),
            'wins': sum(self.results),
            'losses': len(self.results) - sum(self.results),
            # 'currszn': self.currszn,
            'seasons': self.seasons,
            'franchise': self.franchise,
            'min_date': self.min_date,
            'max_date': self.max_date,
            'left_truncated': self.left_truncated,
            'slug': self.slugify()
        }

tenures = []
T = None

for gm in games:
    if not T: T = Tenure(gm)

    newcoach = (gm['coach'] != T.coach_id)
    newfranchise = (gm['franchise'] != T.franchise)

    if newcoach or newfranchise:
        tenures.append(T)
        T = Tenure(gm)

    if gm['season'] != T.currszn:
        T.add_szn()
        T.currszn = gm['season']
        
    T.max_date = gm['date']

    T.win() if gm['result'] == 'W' else T.loss()

tenures.append(T)

# summaries of a coach's entire tenure

tenure_summaries = [t.summarize() for t in tenures]

with open('data/tenures.json', 'w') as outfile:
    json.dump(tenure_summaries, outfile, indent=2)

settings.write_csv(
    tenure_summaries,
    'data/tenures-summarized.csv',
    ['slug','coach','coach_id','franchise','seasons','games','wins','losses','min_date','max_date','left_truncated'],
)

# unique coach names and franchises they coached for

coach_names = set([(t.coach, t.coach_id) for t in tenures])
coach_info = [{
    'coach': n[0],
    'coach_id': n[1],
    'franchises': '|'.join(set(t.franchise for t in tenures if t.coach_id == n[1]))
} for n in coach_names]

settings.write_csv(
    coach_info,
    'data/coach-list.csv',
    ['coach','coach_id','franchises'],
)