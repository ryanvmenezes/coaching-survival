library(glue)
library(rvest)
library(tidyverse)

source('nba/utils.R')

seasons = read_csv(glue('{outfolder}scrape/processed/seasons.csv'))

seasons

coaches = seasons %>% 
  # treat charlotte bobcats as expansion team and give hornets history to pelicans
  mutate(
    franchise.id = case_when(
      season < 2003 & franchise.id == 'CHA' ~ 'NOH',
      TRUE ~ franchise.id
    ),
    franchise.name = case_when(
      season < 2003 & franchise.name == 'Charlotte Hornets' ~ 'New Orleans Pelicans',
      TRUE ~ franchise.name
    )
  ) %>% 
  separate(coach.names, into = c('coach.name.1', 'coach.name.2', 'coach.name.3', 'coach.name.4'), sep = ', ') %>% 
  separate(coach.urls, into = c('coach.url.1', 'coach.url.2', 'coach.url.3', 'coach.url.4'), sep = '\\|\\|') %>% 
  unite(col = 'coach.1', coach.name.1, coach.url.1, sep = '__') %>%
  unite(col = 'coach.2', coach.name.2, coach.url.2, sep = '__', na.rm = TRUE) %>% 
  unite(col = 'coach.3', coach.name.3, coach.url.3, sep = '__', na.rm = TRUE) %>% 
  unite(col = 'coach.4', coach.name.4, coach.url.4, sep = '__', na.rm = TRUE) %>% 
  select(-season.url) %>% 
  pivot_longer(-franchise.name:-season.team.name, names_to = 'coach.order', values_to = 'value') %>% 
  filter(value != '') %>% 
  separate(value, into = c('coach.name.wl', 'coach.id'), sep = '__') %>%
  separate(coach.name.wl, into = c('coach.name', 'coach.wl'), sep = ' \\(') %>% 
  mutate(
    coach.wl = str_replace(coach.wl, '\\)', '')
  ) %>% 
  separate(coach.wl, into = c('coach.wins', 'coach.losses'), sep = '-') %>% 
  mutate(
    coach.wins = as.numeric(coach.wins),
    coach.losses = as.numeric(coach.losses),
    coach.games = coach.wins + coach.losses,
    coach.order = str_replace(coach.order, 'coach.', ''),
    coach.order = as.numeric(coach.order),
    coach.id = str_replace_all(coach.id, '/coaches/', ''),
    coach.id = str_replace_all(coach.id, '.html', ''),
  ) %>% 
  select(franchise.name, franchise.id, season.team.name, season.team.id, season, coach.order, coach.name, coach.id, coach.wins, coach.losses, coach.games) %>% 
  arrange(franchise.name, season, coach.order) %>% 
  mutate(
    tenure.chg = (franchise.name != lag(franchise.name)) |
      (coach.id != lag(coach.id)),
    tenure.chg = replace_na(tenure.chg, TRUE),
    tenure.id = cumsum(tenure.chg)
  )

coaches

tenures = coaches %>%
  group_by(tenure.id) %>%
  summarise(
    coach.id = first(coach.id),
    franchise.id = first(franchise.id),
    start.year = min(season),
    end.year = max(season),
    coach.wins = sum(coach.wins),
    coach.losses = sum(coach.losses),
    coach.games = sum(coach.games),
    .groups = 'drop'
  ) %>%
  mutate(tenure.slug = str_c(coach.id, franchise.id, start.year, end.year, sep = '_'))

tenures

game.logs = read_csv(glue('{outfolder}scrape/processed/game-logs.csv'))

game.logs

download.file(
  'https://projects.fivethirtyeight.com/nba-model/nba_elo.csv',
  glue('{outfolder}raw/nba-elo-538.csv')
)

nba.elo = read_csv(glue('{outfolder}raw/nba-elo-538.csv'), guess_max = 100000)

nba.elo

elo.by.team.date = nba.elo %>%
  select(date, season, season.team.id = team1, elo = elo1_pre) %>% 
  bind_rows(
    nba.elo %>% 
      select(date, season, season.team.id = team2, elo = elo2_pre)
  ) %>% 
  rename(game.date = date) %>% 
  mutate(
    season.team.id = case_when(
      season >= 2003 & season <= 2013 & season.team.id == 'NOP' ~ 'NOH',
      season >= 2005 & season <= 2014 & season.team.id == 'CHO' ~ 'CHA',
      TRUE ~ season.team.id
    )
  )

elo.by.team.date

games.by.tenure = game.logs %>% 
  # same manual edit for charlotte/new orleans
  mutate(
    franchise.id = case_when(
      franchise.id == 'CHA' & season < 2003 ~ 'NOH',
      TRUE ~ franchise.id
    )
  ) %>% 
  left_join(elo.by.team.date) %>% 
  left_join(
    coaches %>% 
      left_join(
        tenures %>% 
          select(tenure.id, tenure.slug)
      ) %>%
      select(franchise.id, season, coach.order, coach.id, coach.games, tenure.slug) %>% 
      group_by(franchise.id, season) %>% 
      mutate(game.number = cumsum(coach.games)) %>% 
      ungroup() %>% 
      select(franchise.id, season, game.number, tenure.slug)
  ) %>% 
  arrange(franchise.id, season, game.number) %>% 
  group_by(franchise.id) %>% 
  fill(tenure.slug, .direction = 'up') %>% 
  # impute a handful of missing elo ratings
  group_by(franchise.id, season) %>% 
  mutate(
    elo = case_when(
      is.na(elo) ~ (lead(elo) + lag(elo)) / 2,
      TRUE ~ elo
    )
  ) %>% 
  ungroup()

games.by.tenure

coaches %>% write_csv(glue('{outfolder}raw/coaches.csv'))
tenures %>% write_csv(glue('{outfolder}raw/tenures.csv'))
games.by.tenure %>% write_csv(glue('{outfolder}raw/games-by-tenure.csv'))