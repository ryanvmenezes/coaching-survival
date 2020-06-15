library(glue)
library(rvest)
library(tidyverse)

source('nba/scrape/utils.R')

index.scrape = tibble(url = '/teams/') %>% 
  mutate(
    teams.html = map(url, get.or.read.html),
    teams.a = map(
      teams.html,
      ~.x %>% 
        html_nodes('#teams_active') %>% 
        html_nodes('tr.full_table') %>% 
        html_node('th a')
    ),
    team.url = map(
      teams.a,
      ~.x %>% 
        html_attr('href')
    ),
    team.name = map(
      teams.a,
      ~.x %>% 
        html_text()
    ),
  )

index.scrape

teams = index.scrape %>% 
  select(team.name, team.url) %>% 
  unnest(c(team.name, team.url))

teams

teams %>% write_csv(glue('{outfolder}raw/teams.csv'))
