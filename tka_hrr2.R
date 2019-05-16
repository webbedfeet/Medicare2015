#' ---
#' output: html_document
#' ---
#'
#' # 2.  White specific analysis
#+ setup, include = F
knitr::opts_chunk$set(echo = F)

#' ## A.  Use white specific Model 1 results.  Display range of SMRs.  Create map.
library(tidyverse)
library(sf)
library(ggpubr)
library(fs)
library(here)
theme_niams <- theme_bw() + theme(axis.title = element_text(size=14),
                                  axis.text = element_text(size = 12))

smr_white <- rio::import('data/raw/PROJ4_SMR_WHITE.csv', check.names=T)

smr_white %>%
  ggplot(aes(x = smr1)) +
  geom_density()+
  geom_rug() +
  labs(x = 'Model 1 SMR', y = '') +
  theme_niams

smr_white <- smr_white %>%
  mutate(status1 = case_when(
    smr1 > 1 + 2.58*sqrt(1/exp1) ~ 'high',
    smr1 < 1 - 2.58*sqrt(1/exp1) ~ 'low',
    TRUE ~ 'normal'
  )) %>%
  mutate(status3 = case_when(
    smr3 > 1 + 2.58*sqrt(1/exp3)~ 'high',
    smr3 < 1 - 2.58 * sqrt(1/exp3) ~ 'low',
    TRUE ~ 'normal'
  ))

hrr_info <- st_read('~/Downloads/hrr_bdry-1/HRR_Bdry.SHP')

# map_data <- smr_white %>% left_join(hrr_info, by = c('hrr' = 'HRRNUM'))

# ggplot(map_data) + geom_sf(aes(fill = status1)) + theme_bw() + labs(fill = 'SMR status')
#
# ggplot(map_data %>% arrange(exp1), aes(exp1, smr1))+geom_point() +
#   geom_line(aes(x = exp1, y = 1 + 6*sqrt(1/exp1)), color = 'red', size=2) +
#   geom_line(aes(x = exp1, y = 1 - 6*sqrt(1/exp1)), color = 'red', size=2)
#


#' ### Then use Model 3 results, display range of SMRs, and create map.
#'

# ggplot(map_data, aes(x = smr3))+geom_density() + geom_rug() +
#   labs(x = 'Model 3 SMR', y = '') +
#   theme_niams
#
# ggplot(map_data %>% arrange(exp3), aes(exp3, smr3))+geom_point() +
#   geom_line(aes(x = exp3, y = 1 + 6*sqrt(1/exp3)), color = 'red', size=2) +
#   geom_line(aes(x = exp3, y = 1 - 6*sqrt(1/exp3)), color = 'red', size=2)
#
# ggplot(map_data) + geom_sf(aes(fill = status3)) + theme_bw() + labs(fill = 'SMR status')

 #' ### Calculate the reduction in variation achieved by adjustment from model 1 to model 3.
 #+ echo = F
map_data %>% select(smr1, smr3) %>%
  gather(variable, value) %>%
  mutate(variable = str_replace(variable, 'smr', 'Model ')) %>%
  ggplot(aes(log10(value), color = variable)) +
    geom_density() +
    geom_vline(xintercept = 0) +
    scale_x_continuous('SMR')+
    labs(color = 'Model') +
    theme_niams

kurt <- map_data %>% summarize_at(vars(smr1,smr3), ~e1071::kurtosis(log10(.)))
meds <- map_data %>% summarize_at(vars(smr1,smr3), ~median(log10(.)))

#' The excess kurtosis, which is a measure of how "tall" and concentrated the distribution is in the middle compared to the standard normal distribution,
#' is `r round(kurt$smr1, 3)` for the Model 1-based SMRs and `r round(kurt$smr3, 3)` for the Model 3-based SMRS (based on the distribution of the logarithm of the SMRs), with the medians being `r round(meds$smr1, 2)` and `r round(meds$smr3, 2)`, respectively. This indicates that the Model 3 based SMRs are more concentrated around 1 than the Model 1 based SMRs.
#'
#' ### Comment on most important variables in Model 3 (present table of betas in supplement).

params <- rio::import('data/raw/MOD3_PARAMS.csv')
params$year <- rep(2011:2015, rep(45,5))

params2013 <- params %>% filter(year==2013)
params2013 %>% filter(!is.na(StdErr)) %>%
  dplyr::select(Parameter:Estimate) %>%
  dplyr::filter(Parameter != 'Intercept') %>%
  dplyr::arrange(desc(abs(Estimate))) %>%
  dplyr::mutate(Estimate = ifelse(Level=='0', -Estimate, Estimate)) %>%
  dplyr::mutate(Parameter = str_replace(Parameter, ' 0$','')) %>%
  dplyr::filter(abs(Estimate) > 0.175) %>%
  dplyr::mutate(Parameter = ifelse(str_detect(Parameter, 'agecat'), paste0(Parameter, ' vs 5'), Parameter)) %>%
  dplyr::mutate(OR = exp(Estimate)) %>%
  dplyr::select(-Level) %>%
  knitr::kable(digits=2)

#' The important predictors for knee surgery are smoking, physical jobs, younger age, not being poor, not having dementia, being obese and not having many comorbidities. Interestingly depression is a positive predictor for surgery, as are being male and suffering from AFIB.
#'
#' ## B.  Show correlations of SMR with HRR-level variables:  percent rural, Medicare Advantage, number of outpatient visits, Ortho per 1000.  Some substitution of inpt for outpt care; some pos association with number of surgeons.
#'
library(Hmisc)
label(smr_white$rural_perc) <- 'Percent rural'
label(smr_white$mcare_adv_wtperc) <- 'Percentage with Medicare Advantage'
label(smr_white$ortho_per_100000) <- 'Number of orthopedists per 10000'
label(smr_white$mean_koa_visits) <- 'Average number of knee visits per person'
label(smr_white$frac_koa) <- 'Fraction of people with at least one knee visit'

plot_fn <- function(variable){
  vrbl <- enquo(variable)
  ggplot(smr_white, aes(x = !!vrbl, y = smr3))+
    geom_point()+
    geom_smooth(se = F) +
    geom_hline(yintercept = 1, linetype = 2) +
    labs(x = label(smr_white[[ensym(vrbl)]]),y = 'SMR') +
    theme_niams
}

plot_fn(mean_op)
plot_fn(mcare_adv_wtperc)
plot_fn(ortho_per_100000)
plot_fn(mean_koa_visits)
plot_fn(frac_koa) + scale_x_continuous(labels=scales::percent_format())


#' ## C.  Are the high (low) SMRs due to across the board increases in surgery (ie lower threshold) or expanded use in selected patient subgroups (either very sick or very healthy)?
#' >   Divide population into quintile of expected probability.  Among each quintile, compute SMR by HRR.  If the SMR remains the same across quintiles, would favor the notion that there are across the board increases in surgery.  If the SMR is very high in the lowest prob quintile and shrinks/converges in the highest prob quintile, then points to selected patient subgroups.
#'
#' We divided the population into quartiles rather than quintiles.
#'
#' See attached files for results
#+ include = F
quarts <- rio::import('data/raw/PROJ4_MOD3_HRR_QUARTILES.csv') %>% as_tibble() %>%
  mutate(smr = tka/exp3) %>% select(hrr,tka, exp3, smr, quartile)

blah <- quarts %>% left_join(select(smr_white, hrr, smr3), by = 'hrr') %>%
  filter(!is.na(smr3)) %>%
  mutate(smr_group = cut(smr3, quantile(smr3, c(0, 0.05, 0.4, 0.6, 0.95, 1)), include.lowest=T))
levels(blah$smr_group) <- paste(c('Very low','Low','Middle','High','Very high'), levels(blah$smr_group), sep = ': ')

ggplot(blah, aes(x = quartile,y = smr, color = smr_group))+geom_point() + geom_line(aes(group = hrr))

ggplot(blah, aes(x = quartile, y = smr, color = smr_group)) + geom_point() + geom_line(aes(group=hrr), alpha = 0.3) +
  facet_wrap(~smr_group)

blah2 <- blah %>% mutate(smr_group = cut(smr3, quantile(smr3), include.lowest = T)) %>%
  select(quartile, hrr, smr, smr_group) %>% bind_rows(
    smr_white %>% select(hrr, smr3) %>% mutate(smr_group='Overall') %>%
      rename(smr = smr3)
  )

levels(blah2$smr_group) <- paste(c(paste('Quartile', 1:4),''), levels(blah2$smr_group), sep = ': ') %>%
  str_replace('^: ','')
ggplot(blah2, aes(x = quartile, y = smr, color = smr_group))+geom_point()+
  geom_line(aes(group = hrr), alpha = 0.5) +
  geom_hline(yintercept = 1, linetype=2)+
  # facet_wrap(~smr_group) +
  labs(x = 'Quartile groups of patients based on\nexpected probability of knee surgery',
       y = 'Probability quartile specific SMR',
       color = 'HRR-specific SMR quartiles') +
  theme_bw()+
  theme(legend.position = 'bottom',
        panel.grid.major.x = element_blank()) +
  guides(color = guide_legend(nrow = 2))

plt <- ggplot(quarts %>% filter( tka >= 10), aes(x = quartile, y =smr, fill = quartile)) +
  geom_bar(stat='identity') + scale_y_log10(breaks = seq(0.2, 2.4, by = 0.4)) +
  ggforce::facet_wrap_paginate(~ hrr, nrow = 3, ncol = 3)
n <- ggforce::n_pages(plt)

pdf('quartile_analysis.pdf')
for(i in 1:n){
  print(ggplot(quarts %>% filter( tka >= 10), aes(x = quartile, y =smr, fill = quartile)) +
    geom_bar(stat='identity') + scale_y_log10(breaks = seq(0.2, 2.4, by = 0.4)) +
    ggforce::facet_wrap_paginate(~ hrr, nrow = 3, ncol = 3, page = i))
}
dev.off()

quarts %>% filter(tka >= 10) %>% select(hrr, smr, quartile) %>% spread(quartile, smr) %>% openxlsx::write.xlsx(file='quartile_analysis.xlsx')
#'
#'
#' Compute absolute rates of surgery in each HRR for subsets of sick and healthy.  In each HRR, isolate patients with dementia, CHF, PVD, ulcers, and healthy (65-69 + no comorbidity).  Also create a poor-risk factor group that combines those with dementia, CHF, PVD, and ulcers.  Compute rate of TKA per 1000 patients with dementia, CHF, etc.  Correlate rate with SMR.  By comparing absolute rates, this will tell how much of the “excess” in the high group is due to expanded TKA use in the healthy versus poor prognosis groups.

# TODO: Need to extract the data for the healthy group, which I missed

comorb_data <- rio::import('data/raw/PROJ4_TKA_CONDITIONS.csv')
comorb_data <- comorb_data %>% mutate(condition = factor(condition,
                              labels = c('Congestive Heart Failure',
                                         'Dementia',
                                         'Healthy',
                                         'Poor risk',
                                         'Peripheral Vascular Disease',
                                         'Ulcers')))

corr_data <- comorb_data %>% group_by(condition) %>%
  dplyr::summarize(corr = cor(prop, smr3))
ggplot(comorb_data, aes(prop, smr3)) +
  geom_point(alpha = 0.5) +
  geom_smooth(se = F, color = 'red') +
  geom_hline(yintercept = 1, linetype = 2)+
  geom_text(data = corr_data,
           aes(x = 12, y = 2, label = glue::glue('r = {round(corr,2)}'))) +
  labs(x = 'Incidence rate of knee replacement
       (per 1000 person-years)', y = 'SMR') +
  facet_wrap(~condition) +
  theme_bw() +
  theme(axis.title = element_text(size = 14),
        axis.text = element_text(size = 12),
        text = element_text(size = 12),
        )



# Surgeon volume analysis -------------------------------------------------

#' ## D.  Is the SMR driven by a few outliers or is it a community standard?
#'   Compute volume per surgeon per HRR.
#' Within HRRs, look at the absolute rates per surgeon.  If we think of the HRR-specific rates as the summary of a set of stratum-specific rates, the surgeon-specific rate is the stratum.  For the high SMRs, how much variability is there in rates in the healthy subgroup and poor-risk factor subgroup among different surgeons?  Is the range of variability comparable to that seen in HRRs with SMRs near 1.0?
#'

phys <- rio::import(here('data','raw','PROJ4_PHYS_RATES2.csv'))
hrr_rates <- rio::import(here('data','raw','PROJ4_OVERALL_SMR.csv')) %>% select(hrr, SMR3)
hrr_info <- st_read('~/Downloads/hrr_bdry-1/HRR_Bdry.SHP') %>%
  as_tibble() %>%
  select(HRRNUM, HRRCITY)

hrr_info %>% separate(HRRCITY, c("State","City"), sep = '-', extra = 'merge') %>%
  mutate(City = str_to_title(str_trim(City))) %>%
  select(-State, everything())

phys <- phys %>%
  left_join(hrr_rates, by = c('hrrnum' = 'hrr')) %>% as_tibble()
phys <- mutate(phys, smr_group = cut(SMR3, quantile(hrr_rates$SMR3, c(0,0.05, 0.4, 0.6, 0.95,1)), include.lowest = T))

smr_levels <- c('Lowest 5%','Low','Middle','High','Highest 5%')
levels(phys$smr_group) <- smr_levels

phys %>%
  filter(smr_group %in% levels(smr_group)[c(1,3,5)]) %>%
  mutate(smr_group1 = case_when(
    smr_group=='[0.634,0.786]' ~ 'Low',
    smr_group=='(0.966,1.05]' ~ 'Around 1',
    TRUE ~ 'High'
  )) %>%
  mutate(smr_group1=factor(smr_group1, levels = c('Low','Around 1','High'))) %>%
ggplot(aes(rate_overall, fill = smr_group1)) +
  geom_density(alpha = 0.4) +
  scale_x_log10() +
  facet_wrap(~ smr_group1, ncol=1) +
  theme_niams+
  labs(x = 'Overall surgeon-specific rate', fill = 'SMR group')

bl <- phys %>% filter(smr_group == levels(smr_group)[c(3,5)]) %>%
  gather(variable, value, rate_healthy, rate_poorrisk) %>%
  mutate(variable = ifelse(variable== 'rate_healthy', 'Healthy','Poor risk'),
         smr_group = ifelse(smr_group=='(0.966,1.05]', 'Around 1','High'))

  ggplot(bl, aes(value, color = smr_group))+
  geom_density() +
  facet_grid(.~variable) +
  labs(x = 'Surgeon-specific rates ', fill = '') +
  theme_niams +
  scale_x_log10()

  ggplot(bl, aes(value, color = smr_group)) + stat_ecdf() +
    facet_grid(.~variable) +
    scale_x_log10()
    coord_cartesian(xlim = c(0, 20000))
