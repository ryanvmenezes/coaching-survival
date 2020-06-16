library(glue)
library(rvest)
library(tidyverse)

source('nba/utils.R')

seasons = read_csv(glue('{outfolder}scrape/processed/seasons.csv'))

seasons

coaches = seasons %>% 
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
  select(franchise.name, franchise.id, season.team.name, season, coach.order, coach.name, coach.id, coach.wins, coach.losses, coach.games) %>% 
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

games.by.tenure = game.logs %>% 
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
  fill(tenure.slug, .direction = 'up')

games.by.tenure

coaches %>% write_csv(glue('{outfolder}raw/coaches.csv'))
tenures %>% write_csv(glue('{outfolder}raw/tenures.csv'))
games.by.tenure %>% write_csv(glue('{outfolder}raw/games-by-tenure.csv'))