## ----setup, include = F----------------------------------------------------
library(tidyverse)
library(rio)
library(sf)
library(fs)
library(here)
library(RColorBrewer)

knitr::opts_chunk$set(echo = FALSE, warning = F, message = F, cache = F,
                      fig.path = 'Result_Graphs/', dev = c('png','pdf'),
                      dpi = 300,
                      # fig.align = 'center',
                      fig.height = 5, fig.width = 7)

theme_set(theme_bw() + theme(
  text = element_text(size = 10),
  axis.title = element_text(size = 10, face = 'bold')))

doc.type <- knitr::opts_knit$get('rmarkdown.pandoc.to')

# drop_dir <- path(ProjTemplate::find_dropbox(), 'NIAMS','Ward','Medicare2015')
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

plot_dat <- plot_dat %>%
  mutate(smr3_quintile = ntile(smr3, 5))

# Using colors extracted from original color scheme
(plt11 <-
    ggplot(plot_dat) +
    geom_sf(aes(geometry = geometry, fill = factor(smr3_quintile)),  color = NA) +
    scale_fill_manual( values = c('#003300','#7C9307', '#FFFF00',
                                  '#FFA100', '#FF0000'))+
    # scale_fill_gradient2( high = '#ff0000',
    #                       low = '#003300',
    #                       mid = '#ffff00',
    #                       midpoint=3)+
    coord_sf(label_graticule = 'SW', crs = 4286)+
    # scale_fill_brewer(palette = 'PiYG')
    # scale_fill_viridis_d(option='D', direction=1)+
    labs(fill='OER quintile')
)
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

pdffile <- fs::path_rel(here::here('docs','Result_Graphs','Figure-1-1-quintile.pdf'))
ggsave(pdffile, plot = plt13)
# x <- magick::image_read_pdf(pdffile)
# magick::image_write(x, stringr::str_replace(pdffile, 'pdf','png'))

pdftools::pdf_convert(pdffile, format='png',
                      filenames = str_replace(pdffile, 'pdf','png'), dpi=300)
pdftools::pdf_convert(pdffile, format = 'tiff',
                      filenames = str_replace(pdffile,'pdf','tiff'), dpi=300)

