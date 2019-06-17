# Analysis of excess risk of TKA within different comorbid conditions


# Setup -------------------------------------------------------------------

library(tidyverse)
library(rio)


# Data ingestion ----------------------------------------------------------

smr_white <- import('data/raw/PROJ4_SMR_WHITE.csv')
conditions_white <- import('data/raw/PROJ4_TKA_CONDITIONS_june.csv') %>%
  bind_rows(import('data/raw/PROJ4_TKA_DEPRESSION.csv') %>%
              mutate(condition='depression')) %>%
  filter(condition != 'poorrisk')
drop_dir <- file.path(ProjTemplate::find_dropbox(),'NIAMS','Ward','Medicare2015')
hrr_info <- sf::st_read(file.path(drop_dir, 'HRR_Bdry.SHP'), quiet = T) %>%
  separate(HRRCITY, c("state",'city'), sep = '-', extra = 'merge') %>%
  mutate(city = str_trim(city)) %>%
  mutate(city = str_to_title(city)) %>%
  unite('Location',c('city','state'), sep = ', ')


# Identifying high and normal regions -------------------------------------

hist(smr_white$smr3)
smr_white %>% top_n(10, smr3)  %>% dplyr::summarize(sum(py))
smr_white %>% filter(smr3 > 0.99, smr3 < 1.01) %>% summarize(sum(py))
## The top 10 HRRs have 2,554,891 person-years, and the middle with SMRs ranging
## from 0.99 to 1.01 have 3,055,199 person years, so of comparable size. If we took
## this to 0.95 to 1.05, we'd have
smr_white %>% filter(smr3 > 0.95, smr3 < 1.05) %>% summarize(sum(py)) # 35,992,494 py

## Grab hrrs
high_hrr <- smr_white %>% top_n(10, smr3) %>% select(hrr) %>%
  left_join(hrr_info %>% select(HRRNUM, Location), by = c('hrr' = 'HRRNUM'))
high_hrr <- setNames(as.character(high_hrr$hrr), high_hrr$Location)
names(high_hrr) <- hrr_info$Location[hrr_info$HRRNUM %in% unlist(high_hrr)]
mid_hrr <- smr_white %>% filter(smr3 > 0.99, smr3 < 1.01) %>% pull(hrr)



excess_tka <- function(hrr1, condition_name) {
  dat <- conditions_white %>%
    filter(condition==condition_name) %>%
    filter(hrr %in% c(hrr1, mid_hrr)) %>%
    mutate(Group = ifelse(hrr %in% mid_hrr, 'mid', 'high'))

  base_rate <- dat %>% filter(Group=='mid') %>%
    summarize(rate = sum(num)/sum(denom)*1000) %>% pull(rate)

  dat %>% group_by(Group) %>%
    summarize(py = sum(denom), rate = sum(num)/sum(denom)*1000) %>%
    mutate(rate_diff = -diff(rate)) %>%
    filter(Group=='high') %>%
    mutate(excess_tka = py * rate_diff/1000,
           excess_tka_per_yr = excess_tka / 5,
           hrr = hrr1,
           base_rate = base_rate,
           condition = condition_name) %>%
    select(hrr, condition, rate, base_rate, rate_diff, excess_tka_per_yr)
}

conds <- sort(unique(conditions_white$condition))
names(conds) <- c('CHF','Dementia','Depression','Healthy','PVD','Leg ulcers')
conds <- as.list(conds) %>% as_tibble() %>% gather(condition_name, condition)

bl <- expand.grid(high_hrr, conds$condition, stringsAsFactors = F)
results <- map2_dfr(bl[[1]], bl[[2]], excess_tka, .id = 'Location') %>%
  mutate(hrr = as.integer(hrr)) %>%
  left_join(conds) %>% select(-condition) %>%
  left_join(smr_white %>% select(hrr, smr3)) %>%
  mutate(Location = fct_reorder(Location, smr3),
         condition_name = factor(condition_name,
                                 levels = c('Dementia','Leg ulcers','PVD',
                                            'CHF','Depression','Healthy')))
out <- results %>%
  mutate_at(vars(rate:excess_tka_per_yr,smr3), round, 2) %>%
  set_names(c('Location','HRR','Rate','Base rate', 'Rate diff', 'Excess TKA', 'Condition','OER')) %>%
  split(., .$Condition) %>%
  map(~select(., -Condition)) %>%
  map(~arrange(., desc(OER)))
export(out, 'docs/excess_tka.xlsx', colWidths = 'auto')

ggplot(results, aes(x = Location, y = excess_tka_per_yr)) +
  geom_point(size = 2, shape = 21) +
  facet_wrap(~condition_name)+
  labs(x = 'Location', y = 'Excess TKA', fill = 'Condition') +
  coord_flip()

ggplot(results, aes(x = Location, y = rate_diff)) +
  geom_point(size = 2, shape = 21) +
  facet_wrap(~condition_name)+
  labs(x = 'Location', y = 'Excess TKA per 1000', fill = 'Condition') +
  coord_flip()


# Final barplot -----------------------------------------------------------


smr_white <- import('data/raw/PROJ4_SMR_WHITE.csv')
conditions_white <- import('data/raw/PROJ4_TKA_CONDITIONS_june.csv') %>%
  bind_rows(import('data/raw/PROJ4_TKA_DEPRESSION.csv') %>%
              mutate(condition='depression')) %>%
  filter(condition != 'poorrisk')
drop_dir <- file.path(ProjTemplate::find_dropbox(),'NIAMS','Ward','Medicare2015')
hrr_info <- sf::st_read(file.path(drop_dir, 'HRR_Bdry.SHP'), quiet = T) %>%
  separate(HRRCITY, c("state",'city'), sep = '-', extra = 'merge') %>%
  mutate(city = str_trim(city)) %>%
  mutate(city = str_to_title(city)) %>%
  unite('Location',c('city','state'), sep = ', ')

high_hrr_12 <- smr_white %>% filter(smr3 > 1.2) %>% pull(hrr)
high_hrr_12 <- as_tibble(hrr_info) %>% filter(HRRNUM %in% high_hrr_12) %>%
  select(Location, HRRNUM, -geometry)
high_hrr_12 <- setNames(as.list(high_hrr_12$HRRNUM), high_hrr_12$Location)

results_healthy <- map_dfr(high_hrr_12, excess_tka, 'healthy',.id='Location')
results_contra <- map_dfr(high_hrr_12, excess_tka, 'contra', .id = 'Location')
results <- bind_rows(results_healthy, results_contra) %>%
  left_join(smr_white %>% select(hrr, smr3)) %>%
  arrange(desc(smr3)) %>%
  mutate(Location = as.factor(Location)) %>%
  mutate(Location = fct_reorder(Location, smr3))

ggplot(results, aes(x = Location, y = excess_tka_per_yr, fill = condition))+
  geom_bar(stat='identity') + labs(y = 'Excess TKA') + theme_bw() +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.minor.y  = element_blank())+
  coord_flip()
