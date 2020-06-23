library(glue)
library(rvest)
library(tidyverse)

source('nba/scrape/utils.R')

seasons = read_csv(glue('{outfolder}processed/seasons.csv'))

seasons

coaches.scrape = seasons %>% 
  select(url = coach.urls) %>% 
  separate_rows(url, sep = '\\|\\|') %>% 
  mutate(
    coach.id = str_replace_all(url, '/coaches/', ''),
    coach.id = str_replace_all(coach.id, '.html', ''),
  ) %>% 
  distinct(coach.id, url) %>% 
  mutate(
    html = map(url, get.or.read.html),
    info = map(
      html,
      ~.x %>% 
        html_node('div[itemtype="https://schema.org/Person"]')
    ),
    name = map_chr(
      info,
      ~.x %>% 
        html_node('h1') %>% 
        html_text()
    ),
    dob = map_chr(
      info,
      ~.x %>% 
        html_node('span[id="necro-birth"]') %>% 
        html_attr('data-birth')
    ),
    dod = map_chr(
      info,
      ~.x %>% 
        html_node('span[id="necro-death"]') %>% 
        html_attr('data-death')
    )
  )

coaches.scrape

coaches = coaches.scrape %>% 
  select(coach.id, name, dob, dod)

coaches

coaches %>% write_csv(glue('{outfolder}processed/coaches.csv'), na = '')
