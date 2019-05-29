# Meta-programming to create urban_rural.sas, which computes
# SMR differences between urban and rural residents in 9 HRRs
# that are "representative" of the different types of HRR by
# their overall SMR number


rm(list = ls())
library(tidyverse)

parse_zip <- function(x){
  x %>%
    str_split(',') %>% `[[`(1) %>% str_trim()
}

wichita <- #http://www.city-data.com/zipmaps/Wichita-Kansas.html
  c("67037, 67052, 67067, 67101, 67106, 67202, 67203, 67204, 67205, 67206, 67207, 67208, 67209, 67210, 67211, 67212, 67213, 67214, 67215, 67216, 67217, 67218, 67219, 67220, 67223, 67226, 67228, 67230, 67235, 67260") %>% parse_zip()


lincoln <- # http://www.city-data.com/zipmaps/Lincoln-Nebraska.html
  c("68336, 68430, 68502, 68503, 68504, 68505, 68506, 68507, 68508, 68510, 68512, 68514, 68516, 68517, 68520, 68521, 68522, 68523, 68524, 68526, 68528, 68531") %>% parse_zip()

salt_lake_city <- # http://www.city-data.com/zipmaps/Salt-Lake-City-Utah.html
  c("84044, 84101, 84102, 84103, 84104, 84105, 84106, 84108, 84109, 84111, 84112, 84113, 84115, 84116, 84119, 84120, 84128, 84144, 84180") %>% parse_zip()


greater_phoenix <- # https://www.bestplaces.net/find/zip.aspx?st=az&msa=38060
  c("85003 (Phoenix)", "85004 (Phoenix)", "85006 (Phoenix)", "85007 (Phoenix)", "85008 (Phoenix)", "85009 (Phoenix)", "85012 (Phoenix)", "85013 (Phoenix)", "85014 (Phoenix)", "85015 (Phoenix)", "85016 (Phoenix)", "85017 (Phoenix)", "85018 (Phoenix)", "85019 (Phoenix)", "85020 (Phoenix)", "85021 (Phoenix)", "85022 (Phoenix)", "85023 (Phoenix)", "85024 (Phoenix)", "85027 (Phoenix)", "85028 (Phoenix)", "85029 (Phoenix)", "85031 (Phoenix)", "85032 (Phoenix)", "85033 (Phoenix)", "85034 (Phoenix)", "85035 (Phoenix)", "85037 (Phoenix)", "85040 (Phoenix)", "85041 (Phoenix)", "85042 (Phoenix)", "85043 (Phoenix)", "85044 (Phoenix)", "85045 (Phoenix)", "85048 (Phoenix)", "85050 (Phoenix)", "85051 (Phoenix)", "85053 (Phoenix)", "85054 (Phoenix)", "85083 (Phoenix)", "85085 (Phoenix)", "85086 (Anthem)", "85087 (New River)", "85118 (Gold Canyon)", "85119 (Apache Junction)", "85120 (Apache Junction)", "85121 (Casa Blanca)", "85122 (Casa Grande)", "85123 (Arizona City)", "85128 (Coolidge)", "85131 (Eloy)", "85132 (Florence)", "85137 (Kearny)", "85138 (Maricopa)", "85139 (Maricopa)", "85140 (San Tan Valley)", "85141 (Picacho)", "85142 (Queen Creek)", "85143 (San Tan Valley)", "85145 (Red Rock)", "85147 (Sacaton)", "85172 (Stanfield)", "85173 (Superior)", "85193 (Casa Grande)", "85194 (Casa Grande)", "85201 (Mesa)", "85202 (Mesa)", "85203 (Mesa)", "85204 (Mesa)", "85205 (Mesa)", "85206 (Mesa)", "85207 (Mesa)", "85208 (Mesa)", "85209 (Mesa)", "85210 (Mesa)", "85212 (Mesa)", "85213 (Mesa)", "85215 (Mesa)", "85224 (Chandler)", "85225 (Chandler)", "85226 (Chandler)", "85233 (Gilbert)", "85234 (Gilbert)", "85248 (Chandler)", "85249 (Chandler)", "85250 (Scottsdale)", "85251 (Scottsdale)", "85253 (Paradise Valley)", "85254 (Phoenix)", "85255 (Scottsdale)", "85256 (Scottsdale)", "85257 (Scottsdale)", "85258 (Scottsdale)", "85259 (Scottsdale)", "85260 (Scottsdale)", "85262 (Scottsdale)", "85263 (Rio Verde)", "85264 (Fort McDowell)", "85266 (Scottsdale)", "85268 (Fountain Hills)", "85281 (Tempe)", "85282 (Tempe)", "85283 (Tempe)", "85284 (Tempe)", "85286 (Chandler)", "85295 (Gilbert)", "85296 (Gilbert)", "85297 (Gilbert)", "85298 (Gilbert)", "85301 (Glendale)", "85302 (Glendale)", "85303 (Glendale)", "85304 (Glendale)", "85305 (Glendale)", "85306 (Glendale)", "85307 (Glendale)", "85308 (Glendale)", "85309 (Glendale)", "85310 (Phoenix)", "85320 (Aguila)", "85322 (Arlington)", "85323 (Avondale)", "85326 (Buckeye)", "85331 (Phoenix)", "85335 (El Mirage)", "85337 (Gila Bend)", "85338 (Goodyear)", "85339 (Phoenix)", "85340 (Litchfield Park)", "85342 (Morristown)", "85343 (Palo Verde)", "85345 (Peoria)", "85351 (Sun City)", "85353 (Phoenix)", "85354 (Tonopah)", "85355 (Waddell)", "85361 (Wittmann)", "85363 (Youngtown)", "85373 (Sun City)", "85374 (Surprise)", "85375 (Sun City West)", "85377 (Carefree)", "85379 (Surprise)", "85381 (Peoria)", "85382 (Peoria)", "85383 (Peoria)", "85387 (Surprise)", "85388 (Surprise)", "85390 (Wickenburg)", "85392 (Avondale)", "85395 (Goodyear)", "85396 (Buckeye)", "85618 (Mammoth)", "85623 (Oracle)", "85631 (San Manuel)")
phoenix <- str_remove(greater_phoenix, '[A-Za-z \\(\\)]+')
rm(greater_phoenix)

albuquerque <- # http://www.city-data.com/zipmaps/Albuquerque-New-Mexico.html
  c("87048, 87102, 87104, 87105, 87106, 87107, 87108, 87109, 87110, 87111, 87112, 87113, 87114, 87116, 87117, 87120, 87121, 87122, 87123") %>% parse_zip()
santa_fe <-  # http://www.city-data.com/zipmaps/Santa-Fe-New-Mexico.html
  c("87501, 87505, 87506, 87507, 87508") %>% parse_zip()
los_alamos <- c('87544','87545')
albuquerque <- Reduce(union, list(albuquerque, santa_fe, los_alamos))
rm(los_alamos);rm(santa_fe)

bakersfield <- # http://www.city-data.com/zipmaps/Bakersfield-California.html
  c("93203, 93220, 93301, 93304, 93305, 93306, 93307, 93308, 93309, 93311, 93312, 93313, 93314") %>%
  parse_zip()

san_antonio <- # http://www.city-data.com/zipmaps/San-Antonio-Texas.html
  c("78023, 78056, 78073, 78109, 78112, 78154, 78201, 78202, 78203, 78204, 78205, 78207, 78208, 78209, 78210, 78211, 78212, 78213, 78214, 78215, 78216, 78217, 78218, 78219, 78220, 78221, 78222, 78223, 78224, 78225, 78226, 78227, 78228, 78229, 78230, 78231, 78232, 78233, 78234, 78235, 78236, 78237, 78238, 78239, 78240, 78242, 78243, 78244, 78245, 78247, 78248, 78249, 78250, 78251, 78252, 78253, 78254, 78255, 78256, 78257, 78258, 78259, 78260, 78263, 78264, 78266") %>%
  parse_zip()

lexington <- # http://www.city-data.com/zipmaps/Lexington-Fayette-Kentucky.html
  c("40361, 40502, 40503, 40504, 40505, 40506, 40507, 40508, 40509, 40510, 40511, 40513, 40514, 40515, 40516, 40517") %>% parse_zip()

syracuse <-
  c("13120, 13202, 13203, 13204, 13205, 13206, 13207, 13208, 13210, 13214, 13215, 13219, 13224, 13290") %>% parse_zip()

city_names <- setdiff(ls(), 'parse_zip')

l1 <- map(syms(city_names), eval)
names(l1) <- city_names

cities <- tibble('city' = names(l1)) %>% mutate(zips = l1)

hrr_info <- sf::st_read('~/Downloads/hrr_bdry-1/HRR_Bdry.SHP', quiet=T) %>%
  as_tibble() %>%
  select(HRRNUM, HRRCITY) %>%
  separate(HRRCITY, c("State","City"), sep = '-', extra = 'merge') %>%
  mutate(City = str_trim(City)) %>%
  mutate(City = str_to_title(City)) %>%
  mutate(ID = str_to_lower(str_replace_all(City,' ', '_')))

cities <- cities %>% left_join(hrr_info, by=c('city' = 'ID')) %>%
  mutate(parse_zip = map(zips, ~paste(shQuote(.), collapse=',')))


# Meta-programming

template <-
  "
data proj4_white_{city};
set proj4_white_{city};
if zip in ({parse_zip}) then city=1;
else city = 0;
run;

%urban_smr({city})
"
outfile <- 'urban_rural.sas'

macro <-
"
%macro urban_smr(cty);
proc sql;
create table smr_&cty as
  select city, sum(tka) as obs, sum(predicted) as expected from proj4_white_&cty
  group by city;
data smr_&cty;
set smr_&cty;
smr3 = obs/expected;
location = &cty;
run;
%mend;
"

cat(macro, file = outfile, sep = '\n\n')

cat(
paste('data',
      paste(glue_data(cities, 'proj4_white_{city} '), collapse=' '),';\n'),
file = outfile, append = T)
cat('set sh026544.proj4_mod3_white;\n', file = outfile, append = T)
cat(
  glue_data(cities,'if (hrrnum = {HRRNUM}) then output proj4_white_{city};'),
  file = outfile, append = T, sep = '\n')
cat('run;\n\n', file = outfile, append = T)

cat(glue_data(cities, template), file = outfile, append = T, sep = '\n\n')

cat('\n\ndata sh026544.proj4_smr_rural_urban;', file = outfile, append = T, sep = '\n')
cat('set ', file = outfile, append = T, sep = '\n')
cat(glue_data(cities, 'smr_{city}'), file = outfile, append = T, sep = '\n')
cat('; run;', file = outfile, append = T)

