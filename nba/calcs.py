import csv
import json

coaches = []
with open('coaches-ordered-corrected.csv') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        cleaned = {}
        cleaned['team'] = row['franchise']
        cleaned['season'] = row['year']
        cleaned['coach'] = row['name']
        cleaned['games'] = int(row['total_games'])
        if row['correct_order'] == '':
            cleaned['order'] = int(row['order'])
        else:
            cleaned['order'] = int(row['correct_order'])

        coaches.append(cleaned)

coaches = sorted(coaches, key=lambda x: x['order'])

team_look = {}

for c in coaches:
    t = c['team']
    s = c['season']
    g = c['games']
    ch = c['coach']
    if not team_look.get(t):
        team_look[t] = {}
    if not team_look[t].get(s):
        team_look[t][s] = []
    for i in range(0, g):
        team_look[t][s].append(ch)

with open('team-coach-lookup.json', 'w') as outfile:
    json.dump(team_look, outfile, indent=2)

games = []
with open('sportsref-gamelogs.csv') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        row['coach'] = team_look[row['franchise']][row['season']][int(row['game_num'])-1]
        games.append(row)

headers = ['franchise','team','season','game_num','date','result','coach']
with open('gamelogs-coaches.csv', 'w') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=headers)
    writer.writeheader()
    writer.writerows(games)

class Tenure(object):
    def __init__(self, info):
        self.coach = info['coach']
        self.results = []
        self.currszn = info['season']
        self.seasons = 1
        self.franchise = info['franchise']
        self.min_year = info['season']
        self.max_year = info['season']
        self.left_censor = (info['game_num'] == '1') and (info['season'] == '2001')

    def win(self):
        self.results.append(True)

    def loss(self):
        self.results.append(False)

    def add_szn(self):
        self.seasons += 1

    def slugify(self):
        return "{}|{}|{}|{}".format(
            self.coach.lower().split()[-1],
            self.min_year[2:4],
            self.max_year[2:4],
            self.franchise
        )

games = sorted(games, key=lambda x: (x['franchise'], x['date']))
tenures = []
T = Tenure(games[0])
for gm in games[1:]:
    newcoach = (gm['coach'] != T.coach)
    newfranchise = (gm['franchise'] != T.franchise)

    if newcoach or newfranchise:
        tenures.append(T)
        T = Tenure(gm)

    if gm['season'] != T.currszn:
        T.add_szn()
        T.currszn = gm['season']
        T.max_year = gm['season']

    if gm['result'] == 'W':
        T.win()
    else:
        T.loss()

tenures.append(T)

tenure_summ = [{
    'coach': t.coach,
    'results': t.results,
    'games': len(t.results),
    'wins': sum(t.results),
    'losses': len(t.results) - sum(t.results),
    'currszn': t.currszn,
    'seasons': t.seasons,
    'franchise': t.franchise,
    'min_year': t.min_year,
    'max_year': t.max_year,
    'left_censor': t.left_censor,
    'slug': t.slugify()
} for t in tenures]

with open('tenures.json', 'w') as outfile:
    json.dump(tenure_summ, outfile, indent=2)

headers = ['slug','coach','franchise','seasons','games','wins','losses','min_year','max_year','left_censor']
with open('tenures-summarized.csv', 'w') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=headers)
    writer.writeheader()
    writer.writerows([{k: g[k] for k in g if k not in ['results','currszn']} for g in tenure_summ])

tenures_calcs = []
for t in tenures:
    for i in range(1, 3000):
        if len(t.results) < i:
            break
        tenures_calcs.append({
            'slug': t.slugify(),
            'games': i,
            'wins': sum(t.results[:i]),
            'pct': sum(t.results[:i]) / float(i),
        })

headers = ['slug','games','wins','pct']
with open('tenure-calcs.csv', 'w') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=headers)
    writer.writeheader()
    writer.writerows(tenures_calcs)


coach_names = set([t.coach for t in tenures])
coach_info = []
for n in coach_names:
    coach_info.append({
        'coach': n,
        'franchises': '|'.join(set(t.franchise for t in tenures if t.coach == n))
    })

headers = ['coach','franchises']
with open('coach-list.csv', 'w') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=headers)
    writer.writeheader()
    writer.writerows(coach_info)
