
# setup -------------------------------------------------------------------

library(tidyverse)
library(rio)
library(sf)
library(fs)

# Ingest data -------------------------------------------------------------

data_dir <- path('P:/','Work','Ward','Studies','Medicare2015','data')
dir_exists(data_dir)

hrr_info <- st_read(path(data_dir,'HRR_Bdry.SHP'), quiet=TRUE)
smr_overall <- read_csv(path(data_dir, 'raw/PROJ4_OVERALL_SMR.csv')) %>%
  as.data.frame()
plot_dat <- smr_overall %>% dplyr::right_join(hrr_info, by = c('hrr' = 'HRRNUM'))# %>%
# mutate(SMR1 = ifelse(SMR1 <= 0.67, 0.67, SMR1)) %>%
# mutate(SMR1 = ifelse(SMR1 >= 1.5, 1.5, SMR1))

plt1 <-
  ggplot(plot_dat, aes(geometry=geometry)) +
  geom_sf(aes(fill = SMR1)) +
  scale_fill_gradient2(
    name = 'OER',
    trans = 'log',
    breaks = c(0.75, 1, 1.33 ),
    # limits = c(0.67, 1.5),
    low = 'orange', mid = '#ffffbf', high = 'green', midpoint = 0) +
  coord_sf(label_graticule = 'SW', crs = 4286)

# plt2 <- plt1 + coord_sf(xlim = c(-80, -70), ylim = c(40,45)) +
#   theme(legend.position = 'none',
#         axis.text = element_blank(),
#         axis.ticks = element_blank())

# plt1
ggsave('graphs/map_model1.pdf', plot = plt1)


# Revised map using OER quintiles -----------------------------------------


