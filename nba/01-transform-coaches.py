import csv
import settings

coaches = settings.read_csv('scrape/sportsref-coaches.csv')
coaches = filter(
    lambda x: int(x['year']) >= settings.MIN_YEAR and int(x['year']) <= settings.MAX_YEAR,
    coaches,
)

# parse sports-reference coach strings into name, wins, losses
# where there are multiple coaches in a season, create one row per coach, in the correct order

def parse_coach(string):
    nr = string[:-1].split(" (")
    record = nr[1]
    wl = record.split("-")
    return nr[0], int(wl[0]), int(wl[1])

results = []

for line in coaches:
    chs = line['coaches_text'].split(", ")
    order = len(chs)
    for c in reversed(chs):
        name, wins, losses = parse_coach(c)
        res = {}
        res['team'] = line['team']
        res['franchise'] = line['franchise']
        res['year'] = line['year']
        res['coaches_text'] = line['coaches_text']
        res['coach'] = name
        res['wins'] = wins
        res['losses'] = losses
        res['games'] = wins + losses
        res['order'] = order
        results.append(res)
        order -= 1

settings.write_csv(
    results,
    'data/coaches-ordered.csv',
    ['franchise','team','year','coaches_text','coach','wins','losses','games','order']
)
