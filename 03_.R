library(glue)
library(rvest)
library(tidyverse)

source('nba/scrape/utils.R')

coaches = read_csv(glue('{outfolder}raw/coaches.csv'))

coaches %>% 
  filter(season > 2000) %>% 
  separate(coach.names, into = c('coach.name.1', 'coach.name.2', 'coach.name.3'), sep = ', ') %>% 
  separate(coach.urls, into = c('coach.url.1', 'coach.url.2', 'coach.url.3'), sep = '\\|\\|') %>% 
  unite(col = 'coach.1', coach.name.1, coach.url.1, sep = '__') %>%
  unite(col = 'coach.2', coach.name.2, coach.url.2, sep = '__', na.rm = TRUE) %>% 
  unite(col = 'coach.3', coach.name.3, coach.url.3, sep = '__', na.rm = TRUE) %>% 
  select(-season.url) %>% 
  pivot_longer(-team.name:-season, names_to = 'coach.order', values_to = 'value') %>% 
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
  select(team.name, team.id, season, coach.order, coach.name, coach.id, coach.wins, coach.losses, coach.games)
