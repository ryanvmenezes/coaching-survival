library(glue)
library(tidyverse)

source('nba/utils.R')

games = read_csv(glue('{outfolder}raw/games-by-tenure.csv'))

games

coaches = read_csv(glue('{outfolder}processed/coaches.csv'))

coaches

tenures = read_csv(glue('{outfolder}processed/tenures.csv'))

tenures

tenures %>% count(tenure.ending)

coaches.tenures.coded = tenures %>% 
  mutate(tenure.ending = replace_na(tenure.ending, 'active')) %>% 
  filter(tenure.ending != 'interim only') %>% 
  select(tenure.slug, coach.id, tenure.ending, interim.promoted) %>% 
  transmute(
    tenure.slug, coach.id,
    released = case_when(
      tenure.ending %in% c('died', 'resigned', 'retired', 'active') ~ 0,
      TRUE ~ 1
    ),
    interim.promoted = as.numeric(!is.na(interim.promoted))
  ) %>%
  left_join(
    coaches %>% 
      transmute(
        coach.id,
        black = as.numeric(!is.na(black))
      )
  )

coaches.tenures.coded

all.data = games %>% 
  right_join(coaches.tenures.coded) %>% 
  arrange(tenure.slug, game.date) %>% 
  group_by(tenure.slug) %>% 
  mutate(
    final.game = as.numeric(game.date == max(game.date)),
    end.event = case_when(
      final.game == 1 ~ released,
      TRUE ~ 0
    ),
    total.games = row_number(),
    wins = cumsum(win.loss == 'W'),
    win.pct = wins / total.games,
    starting.elo = first(elo),
    tenure.progress = elo - starting.elo,
    recent.progress = elo - lag(elo, 10),
    peak = cummax(elo),
    bottom = cummin(elo),
    peak.to.start = peak - starting.elo,
    bottom.to.start = bottom - starting.elo,
  ) %>% 
  ungroup() %>% 
  left_join(
    games %>% 
      group_by(season.team.id, season) %>% 
      filter(game.date == max(game.date)) %>% 
      arrange(franchise.id, season) %>% 
      group_by(franchise.id) %>% 
      mutate(prev.year.end.rating = lag(elo)) %>% 
      select(franchise.id, season.team.id, season, prev.year.end.rating)
  ) %>% 
  mutate(
    last.year.progress = elo - prev.year.end.rating
  ) %>% 
  ungroup()

all.data

study.by.game = all.data %>% 
  select(
    tenure.slug, end.event, black, interim.promoted,
    total.games, win.pct, starting.elo,
    tenure.progress, last.year.progress, recent.progress, 
    peak, bottom, peak.to.start, bottom.to.start
  )

study.by.game

study.summary = study.by.game %>% 
  group_by(tenure.slug) %>% 
  filter(total.games == max(total.games))

study.summary

study.by.game %>% write_csv(glue('{outfolder}processed/study-data-by-game.csv'))
study.summary %>% write_csv(glue('{outfolder}processed/study-data-summary.csv'))
