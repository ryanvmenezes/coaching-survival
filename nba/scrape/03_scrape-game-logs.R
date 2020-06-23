library(glue)
library(rvest)
library(tidyverse)

source('nba/scrape/utils.R')

seasons = read_csv(glue('{outfolder}processed/seasons.csv'))

seasons

game.log.scrape = seasons %>% 
  select(franchise.name, franchise.id, season, season.team.id, season.team.name, season.url) %>% 
  mutate(
    game.log.url = str_replace(season.url, '.html', '_games.html'),
    game.log.html = map(game.log.url, get.or.read.html),
    game.number = map(
      game.log.html,
      ~.x %>% 
        html_node('table#games') %>% 
        html_nodes('th[data-stat="g"][scope="row"]') %>% 
        html_text()
    ),
    game.date = map(
      game.log.html,
      ~.x %>% 
        html_node('table#games') %>% 
        html_nodes('td[data-stat="date_game"]') %>% 
        html_attr('csk')
    ),
    win.loss = map(
      game.log.html,
      ~.x %>% 
        html_node('table#games') %>% 
        html_nodes('td[data-stat="game_result"]') %>% 
        html_text()
    )
  )

game.log.scrape

game.logs = game.log.scrape %>% 
  select(franchise.id, season.team.id, season, game.number, game.date, win.loss) %>% 
  unnest(c(game.number, game.date, win.loss))

game.logs

game.logs %>% write_csv(glue('{outfolder}processed/game-logs.csv'))
