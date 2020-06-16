outfolder = 'nba/scrape/'

path.to.url = function(path) {
  return(glue('https://www.basketball-reference.com{path}'))
}

url.to.path = function(url) {
  return(str_replace(url, 'https://www.basketball-reference.com/', ''))  
}

get.or.read.html = function(path, sleep = FALSE, overwrite = FALSE) {
  outname = path %>% 
    str_replace('^/', '') %>% 
    str_replace('/$', '') %>% 
    str_replace_all('.html', '') %>% 
    str_replace_all('/', '--') 
  outpath = glue('{outfolder}web/{outname}.html')
  if(file.exists(outpath) & !overwrite) {
    return(read_html(outpath))
  }
  h = read_html(path.to.url(path))
  if (sleep | overwrite) {
    Sys.sleep(1 + runif(1))
  }
  write_html(h, outpath)
  return(h)
}