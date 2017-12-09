import csv

MIN_YEAR = 2001
MAX_YEAR = 2017
YEARS_TO_SCRAPE = range(MIN_YEAR, MAX_YEAR+1)

def read_csv(fpath, delimiter=','):
    with open(fpath) as csvfile:
        reader = csv.DictReader(csvfile, delimiter=delimiter)
        res = []
        for row in reader:
            res.append(row)
        return res

def write_csv(rows, fpath, headers):
    with open(fpath, 'w') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=headers)
        writer.writeheader()
        writer.writerows(rows)
