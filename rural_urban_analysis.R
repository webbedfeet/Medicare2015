#' ---
#' title: Urban-Rural analysis
#' author: Abhijit
#' output: word_document
#' ---
#'
#+ include = F
library(tidyverse)
#'
#+ echo = F, message = F
d <- read_csv('data/raw/PROJ4_SMR_RURAL_URBAN.csv')

d1 <- d %>% mutate(city = ifelse(city == 0, 'Rural','Urban')) %>%
  select(hrrnum, city, smr3, location) %>%
  spread(city, smr3) %>%
  mutate(Difference = Rural - Urban) %>%
  arrange(Urban)


d2 <- d %>% select(hrrnum, overall_smr) %>% distinct()
d3 <- d1 %>% left_join(d2) %>%
  arrange(overall_smr) %>%
  rename('Overall OER' = 'overall_smr') %>%
  mutate(location = str_replace(location, '_', ' ')) %>%
  mutate(location = str_to_title(location)) %>%
  mutate(location = ifelse(location=='Slc', 'Salt Lake City', location))

d4 <- d %>% filter(city==1) %>% select(hrrnum, Percent)
d3 <- d3 %>% left_join(d4) %>% rename('Percent White'= 'Percent')
knitr::kable(d3, format='pandoc', digits = 2)
