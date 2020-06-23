library(glue)
library(rvest)
library(tidyverse)

source('nba/scrape/utils.R')

franchises = read_csv(glue('{outfolder}processed/franchises.csv'))

franchises

franchise.scrape = franchises %>% 
  mutate(
    franchise.html = map(franchise.url, get.or.read.html),
    franchise.history.table = map(
      franchise.html,
      ~.x %>% 
        html_node('.stats_table')
    ),
    season = map(
      franchise.history.table,
      ~.x %>% 
        html_nodes('th[data-stat="season"][scope="row"]') %>% 
        html_text() %>% 
        str_trim() %>% 
        str_sub(end = 4) %>% 
        as.numeric() + 1
    ),
    season.url = map(
      franchise.history.table,
      ~.x %>% 
        html_nodes('th[data-stat="season"][scope="row"]') %>% 
        html_node('a') %>% 
        html_attr('href')
    ),
    season.team.name = map(
      franchise.history.table,
      ~.x %>%
        html_nodes('td[data-stat="team_name"]') %>%
        html_text() %>%
        str_trim() %>% 
        str_replace('\\*', '')
    ),
    coach.names = map(
      franchise.history.table,
      ~.x %>% 
        html_nodes('td[data-stat="coaches"]') %>% 
        html_text() %>% 
        str_trim()
    ),
    coach.urls = map(
      franchise.history.table,
      ~.x %>% 
        html_nodes('td[data-stat="coaches"]') %>% 
        map_chr(~.x %>% html_nodes('a') %>% html_attr('href') %>% str_c(collapse = '||'))
    )
  )

franchise.scrape

seasons = franchise.scrape %>% 
  mutate(
    franchise.id = str_sub(franchise.url, start = -4, end = -2),
    season.team.id = map(season.url, ~str_sub(.x, start = 8, end = 10)),
  ) %>% 
  select(franchise.name, franchise.id, season, season.team.id, season.url, season.team.name, coach.names, coach.urls) %>% 
  unnest(c(season, season.team.id, season.url, coach.names, season.team.name, coach.urls))

seasons

seasons %>% write_csv(glue('{outfolder}processed/seasons.csv'))
