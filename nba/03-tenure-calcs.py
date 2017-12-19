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
        self.currszn = info['season']
        self.franchise = info['franchise']
        self.min_date = info['date']
        self.max_date = None
        self.left_truncated = (info['game_num'] == '1') and (info['season'] == '2001')

    def add_szn(self):
        self.seasons += 1

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
        
    T.max_date = gm['date']

tenures.append(T)

# summaries of a coach's entire tenure

tenure_summaries = [t.summarize() for t in tenures]

with open('data/tenures.json', 'w') as outfile:
    json.dump(tenure_summaries, outfile, indent=2)

settings.write_csv(
    tenure_summaries,
    'data/tenures-summarized.csv',
    ['slug','coach','coach_id','franchise','min_date','max_date','left_truncated'],
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