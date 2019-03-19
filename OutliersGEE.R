library(readxl)
library(tidyverse)
library(sf)
library(plotly)
library(openxlsx)
library(ProjTemplate)
library(here)

datadir <- fs::path(find_dropbox(),'NIAMS','Ward','Medicare2015')

# LowHigh.xlsx was hand-curated from the SAS analysis

datafile <- fs::path(here(),'data','LowHigh.xlsx')
sn <- openxlsx::getSheetNames(datafile)
d <- map_df(sn, ~read_excel(datafile, sheet=.x), .id='Direction') %>%
  mutate(Direction = ifelse(Direction==1, 'Low','High')) %>%
  mutate(Level99 = ifelse(is.na(Level99), '', Level99))

hrr_info <- st_read(fs::path(datadir,'HRR_Bdry.SHP'))

d <- d %>% left_join(hrr_info, by = c('HRR'="HRRNUM")) %>%
  select(Direction:Level99, HRRCITY, geometry) %>%
  mutate(color = ifelse(Direction == 'Low', 'green','red'))

bl <- as.data.frame(hrr_info)

# quartz()
# ggplot(bl) + geom_sf() + geom_sf(data=d, aes(fill=color))+
#   scale_fill_manual(values = c('green'='green','red'='red'))

hrr_info %>% left_join(d %>% select(Direction, HRR, Level99), by=c("HRRNUM"="HRR")) %>%
  mutate(colors = ifelse(Direction=='Low', 'green','red')) %>%
  mutate(Direction = ifelse(is.na(Direction), 'Normal', Direction)) %>%
  mutate(Level99 = ifelse(is.na(Level99), '', Level99)) -> blah

if(!fs::dir_exists('outputs')) fs::dir_create('outputs')
blah %>% as_tibble() %>% select(HRRNUM:Level99) %>%
  filter(Direction != 'Normal') %>%
  arrange(desc(Direction)) -> out

wb <- createWorkbook()
addWorksheet(wb, 'Fully adjusted')
negStyle <- createStyle(fontColour = 'black', bgFill = 'red')
posStyle <- createStyle(fontColour = 'black', bgFill = 'green')
style99 <- createStyle(fontColour = 'black', bgFill = 'yellow')
writeDataTable(wb, 'Fully adjusted', out, withFilter = TRUE)
conditionalFormatting(wb, 'Fully adjusted', cols = 1:ncol(out), rows = 2:(nrow(out)+1),
                      type='contains',
                      rule = "Low", style=posStyle)
conditionalFormatting(wb, 'Fully adjusted', cols = 1:ncol(out), rows = 2:(nrow(out)+1),
                      type='contains',
                      rule = "High", style=negStyle)
conditionalFormatting(wb, 'Fully adjusted', cols = 4, rows = 2:(1+nrow(out)),
                      type = 'contains',
                      rule = 'x', style = style99)
setColWidths(wb, 'Fully adjusted', widths = 'auto', cols = 1:ncol(out))
saveWorkbook(wb, file = fs::path('outputs','Outliers-fully-adjusted.xlsx'),
             overwrite = TRUE)

plotly::plot_ly(blah, color = ~Direction, colors = c('red','green', 'white'),
                alpha=1, stroke = I("black"),
                hoverinfo = ~HRRCITY, hoveron="fill")

hrr_info %>% left_join(d %>% select(Direction, HRR, Level99) %>% filter(Level99=='x'),
                       by=c("HRRNUM"="HRR")) %>%
  mutate(colors = ifelse(Direction=='Low', 'green','red')) %>%
  mutate(Direction = ifelse(is.na(Direction), 'Normal', Direction)) %>%
  mutate(Level99 = ifelse(is.na(Level99), '', Level99))-> blah

plotly::plot_ly(blah, color = ~Direction,
                colors = c('red','green', 'white'),
                alpha=1, stroke = I("black"),
                hoverinfo = ~HRRCITY, hoveron="fill")


# plt <- ggplot(blah) + geom_sf(aes(fill=Direction))+
#   scale_color_manual(values = c('Low'='green','Normal'='white', 'High' = 'red'))
