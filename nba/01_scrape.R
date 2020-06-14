library(glue)
library(rvest)
library(tidyverse)

outfolder = 'nba/scraped/'

path.to.url = function(path) {
  return(glue('https://www.basketball-reference.com{path}'))
}

url.to.path = function(url) {
  return(str_replace(url, 'https://www.basketball-reference.com/', ''))  
}

get.or.read.html = function(path) {
  outname = path %>% 
    str_replace('^/', '') %>% 
    str_replace('/$', '') %>% 
    str_replace_all('/', '_')
  outpath = glue('{outfolder}{outname}.html')
  if(file.exists(outpath)) {
    return(read_html(outpath))
  }
  h = read_html(path.to.url(path))
  write_html(h, outpath)
  return(h)
}

team.index.scrape = tibble(url = '/teams/') %>% 
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

team.index.scrape

teams = team.index.scrape %>% 
  select(team.name, team.url) %>% 
  unnest(c(team.name, team.url))

teams

teams %>% 
  mutate(team.html = map(team.url, get.or.read.html))
