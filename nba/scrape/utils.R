outfolder = 'nba/scrape/'

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
  outpath = glue('{outfolder}web/{outname}.html')
  if(file.exists(outpath)) {
    return(read_html(outpath))
  }
  h = read_html(path.to.url(path))
  write_html(h, outpath)
  return(h)
}