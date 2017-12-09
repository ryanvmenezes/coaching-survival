import settings

raw = settings.read_csv('data/coach-list.csv')

existing =  {
    l['coach']: (l['poc'], l['note'])
    for l in settings.read_csv('categorized/coach-list-poc.csv')
}

for coach in raw:
    poc = note = ''
    if coach['coach'] in existing:
        poc, note = existing[coach['coach']]
    coach['poc'] = poc
    coach['note'] = note