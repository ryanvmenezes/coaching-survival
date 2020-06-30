library(glue)
library(rvest)
library(tidyverse)
library(googlesheets4)

source('nba/utils.R')

coaches = read_csv(glue('{outfolder}raw/coaches.csv'))

coaches

tenures = read_csv(glue('{outfolder}raw/tenures.csv'))

tenures

games.by.tenure = read_csv(glue('{outfolder}raw/games-by-tenure.csv'))

games.by.tenure

coach.names = read_csv(glue('{outfolder}scrape/processed/coaches.csv'))

coach.names

# subset tenures to just ones that were active in 2000, and all after it

tenures.study = coach.names %>% 
  select(coach.id, name) %>% 
  right_join(
    tenures %>% 
    filter(start.year >= 2000 | (start.year <= 2000 & end.year >= 2000))
  ) %>% 
  arrange(franchise.id, tenure.id)

tenures.study

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

# join to manually categorized data ---------------------------------------

sheeturl = 'https://docs.google.com/spreadsheets/d/1CnFI-QxRaKwt_MUUup68a8makUGL2jpwXium_H0l4Tc/edit#gid=0'
gs4_auth(email = 'ryanvmenezes@gmail.com')

# coaches need to be categorized as POC, qualifications, etc

coaches.tagged = read_sheet(sheeturl, sheet = 'nba-coaches')

coaches.tagged

coaches.joined = coaches.study %>% 
  left_join(
    coaches.tagged %>%
      select(-franchises)
  )

coaches.joined

coaches.joined %>% write_csv(glue('{outfolder}processed/coaches.csv'), na = '')
coaches.joined %>% write_sheet(ss = sheeturl, sheet = 'nba-coaches')

# tenures need to be marked by how they ended

tenures.tagged = read_sheet(sheeturl, sheet = 'nba-tenures')

tenures.tagged

tenures.joined = tenures.study %>% 
  left_join(
    tenures.tagged %>% 
      select(tenure.slug, tenure.ending, interim.promoted, first.hc.job)
  )

tenures.joined

tenures.joined %>% write_csv(glue('{outfolder}processed/tenures.csv'), na = '')
tenures.joined %>% write_sheet(ss = sheeturl, sheet = 'nba-tenures')
