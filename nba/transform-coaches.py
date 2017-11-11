import csv

coaches = []
with open('sportsref-coaches.csv') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        if int(row['year']) > 2000 and int(row['year']) <= 2017:
            coaches.append(row)

def parse_coach(string):
    nr = string[:-1].split(" (")
    record = nr[1]
    wl = record.split("-")
    return nr[0], int(wl[0]), int(wl[1])

results = []

for line in coaches:
    chs = line['coaches_text'].split(", ")
    if len(chs) == 1:
        name, wins, losses = parse_coach(chs[0])
        res = {}
        res['team'] = line['team']
        res['franchise'] = line['franchise']
        res['year'] = line['year']
        res['coaches_text'] = line['coaches_text']
        res['name'] = name
        res['wins'] = wins
        res['losses'] = losses
        res['total_games'] = wins + losses
        res['order'] = 1
        results.append(res)
    else:
        order = len(chs)
        for c in reversed(chs):
            name, wins, losses = parse_coach(c)
            res = {}
            res['team'] = line['team']
            res['franchise'] = line['franchise']
            res['year'] = line['year']
            res['coaches_text'] = line['coaches_text']
            res['name'] = name
            res['wins'] = wins
            res['losses'] = losses
            res['total_games'] = wins + losses
            res['order'] = order
            results.append(res)
            order -= 1

headers = ['franchise','team','year','coaches_text','name','wins','losses','total_games','order']
with open('coaches-ordered.csv', 'w') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=headers)
    writer.writeheader()
    writer.writerows(results)
