import pandas as pd

elo_games = pd.read_csv('https://projects.fivethirtyeight.com/nba-model/nba_elo.csv')
elo_games.to_csv('elo/elo_538_latest.csv', index=False)

t1 = elo_games[['date','season','team1','elo1_post',]]
t2 = elo_games[['date','season','team2','elo2_post',]]

t1.columns = t2.columns = ['date','season','team','elo']

elo_teams = pd.concat([t1,t2], axis=0)
elo_teams = elo_teams[elo_teams.elo.notnull()]

def standardize_franchises(row):
    franchise = ''
    if row.season >= 2000:
        if row.team == 'OKC' or row.team == 'SEA':
            franchise = 'SEAOKC'
        elif row.team == 'MEM' or row.team == 'VAN':
            franchise = 'VANMEM'
        elif row.team == 'NJN' or row.team == 'BRK':
            franchise = 'NJNBRK'
        elif row.team == 'CHH' or row.team == 'NOP' or row.team == 'NOK':
            franchise = 'NORLHP'
        elif row.team == 'CHO':
            franchise = 'CHARBH'
        else:
            franchise = row.team
    return franchise

elo_teams['franchise'] = elo_teams.apply(standardize_franchises, axis=1)

elo_teams.to_csv('elo/elo_teams.csv',index=False)

# games = pd.read_csv('data/tenures-cumulative-calcs.csv')

# tenures = pd.read_csv('categorized/tenures-summarized-categorized.csv')



