import settings

rawpoc = settings.read_csv('data/coach-list.csv')

oldpoc =  {
    l['coach']: (l['poc'], l['note'])
    for l in settings.read_csv('categorized/coach-list-poc.csv')
}

for coach in rawpoc:
    poc = note = ''
    if coach['coach'] in oldpoc:
        poc, note = oldpoc[coach['coach']]
    coach['poc'] = poc
    coach['note'] = note

rawpoc = sorted(rawpoc, key=lambda x: (x['poc'], x['coach']), reverse=True)

settings.write_csv(
    rawpoc,
    'categorized/coach-list-poc.csv',
    ['coach','coach_id','franchises','poc','note'],
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