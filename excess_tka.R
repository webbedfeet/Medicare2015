# Analysis of excess risk of TKA within different comorbid conditions


# Setup -------------------------------------------------------------------

library(tidyverse)
library(rio)


# Data ingestion ----------------------------------------------------------

smr_white <- import('data/raw/PROJ4_SMR_WHITE.csv')
conditions_white <- import('data/raw/PROJ4_TKA_CONDITIONS.csv') %>%
  bind_rows(import('data/raw/PROJ4_TKA_DEPRESSION.csv') %>%
              mutate(condition='depression')) %>%
  filter(condition != 'poorrisk')


# Identifying high and normal regions -------------------------------------

hist(smr_white$smr3)
smr_white %>% top_n(10, smr3)  %>% summarize(sum(py))
smr_white %>% filter(smr3 > 0.99, smr3 < 1.01) %>% summarize(sum(py))
## The top 10 HRRs have 2,554,891 person-years, and the middle with SMRs ranging
## from 0.99 to 1.01 have 3,055,199 person years, so of comparable size. If we took
## this to 0.95 to 1.05, we'd have
smr_white %>% filter(smr3 > 0.95, smr3 < 1.05) %>% summarize(sum(py)) # 35,992,494 py

## Grab hrrs
high_hrr <- smr_white %>% top_n(10, smr3) %>% pull(hrr)
mid_hrr <- smr_white %>% filter(smr3 > 0.99, smr3 < 1.01) %>% pull(hrr)



excess_tka <- function(condition_name) {
  dat <- conditions_white %>%
    filter(condition==condition_name) %>%
    filter(hrr %in% c(high_hrr, mid_hrr)) %>%
    mutate(Group = ifelse(hrr %in% high_hrr, 'high','mid'))

  dat %>% group_by(Group) %>%
    summarize(py = sum(denom), rate = sum(num)/sum(denom)) %>%
    mutate(rate_diff = -diff(rate)) %>%
    filter(Group=='high') %>%
    mutate(excess_tka = py * rate_diff,
           excess_tka_per_yr = excess_tka / 5)
}

conds <- sort(unique(conditions_white$condition))
names(conds) <- c('CHF','Dementia','Depression','Healthy','PVD','Leg ulcers')

map_dfr(as.list(conds), excess_tka, .id = 'Condition') %>%
  select(-Group, -rate)
