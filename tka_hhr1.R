#' ---
#' output: word_document
#' always_allow_html: yes
#' ---
#'
#' 1.  Confounding by race
#'     Use Model 1 results.  Display range of SMRs.  For top 10 and bottom 10 SMRs,
#'     list location and % composition by race
#'     Show correlations of SMR with % white/black/Hisp/Asian/Other
#'     This motivates the race-specific analysis.
#+ include = FALSE
library(tidyverse)
library(sf)
library(kableExtra)
overall_smr <- read_csv('data/raw/PROJ4_OVERALL_SMR.csv')
knitr::opts_chunk$set(echo = F, warning = F, message = F)

#' ### Range of SMRs
#'
overall_smr %>%
  ggplot(aes(x = SMR1))+geom_density() + geom_rug() +
  geom_vline(xintercept = 1, linetype = 2)+
  labs(x = "Model 1 SMRs") +
  theme_bw()

#'
#' ### Top and bottom 10 SMRs
#+ echo = FALSE, results='asis'
top10 <- overall_smr %>% arrange(SMR3) %>% slice(1:10, (n()-9):n())
hrr_info <- st_read('~/Downloads/hrr_bdry-1/HRR_Bdry.SHP')
top10 <- top10 %>% left_join(hrr_info, by = c('hrr' = 'HRRNUM'))

races <- read_csv('data/raw/PROJ4_RACE.csv')
races <- races %>% spread(race, Percent) %>%
  set_names(c('HRR','White','Black','Hispanic','Asian','Other'))
top10 <- top10 %>% left_join(races, by = c('hrr'= 'HRR')) %>%
  select(hrr, SMR3, HRRCITY, White:Other) %>%
  separate(HRRCITY, c("State","City"), sep = '- ') %>%
  mutate(City = str_to_title(City)) %>%
  rename(HRR=hrr, SMR = SMR3)
kableExtra::kable(top10,'pandoc', digits = 2, align=c('l','c','c','l','r','r','r','r','r')) %>%
  pack_rows('Bottom 10', 1, 10) %>%
  pack_rows('Top 10', 11,20)

#' ### Show correlations of SMR with % white/black/Hisp/Asian/Other
#+

overall_smr %>% left_join(races, by=c('hrr'='HRR')) %>%
  gather(race, proportion, White:Black) %>%
  mutate(race = as.factor(race)) %>%
  mutate(race = fct_relevel(race, 'White','Black')) %>%
  ggplot(aes(proportion, SMR3))+geom_smooth() + geom_point()+facet_wrap(~race, ncol=1)+
    labs(x = 'Proportion', y = 'SMR')+
  theme_bw()+
  theme(strip.text = element_text(size=14),
        axis.title = element_text(size=14))
