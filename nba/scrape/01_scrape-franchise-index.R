library(glue)
library(rvest)
library(tidyverse)

source('nba/scrape/utils.R')

index.scrape = tibble(url = '/teams/') %>% 
  mutate(
    index.html = map(url, get.or.read.html),
    franchise.a = map(
      index.html,
      ~.x %>% 
        html_nodes('#teams_active') %>% 
        html_nodes('tr.full_table') %>% 
        html_node('th a')
    ),
    franchise.url = map(
      franchise.a,
      ~.x %>% 
        html_attr('href')
    ),
    franchise.name = map(
      franchise.a,
      ~.x %>% 
        html_text()
    ),
  )

index.scrape

franchises = index.scrape %>% 
  select(franchise.name, franchise.url) %>% 
  unnest(c(franchise.name, franchise.url))

franchises

franchises %>% write_csv(glue('{outfolder}processed/franchises.csv'))
