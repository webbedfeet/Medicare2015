## ----setup, include = F----------------------------------------------------
library(tidyverse)
library(rio)
library(sf)
library(fs)
library(here)

knitr::opts_chunk$set(echo = FALSE, warning = F, message = F, cache = F,
                      fig.path = 'Result_Graphs/', dev = c('png','pdf'),
                      dpi = 300,
                      # fig.align = 'center',
                      fig.height = 5, fig.width = 7)

theme_set(theme_bw() + theme(
  text = element_text(size = 10),
  axis.title = element_text(size = 10, face = 'bold')))

doc.type <- knitr::opts_knit$get('rmarkdown.pandoc.to')

drop_dir <- path('P:/','Work','Ward','Studies','Medicare2015','data')
print(doc.type)

map_scale_fill <- function(...){
  scale_fill_gradient2(
  name = 'OER',
  trans = 'log2',
  labels = function(x){round(x,2)},
  high = '#ff0000',
  low = '#003300',
  mid = '#ffff00',
  midpoint = 0,
  ...)
}
map_scale_color <- function(...){
  scale_color_gradient2(
  name = 'OER',
  trans = 'log2',
  labels = function(x){round(x,2)},
 high = '#ff0000',
  low = '#003300',
  mid = '#ffff00',
  midpoint = 0,
  ...)
}



## ----Figure-1, echo = F, include=T-----------------------------------------

smr_white <- import(path(drop_dir, 'raw/PROJ4_SMR_WHITE.csv') )
hrr_info <- st_read(path(drop_dir, 'HRR_Bdry.SHP'), quiet = TRUE)
plot_dat <- smr_white %>% left_join(hrr_info, by = c('hrr' = 'HRRNUM'))# %>%
  # mutate(SMR1 = ifelse(SMR1 <= 0.67, 0.67, SMR1)) %>%
  # mutate(SMR1 = ifelse(SMR1 >= 1.5, 1.5, SMR1))


plt11 <-
  ggplot(plot_dat) +
  geom_sf(aes(geometry = geometry, fill = smr3),  color = NA) +
  map_scale_fill(breaks = c(min(plot_dat$smr3),  1, max(plot_dat$smr3)))+
  # scale_fill_gradient2(
  #   name = 'OER',
  #   trans = 'log2',
  #   breaks = c(min(plot_dat$SMR3), 0.75, 1, 1.33, max(plot_dat$SMR3)),
  #   labels = function(x){round(x,2)},
  #   # limits = c(0.67, 1.5),
  #    high = 'red', mid = '#ffffbf', low = 'green', midpoint = 0) +
  coord_sf(label_graticule = 'SW', crs = 4286)

plt12 <- ggplotGrob(
  plt11 + coord_sf(xlim = c(-76,-71.5), ylim = c(39.5,42), crs=4286) +
  theme(legend.position = 'none',
        axis.text = element_blank() , axis.ticks = element_blank())
)

plt13 <- plt11 +

  annotation_custom(grob = plt12, xmin =-78.8, xmax = -63.8, ymin = 22.5,
                    ymax = 32.5) +
  annotate('rect', xmax = -71.5, xmin = -76, ymax = 42, ymin = 39.5,
           alpha = 0.3)


pdffile <- fs::path_rel(here::here('docs','Result_Graphs','Figure-1-1.pdf'))
ggsave(pdffile,
       plot = plt13)
x <- magick::image_read_pdf(pdffile)
magick::image_write(x, stringr::str_replace(pdffile, 'pdf','png'))
knitr::include_graphics(stringr::str_replace(pdffile, 'pdf','png'))



## ----Figure-2--------------------------------------------------------------
library(Hmisc)
library(patchwork)
smr_white <- import(path(drop_dir, 'raw/PROJ4_SMR_WHITE.csv'))
label(smr_white$rural_perc) <- 'Percent rural\n'
label(smr_white$mean_op) <- 'Average number of \noutpatient visits per year'
label(smr_white$mcare_adv_wtperc) <- 'Percentage with \nMedicare Managed Care'
label(smr_white$ortho_per_100000) <- 'Number of TKA surgeons\nper 100,000 beneficiaries'
label(smr_white$mean_koa_visits) <- 'Mean annual knee visits\n per person'
label(smr_white$frac_koa) <- 'Fraction of people with \nat least one knee visit a year'
plot_fn <- function(variable){
  vrbl <- enquo(variable)
  ggplot(smr_white, aes(x = !!vrbl, y = smr3))+
    geom_point()+
    geom_smooth(se = F, color = 'red') +
    geom_hline(yintercept = 1, linetype = 2) +
    labs(x = label(smr_white[[ensym(vrbl)]]),
         y = 'Observed/Expected ratio (OER)') +
    theme_bw() +
    theme(axis.text = element_text(size = 12),
          axis.title = element_text(size = 12, face = 'bold'),
          axis.title.y = element_blank())
}

p0 <- plot_fn(rural_perc)
p1 <- plot_fn(mean_op)
p2 <- plot_fn(mcare_adv_wtperc)
p3 <- plot_fn(ortho_per_100000)
p4 <- plot_fn(mean_koa_visits)
p5 <- plot_fn(frac_koa) + scale_x_continuous(labels=scales::percent_format())

plt <- ggpubr::ggarrange(p0, p4, p1, p2, p3, ncol = 3, nrow = 2)
# plt <- ggpubr::ggarrange(p4,p0,p2,p3, ncol = 2, nrow = 2)
(final_plt <- ggpubr::annotate_figure(plt,
    left = ggpubr::text_grob('Observed/Expected ratio (OER)',
                             rot = 90, size = 12, face = 'bold'))
)



## ----Figure-3--------------------------------------------------------------
quarts <- rio::import(path(drop_dir, 'raw/PROJ4_MOD3_HRR_QUARTILES.csv')) %>% as_tibble() %>%
  mutate(smr = tka/exp3) %>% select(hrr, smr, quartile)
smr_white <- rio::import(path(drop_dir,'raw/PROJ4_SMR_WHITE.csv')) %>%
  select(hrr, smr3) %>%
  mutate(quartile = 'Overall') %>%
  mutate(smr_group = cut(smr3, quantile(smr3, c(0,0.05,0.4, 0.6, 0.95, 1)),
                         include.lowest = T))
levels(smr_white$smr_group) <- str_split(levels(smr_white$smr_group), ',') %>%
  map(~str_replace(., '\\(|\\)|\\[|\\]','')) %>%
  map(as.numeric) %>%
  map(~paste(round(., 2), collapse = '-')) %>%
  unlist()
levels(smr_white$smr_group) <- paste(c('Very low','Low','Middle','High',
                                       'Very high'),
                                     levels(smr_white$smr_group),
                                     sep = ': ')

blah <- quarts %>% bind_rows(smr_white %>%
                               select(-smr_group) %>%
                               rename(smr = smr3)) %>%
  filter(!is.na(smr)) # Adding the overall SMR values to the dataset
blah <- blah %>%
  left_join(smr_white %>%
              select(hrr, smr_group)) %>%  # Adding the SMR groups to the dataset
  mutate(quartile = as_factor(quartile)) %>%
  mutate(quartile = fct_recode(quartile,
                               "Low" = "q1",
                               "Low-middle" = "q2",
                               "High-middle" = "q3",
                               "High" = 'q4')) %>%
  mutate(quartile = fct_relevel(quartile, 'Low','Low-middle', 'High-middle',
                                'High','Overall'))
blah2 <- blah %>% filter(quartile=='Overall') %>%
  select(hrr, smr) %>%
  rename(smr_overall=smr)
blah <- blah %>% left_join(blah2)
plt <- ggplot(blah, aes(x = quartile,y = smr, color = smr_overall)) +
  geom_line(aes(group = hrr), alpha = 0.2) +
  geom_point() +
  scale_y_log10()+
  map_scale_color(breaks = c(min(blah$smr_overall),  1, max(blah$smr_overall)))+
  theme(legend.position = c(.8,0.2),
        legend.text = element_text(size = 10),
        axis.text = element_text(face='bold')) +
  labs(x = 'Quartile groups of patients based on\n expected probability of knee surgery',
       y = 'Probability quartile specific OER',
       color = 'HRR-specific overall OER quartiles')

plt


## ----Figure-4--------------------------------------------------------------
conditions <- import(path(drop_dir, 'raw/PROJ4_TKA_CONDITIONS_june2.csv'))
depr <- import(path(drop_dir, 'raw/PROJ4_TKA_DEPRESSION.csv')) %>%
  mutate(condition='depression') %>% mutate(prop = prop*1000)
conditions <- bind_rows(conditions,depr)
conditions <- conditions %>%
  filter(condition %in% c('dementia','ulcers','pvd','chf','depression','diabetes','healthy')) %>%
  mutate(condition = as.factor(condition)) %>%
  mutate(condition = fct_relevel(condition, 'dementia','ulcers','pvd','chf','depression','diabetes','healthy')) %>%
  mutate(condition = fct_recode(condition,
                                'Dementia' = 'dementia',
                                'Peripheral vascular disease' = 'pvd',
                                'Skin ulcers' = 'ulcers',
                                'Congestive heart failure' = 'chf',
                                'Depression' = 'depression',
                                'Diabetes Mellitus' = 'diabetes',
                                'No comorbidity' = 'healthy',
                                # 'Depression' = 'depression',
                                # 'Congestive\nHeart Failure' = 'chf'
                                ))
ggplot(conditions, aes(x = prop, y = smr3)) +
  geom_point() +
  geom_smooth(se = F, color = 'red') +
  geom_hline(yintercept = 1, linetype = 2) +
  facet_wrap(~ condition, nrow=3, ncol = 3, scales = 'free_x') +
  scale_x_continuous(breaks = seq(10, 60, by = 10))+
  labs( x = 'Incidence of TKA per 1000 among those with condition',
        y = 'Observed/Expected Ratio (OER)') +
  theme(text = element_text(size = 14),
        strip.text = element_text(size = 10))



## ----Figure-4a, echo = F, eval = F-----------------------------------------
## conditions <- import(path(drop_dir, 'raw/PROJ4_TKA_CONDITIONS.csv'))
## depr <- import(path(drop_dir, 'raw/PROJ4_TKA_DEPRESSION.csv')) %>%
##   mutate(condition='depression') %>% mutate(prop = prop * 1000)
## conditions <- bind_rows(conditions,depr)
## conditions <- conditions %>%
##   filter(condition != 'poorrisk') %>%
##   mutate(condition = as.factor(condition)) %>%
##   mutate(condition = fct_relevel(condition, 'dementia','pvd','ulcers','depression','chf','healthy')) %>%
##   mutate(condition = fct_recode(condition,
##                                 'Dementia' = 'dementia',
##                                 'Peripheral\n vascular disease' = 'pvd',
##                                 'Skin ulcers' = 'ulcers',
##                                 'Healthy' = 'healthy',
##                                 'Depression' = 'depression',
##                                 'Congestive\nHeart Failure' = 'chf'))
## ortho_prevalence <- import(path(drop_dir, 'raw/PROJ4_SMR_WHITE.csv')) %>%
##   select(hrr, ortho_per_100000)
## plot_dat <- left_join(conditions, ortho_prevalence)
## ggplot(plot_dat, aes(x = prop, y = ortho_per_100000)) + geom_point() +
##   geom_point() +
##   geom_smooth(se = F, color = 'red') +
##   facet_wrap(~ condition, , nrow = 2) +
##   labs( x = 'Prevalence per 1000 subjects',
##         y = 'Number of orthopedists per 100,000 beneficiaries') +
##   theme_bw()


## ----Figure-5--------------------------------------------------------------
smr_black <- read_csv(path(drop_dir,'raw/Black_SMR.csv')) %>%
  filter(n >= 15000)
smr_white <- read_csv(path(drop_dir,'raw/PROJ4_SMR_WHITE.csv'))

smrs <- bind_rows(smr_white, smr_black) %>%
  mutate(race = ifelse(race == 1, 'White','Black')) %>%
  mutate(race = as_factor(race)) %>%
  # mutate(race = fct_relevel('White')) %>%
  select(hrr, race, smr3, ortho_per_100000)

smrs %>% select(-ortho_per_100000) %>%
  spread(race, smr3) %>%
  ggplot(aes(White, Black)) +
  geom_point() +
  # geom_smooth(se=F, color = 'red', method = 'lm') +
  geom_abline(linetype = 2) +
  coord_equal(xlim = c(0.6, 1.3), ylim = c(0.6, 1.3)) +
  theme_bw() +
  theme(text = element_text(size = 12),
        axis.title = element_text(face = 'bold'))


## ----Figure-6, eval = F, echo = F------------------------------------------
## smr_black <- read_csv(path(drop_dir,'raw/Black_SMR.csv')) %>%
##   filter(n >= 15000)
## ggplot(smr_black, aes(x = ortho_per_100000, y = smr3)) +
##   geom_point() + geom_smooth(color = 'red', se = F) +
##   geom_hline(yintercept = 1, linetype = 2) +
##   labs(x = 'Number of TKA surgeons \nper 100,000 beneficiaries',
##        y = 'Observed/Expected ratio (OER)')


## ----Figure-7, echo = TRUE-------------------------------------------------
overall_smr <-
  rio::import(path(drop_dir,'raw','PROJ4_OVERALL_SMR.csv')) %>%
  select(hrr, SMR3)
dat_n <- rio::import(path(drop_dir, 'N_2013.csv'))
yrs <- 2011:2015
dat <- list()
for(yr in yrs){
  dat[[as.character(yr)]] <-
    rio::import(path(drop_dir,                                               paste0('PROJ4_HRR_MODSUMMARY_',yr,'.csv'))) %>%
    group_by(hrr) %>%
    dplyr::summarize(obs= sum(total_knee),
              expect = sum(expected_knee3)) %>%
    mutate(oer = obs/expect) %>%
    ungroup() %>%
    select(hrr, oer) %>%
    left_join(dat_n)
}
Dat <- bind_rows(dat, .id = 'year') %>%
  group_by(hrr) %>%
  dplyr::summarize(N = unique(N),
            maxoer = max(oer),
            minoer = min(oer),
            rangeoer = maxoer - minoer) %>%
  ungroup() %>%
  left_join(overall_smr)

library(scales)
p1 <- ggplot(Dat %>% filter(N <= 100000), aes(x = N, y = SMR3, ymin = minoer, ymax = maxoer)) +
  geom_pointrange(size = 0.5) +
  scale_y_log10(breaks = c(0.7, 1, 2), limits = c(0.5, 2.05)) + scale_x_continuous(labels = comma) +
  labs(x = 'Population in Medicare',
       y = 'Observed/Expected Ratio')
p2 <- ggplot(Dat %>% filter(N > 100000), aes(x = N, y = SMR3, ymin = minoer, ymax = maxoer)) +
  geom_pointrange(size = 0.5) +
  scale_y_log10(breaks = c(0.7, 1, 2), limits = c(0.5, 2.05)) + scale_x_continuous(labels = comma) +
  labs(x = 'Population in Medicare',
       y = 'Observed/Expected Ratio')
cowplot::plot_grid(p1, p2, nrow = 2, ncol = 1)



## ----post, include=F, message=F, results = 'hide'--------------------------
abhiR::pdf2tiff(here::here('docs','Result_Graphs'))

