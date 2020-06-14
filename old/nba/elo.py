import pandas as pd

elo_games = pd.read_csv('https://projects.fivethirtyeight.com/nba-model/nba_elo.csv')
elo_games.to_csv('elo/elo_538_latest.csv', index=False)

elo_games['t1_win'] = elo_games.apply(lambda row: row.score1 >= row.score2, axis=1)
elo_games['t2_win'] = elo_games.apply(lambda row: row.score2 > row.score1, axis=1)

t1 = elo_games[['date','season','playoff','team1','elo1_post','t1_win']]
t2 = elo_games[['date','season','playoff','team2','elo2_post','t2_win']]

t1.columns = t2.columns = ['date','season','playoff','team','elo', 'win']

elo_teams = pd.concat([t1,t2], axis=0).sort_values('date')

def standardize_franchises(row):
    franchise = ''
    if row.season >= 1980:
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

elo_teams = elo_teams[elo_teams.franchise != '']

elo_teams.to_csv('elo/elo_teams.csv',index=False)
