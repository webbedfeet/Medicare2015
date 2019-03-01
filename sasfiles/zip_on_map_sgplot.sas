%let name=zip_on_map_sgplot;
filename odsout '.';

/*
Updated version of this Tech Support example:
http://support.sas.com/kb/31/419.html
*/

data locations;
input Zip;
City=zipcity(zip);
data_flag=1;
datalines;
35004
85003
71601
80002
06001
19701
20001
32007
83201
60001
46001
50001
66002
40003
70001
3901
20601
1001
27513
;
run;

proc geocode data=locations out=locations (rename=(x=long y=lat))
 method=ZIP lookup=sashelp.zipcode;
run;

data my_map; set mapsgfk.us_states
 (where=(statecode not in ('AK' 'HI') and density<=3) drop=resolution);
run;

/* 
Sgplot polygons need every segment of every polygon to have a unique id.
*/
data my_map; set my_map;
length statecode_plus_segment $10;
statecode_plus_segment=trim(left(statecode))||'_'||trim(left(segment));
run;

/*
We combine the data & map to project them together, to guarantee
that the projected x/y will line up right. (There is a way to
project them separately, if you really want to do that...)
*/
data combined; set my_map locations;
run;
proc gproject data=combined out=combined latlong eastlong degrees;
 id statecode;
run;
data my_map locations; set combined;
if data_flag=1 then output locations;
else output my_map;
run;

/*
I like splitting the map & data apart after projecting it.
This gives a lot of flexibility, for example, if you want to
annotate the data.
But in this case, using an overlaid sgplot scatter, 
we will end up combining them again.
I guess you 'could' save a little time by leaving
them together, but I prefer working with the datasets
split apart.
*/

/* 
sganno doesn't support hover-text tips yet, so let's use 
an overlaid scatter plot instead...
*/
data scatter_locations (rename=(x=zipX y=zipY)); 
 set locations (keep = zip city x y);
label city_zip='00'x;
length city_zip $100;
city_zip='= = = = ='||'0d'x||trim(left(city))||'0d'x||trim(left(zip));
run;

/* 
To overlay a scatter on a map, you must combine the two datasets.
Make sure you don't have any variables named the same!
*/
data my_map; set my_map scatter_locations;
run;


goptions device=png;
goptions border;

ODS _ALL_ CLOSE;
ODS HTML path=odsout body="&name..htm" 
 (title="Zipcode dots overlaid on a sgplot") 
 style=htmlblue;

ods graphics on / imagename="&name" height=6.25in width=8.33in
 imagefmt=staticmap imagemap=on tipmax=2500;

/* Calculate the aspect ratio of the points in the map */
proc sql noprint;
select (max(y)-min(y))/(max(x)-min(x)) into :aspect from combined;
quit; run;

title1 ls=0.2 height=22pt c=gray33 'ZIP Code locations on a US Map';
title2 height=12pt c=gray33 "Using Proc SGplot, and overlaid scatter markers";

proc sgplot data=my_map noborder noautolegend aspect=&aspect;
 polygon x=x y=y id=statecode_plus_segment / fill outline tip=none
  lineattrs=(color=gray99) fillattrs=(color=cxe8edd5);
 scatter x=zipX y=zipY / tip=(city_zip)
   filledoutlinemarkers
   markerattrs=(symbol=circlefilled size=13)
   markerfillattrs=(color=yellow) 
   markeroutlineattrs=(color=purple);
 xaxis display=none;
 yaxis display=none;
run;

proc sort data=locations out=locations;
by city;
run;

title;
proc print data=locations noobs;
format zip z5.;
format lat long comma8.1;
var city zip lat long;
run;

quit;
ODS HTML CLOSE;
ODS LISTING;
