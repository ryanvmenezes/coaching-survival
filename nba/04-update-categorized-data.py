import settings

## update POC categorization

rawcoaches = settings.read_csv('data/coach-list.csv')

oldpoc =  {
    l['coach_id']: (l['poc'], l['note'])
    for l in settings.read_csv('categorized/coach-list-poc.csv')
}

for coach in rawcoaches:
    poc = note = ''
    if coach['coach_id'] in oldpoc:
        poc, note = oldpoc[coach['coach_id']]
    coach['poc'] = poc
    coach['note'] = note

rawcoaches = sorted(rawcoaches, key=lambda x: (x['poc'], x['coach']), reverse=True)

settings.write_csv(
    rawcoaches,
    'categorized/coach-list-poc.csv',
    ['coach','coach_id','franchises','poc','note'],
)

## update NBA player categorization

rawcoaches = settings.read_csv('data/coach-list.csv')

oldplayed =  {
    l['coach_id']: l['former_nba_player']
    for l in settings.read_csv('categorized/coach-list-qualifications.csv')
}

for coach in rawcoaches:
    former_player = ''
    if coach['coach_id'] in oldplayed:
        former_player = oldplayed[coach['coach_id']]
    coach['former_nba_player'] = former_player

rawcoaches = sorted(rawcoaches, key=lambda x: x['former_nba_player'], reverse=True)

settings.write_csv(
    rawcoaches,
    'categorized/coach-list-poc.csv',
    ['coach','coach_id','franchises','former_nba_player'],
)


# rawtenures = settings.read_csv('data/tenures-summarized.csv')

# oldtenures =  {
#     c['slug']: c['ending']
#     for c in settings.read_csv('categorized/tenures-summarized-categorized.csv')
# }

# for coach in rawtenures:
#     ending = ''
#     if coach['slug'] in oldtenures:
#         ending = oldtenures[coach['slug']]
#     coach['ending'] = ending

# rawtenures = sorted(rawtenures, key=lambda x: (x['franchise'], x['min_year']))

# settings.write_csv(
#     rawtenures,
#     'categorized/tenures-summarized-categorized.csv',
#     ['slug','coach','franchise','seasons','games','wins','losses','min_year','max_year','left_truncated','ending'],
# )