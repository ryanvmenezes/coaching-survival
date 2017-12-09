import csv
import json
import settings

coaches = settings.read_csv('data/coaches-ordered.csv')

# coaches must appear in the right order for this to work
coaches = sorted(coaches, key=lambda x: (x['franchise'], x['year'], x['order']))

# make a "lookup" such that team_look[team_name][game_num] returns the coach for that game
team_look = {}
for c in coaches:
    f = c['franchise']
    s = c['year']
    g = int(c['games'])
    ch = c['coach']
    if not team_look.get(f):
        team_look[f] = {}
    if not team_look[f].get(s):
        team_look[f][s] = []
    for i in range(0, g):
        team_look[f][s].append(ch)

with open('data/team-coach-lookup.json', 'w') as outfile:
    json.dump(team_look, outfile, indent=2)

# attach the coach's name to each game
games = settings.read_csv('scrape/sportsref-gamelogs.csv')
for g in games:
    g['coach'] = team_look[g['franchise']][g['season']][int(g['game_num'])-1]

settings.write_csv(
    games,
    'data/gamelogs-coaches.csv',
    ['franchise','team','season','game_num','date','result','coach'],
)
