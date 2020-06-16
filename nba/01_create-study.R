library(glue)
library(rvest)
library(tidyverse)

source('nba/utils.R')

coaches = read_csv(glue('{outfolder}raw/coaches.csv'))

coaches

tenures = read_csv(glue('{outfolder}raw/tenures.csv'))

tenures

games.by.tenure = read_csv(glue('{outfolder}raw/games-by-tenure.csv'))

games.by.tenure

coach.names = read_csv(glue('{outfolder}scrape/processed/coaches.csv'))

coach.names

# subset tenures
# looking at coaching tenures from the 1998-99 season to 2018-19

tenures.study = tenures %>% 
  filter(start.year >= 1999 | (start.year <= 2000 & end.year >= 2000))

# who are the coaches in this period?

coaches.study = coach.names %>% 
  select(coach.id, name) %>% 
  right_join(
    tenures.study %>% 
      group_by(coach.id) %>% 
      summarise(franchises = str_c(franchise.id, collapse = ', '))
  ) %>% 
  arrange(coach.id)
  
coaches.study

# coaches need to be categorized as POC, qualifications, etc

coaches.study %>% write_csv(glue('{outfolder}processed/coaches.csv'), na = '')

# tenures need to be marked by how they ended

tenures.study %>% write_csv(glue('{outfolder}processed/tenures.csv'), na = '')
