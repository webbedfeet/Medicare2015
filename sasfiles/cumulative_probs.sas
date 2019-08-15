/* Cumulative probability plots by HRR and SMR levels */

proc print data=sh026544.proj4_smr_white (obs=10); run;
proc print data=sh026544.proj4_mod3_white_2011 (obs=10); run;

proc format;
value smrgrp 1="Very low (< 0.67)"
             2="Low (0.67-0.83)"
			 3="Normal (0.83-1.2)"
			 4="High (1.2-1.5)"
			 5="Very high (> 1.5)";
run;

data smr_white;
set sh026544.proj4_smr_white;
keep hrr smr3;
run;
proc sort data=smr_white;
by hrr;
run;
data smr_white;
set smr_white;
group = . ;
if (smr3 > 1.5) then group=5;
if (smr3 <= 1.5 and smr3 > 1.2) then group = 4;
if (smr3 <= 1.2 and smr3 >= 1/1.2) then group = 3;
if (smr3 < 1/1.2 and smr3 >= 1/1.5) then group = 2;
if (smr3 < 1/1.5) then group = 1;
label group="SMR categories";
format group smrgrp.;
run;

data mod3_summary;
set sh026544.proj4_mod3_white_2011
	sh026544.proj4_mod3_white_2012
	sh026544.proj4_mod3_white_2013
	sh026544.proj4_mod3_white_2014
	sh026544.proj4_mod3_white_2015;
keep bene_id bene_enrollmt_ref_yr hrr Predicted;
run;

data knee_replaced;
set sh026544.project4_hrr_end15;
where tka > 0;
keep bene_id hrr tka;
run;

proc print data=mod3_summary(obs=10);run;
proc sql;
create table mod3_overall_max as
	select distinct bene_id, hrr, max(Predicted) as predicted from mod3_summary
	group by bene_id, hrr
	order by hrr;
proc sql;
create table mod3_overall_mean as 
	select distinct bene_id, hrr, mean(Predicted) as predicted from mod3_summary
	group by bene_id, hrr
	order by hrr;

proc sql;
create table mod3_overall_max_surg as
	select * from knee_replaced a left join mod3_overall_max b on a.bene_id=b.bene_id and a.hrr=b.hrr
	order by hrr;

proc sql;
create table mod3_overall_max_surg1 as
	select * from mod3_overall_max_surg a left join smr_white b on a.hrr=b.hrr order by group;

proc sgplot data=mod3_overall_max_surg;
title "Distribution of expected probabilities among those getting surgery";
histogram predicted;
xaxis label="Maximum expected probability of surgery (2011-2015)";
run;
/*
proc univariate data=mod3_overall_max_surg noprint; /* computes cumulative probabilities 
	var predicted;
	class hrr;
	cdfplot predicted;
	ods output cdfplot=outCDF; /* saves the data 
run;
*/

proc print data=mod3_overall_max_surg (obs=10); run;
proc univariate data=mod3_overall_max_surg1 noprint;
	by group;
	var predicted;
	output out=percentiles pctlpre=P pctlpts=1 to 100 by 1;
	run;

proc transpose data=percentiles out=tmp;
by group;
run;
proc sql;
create table perc_long as
	select * from tmp a left join smr_white b on a.hrr=b.hrr
	order by hrr;

data perc_long;
set tmp;
perctmp=compress(_NAME_,'','A');
perc = input(perctmp,8.);
perc = perc/100;
perc_val = col1;
keep  perc perc_val smr3 group;
run;
proc sort data=perc_long;
by hrr perc;
run;

proc sgplot data=perc_long;
series x=perc_val y=perc / group=group grouplc=group lineattrs=(pattern=Solid thickness=3);
run;

proc sgplot data=perc_long(where=(group=1 or group=5));
series x=perc_val y=perc / group=hrr grouplc=group lineattrs=(pattern=Solid) transparency=0.5;
keylegend / type=linecolor;
run;

proc sgpanel data=perc_long noautolegend;
panelby group/ novarname;
series x=perc_val y=perc / group=hrr lineattrs=(pattern=Solid) grouplc=group transparency=0.7;
run;

