library(glue)
library(rvest)
library(tidyverse)

source('nba/scrape/utils.R')

teams = read_csv(glue('{outfolder}processed/teams.csv'))

teams

teams.scrape = teams %>% 
  mutate(
    team.html = map(team.url, get.or.read.html),
    team.history.table = map(
      team.html,
      ~.x %>% 
        html_node('.stats_table')
    ),
    season = map(
      team.history.table,
      ~.x %>% 
        html_nodes('th[data-stat="season"][scope="row"]') %>% 
        html_text() %>% 
        str_trim() %>% 
        str_sub(end = 4) %>% 
        as.numeric() + 1
    ),
    season.url =  map(
      team.history.table,
      ~.x %>% 
        html_nodes('th[data-stat="season"][scope="row"]') %>% 
        html_node('a') %>% 
        html_attr('href')
    ),
    coach.names = map(
      team.history.table,
      ~.x %>% 
        html_nodes('td[data-stat="coaches"]') %>% 
        html_text() %>% 
        str_trim()
    ),
    coach.urls = map(
      team.history.table,
      ~.x %>% 
        html_nodes('td[data-stat="coaches"]') %>% 
        map_chr(~.x %>% html_nodes('a') %>% html_attr('href') %>% str_c(collapse = '||'))
    )
  )

teams.scrape

coaches = teams.scrape %>% 
  mutate(team.id = str_sub(team.url, start = -4, end = -2)) %>% 
  select(team.name, team.id, season, season.url, coach.names, coach.urls) %>% 
  unnest(c(season, season.url, coach.names, coach.urls))

coaches

coaches %>% write_csv(glue('{outfolder}raw/coaches.csv'))
