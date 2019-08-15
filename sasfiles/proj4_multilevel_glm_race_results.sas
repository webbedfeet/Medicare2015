title "Whites analysis";
data modsummary_white;
set sh026544.proj4_hrr_modsummary_white_2011
 sh026544.proj4_hrr_modsummary_white_2012
 sh026544.proj4_hrr_modsummary_white_2013
 sh026544.proj4_hrr_modsummary_white_2014
 sh026544.proj4_hrr_modsummary_white_2015;
run;
proc contents data=modsummary_white; run;
proc sql;
create table smr_white as 
	select distinct hrr, race, sum(total_knee) as total_knee, sum(expected_knee1) as exp1,
	sum(expected_knee2) as exp2, sum(expected_knee3) as exp3, sum(py) as py
	from modsummary_white
	group by hrr;
data smr_white;
set smr_white;
smr1 = total_knee/exp1;
smr2 = total_knee/exp2;
smr3 = total_knee/exp3;
run;


proc sql;
create table expected_rate as
	select hrr, race, sum(exp1) as exp1, sum(exp2) as exp2, sum(exp3) as exp3, sum(py) as py
from smr_white;
data expected_rate_white;
set expected_rate;
title "Expected rates, white";
expected_white = exp3/py * 1000;
keep expected_white;
run;
proc sql;
	create table expected_rate_white as 
	select distinct * from expected_rate_white;
proc sql;
create table white_counts as
select hrr, count(*)/5 as n, sum(tka)/5 as tka from sh026544.proj4_hrr_end15_white
	group by hrr
	order by hrr;
proc sql;
	create table sh026544.proj4_smr_white as
	select distinct * from smr_white a
		left join work.white_counts c on a.hrr=c.hrr
		left join sh026544.proj4_hrrlevel b on a.hrr=b.hrr and a.race=b.race
	order by smr3;
proc print data=sh026544.proj4_smr_white (obs=20); run;

title "Blacks";
data modsummary_black;
set sh026544.proj4_hrr_modsummary_black_2011
 sh026544.proj4_hrr_modsummary_black_2012
 sh026544.proj4_hrr_modsummary_black_2013
 sh026544.proj4_hrr_modsummary_black_2014
 sh026544.proj4_hrr_modsummary_black_2015;
run;
proc sql;
create table smr_black as 
	select hrr, race, sum(total_knee) as total_knee, sum(expected_knee1) as exp1,
	sum(expected_knee2) as exp2, sum(expected_knee3) as exp3, sum(py) as py
	from modsummary_black
	group by hrr;
data smr_black;
set smr_black;
smr1 = total_knee/exp1;
smr2 = total_knee/exp2;
smr3 = total_knee/exp3;
run;

proc sql;
create table expected_rate_black as
	select hrr, race, sum(exp1) as exp1, sum(exp2) as exp2, sum(exp3) as exp3, sum(py) as py
from smr_black;
data expected_rate_black;
set expected_rate_black;
title "Expected rates, black";
expected_black = exp3/py * 1000;
keep expected_black;
run;
proc sql;
	create table expected_rate_black as 
	select distinct * from expected_rate_black;

/********************************************************************************************************
Let's identify HRRs where there are at least 100,000 black people in the database. Well they don't exist. We're cutting
off at 15,000, in line with white HRRs
/********************************************************************************************************/

proc sql;
create table white_counts as
select hrr, count(*)/5 as n, sum(tka)/5 as tka from sh026544.proj4_hrr_end15_white
	group by hrr
	order by hrr;
create table black_counts as 
select hrr,  count(*)/5 as n, sum(tka)/5 as tka from sh026544.proj4_hrr_end15_black
	group by hrr
	order by hrr;
create table hisp_counts as
select hrr, count(*)/5 as n, sum(tka)/5 as tka from sh026544.proj4_hrr_end15_hispanic
	group by hrr
	order by hrr;
proc sql;
create table tmp as
	select * from smr_black a 
		left join black_counts b on a.hrr=b.hrr
		left join sh026544.proj4_hrrlevel c on a.hrr=c.hrr and a.race=c.race
	order by smr3;

data sh026544.proj4_smr_black;
	set tmp;
	where n > 15000;
run;




title "Hispanics";

data modsummary_hisp;
set sh026544.proj4_hrr_modsummary_hisp_2011
 sh026544.proj4_hrr_modsummary_hisp_2012
 sh026544.proj4_hrr_modsummary_hisp_2013
 sh026544.proj4_hrr_modsummary_hisp_2014
 sh026544.proj4_hrr_modsummary_hisp_2015;
run;
proc sql;
create table smr_hisp as 
	select hrr, race, sum(total_knee) as total_knee, sum(expected_knee1) as exp1,
	sum(expected_knee2) as exp2, sum(expected_knee3) as exp3, sum(py) as py
	from modsummary_hisp
	group by hrr;
data smr_hisp;
set smr_hisp;
smr1 = total_knee/exp1;
smr2 = total_knee/exp2;
smr3 = total_knee/exp3;
run;
proc sql;
create table tmp as
	select * from smr_hisp a 
		left join hisp_counts b on a.hrr=b.hrr
		left join sh026544.proj4_hrrlevel c on a.hrr=c.hrr and a.race=c.race
	order by smr3;

data sh026544.proj4_smr_hisp;
	set tmp;
	where n > 15000;
run;




/*
%macro make_funnel(data, label="TRUE");
data tmp;
	set &data;
	L95 = 1 - 1.96*sqrt(1/exp3);
	L99 = 1 - 2.58*sqrt(1/exp3);
	U95 = 1 + 1.96*sqrt(1/exp3);
	U99 = 1 + 2.58*sqrt(1/exp3);
	if smr3 > U95 then result95 = 'high';
		else if smr3 < L95 then result95='low';
		else result95 = 'norm';
	if smr3 > U99 then result99 = 'high';
		else if smr3 < L99 then result99 = 'low';
		else result99 = 'norm';
	Label = hrr;
	if L99 <= smr3 <= U99 then Label='';
	run;
proc sort data=tmp;
	by exp3;
	run;
proc sgplot data=tmp;
	band x=exp3 lower=L95 upper=U95/nofill lineattrs=(color=lipk) legendlabel="95% limits" name='band95';
	band x=exp3 lower=L99 upper=U99/nofill lineattrs=(color=gray) legendlabel="99.8% limits" name="band99";
	refline 1 / axis=y;
	%if &label="TRUE" %then
	%do;
		scatter x=exp3 y=smr3 / datalabel=Label markerattrs=(color=black symbol=circlefilled) transparency=0.5;
	%end;
	%else
	%do;
		scatter x=exp3 y = smr3 / markerattrs=(color=black symbol=circlefilled) transparency=0.5;
	%end;
	keylegend "band95" "band99" / location=inside position=topright;
	yaxis grid label='SMR';
	xaxis label = 'Expected number of replacements';
	run;

%mend;

title "Funnel plots, whites";
%make_funnel(sh026544.proj4_smr_white, label="FALSE");
title "Funnel plots, blacks";
%make_funnel(sh026544.proj4_smr_black, label="FALSE");
*/

/*
proc print data=sh026544.proj4_smr_white (obs=20); run;

title "Whites graphical analysis";
data sh026544.proj4_smr_white;
set sh026544.proj4_smr_white;
label rural_perc="Percent rural";
label mcare_adv_wtperc="Percent with Medicare Advantage";
label mean_op="Mean number of outpatient visits";
label ortho_per_100000="Number of orthopedists per 1000";
label mean_koa_visits="Mean number of knee visits";
label frac_koa="Proportion with at least 1 knee visit";
run;

proc sgplot data=sh026544.proj4_smr_white noautolegend;
scatter x=rural_perc y=smr3/ markerattrs=(color=black symbol=circlefilled);
loess x=rural_perc y=smr3 / lineattrs=(color=red) smooth=0.3;
yaxis label="SMR" type=log logstyle=linear grid;
run;

proc sgplot data=sh026544.proj4_smr_white noautolegend;
scatter x=mean_koa_visits y=smr3/ markerattrs=(color=black symbol=circlefilled);
loess x=mean_koa_visits y=smr3/ lineattrs=(color=red) smooth=0.3;
yaxis label="SMR" type= log logstyle=linear grid;

proc sgplot data=sh026544.proj4_smr_white noautolegend;
scatter x=frac_koa y=smr3/ markerattrs=(color=black symbol=circlefilled);
loess x=frac_koa y=smr3/ lineattrs=(color=red) smooth=0.3;
yaxis label="SMR" type= log logstyle=linear grid;

proc sgplot data=sh026544.proj4_smr_white noautolegend;
scatter x=mcare_adv_wtperc y=smr3/ markerattrs=(color=black symbol=circlefilled);
loess x=mcare_adv_wtperc y=smr3 / lineattrs=(color=red) smooth=0.3;
yaxis label="SMR" type=log logstyle=linear grid;
run;

proc sgplot data=sh026544.proj4_smr_white ;
styleattrs wallcolr=CXF0F0F0;
scatter x=mean_op y=smr3/ colormodel=TwoColorRamp colorresponse=rural_perc markerattrs=(symbol=circlefilled);
loess x=mean_op y=smr3 / lineattrs=(color=red);
yaxis label="SMR" type=log logstyle=linear grid;
run;

proc sgplot data=sh026544.proj4_smr_white noautolegend;
scatter x=median_op y=smr3/markerattrs=(color=black symbol=circlefilled);
loess x=median_op y=smr3 / lineattrs=(color=red);
yaxis label="SMR" type=log logstyle=linear grid;
run;

proc sgplot data=sh026544.proj4_smr_white ;
scatter x=ortho_per_100000 y=smr3/ colorresponse=rural_perc colormodel=TwoColorRamp markerattrs=( symbol=circlefilled);
loess x=ortho_per_100000 y=smr3 / lineattrs=(color=red);
yaxis label="SMR" type=log logstyle=linear grid;
run;

title "Graphical analyses, blacks";

data sh026544.proj4_smr_black;
set sh026544.proj4_smr_black;
label rural_perc="Percent rural";
label mcare_adv_wtperc="Percent with Medicare Advantage";
label mean_op="Mean number of outpatient visits";
label ortho_per_100000="Number of orthopedists per 1000";
run;

proc sgplot data=sh026544.proj4_smr_black noautolegend;
scatter x=rural_perc y=smr3/ markerattrs=(color=black symbol=circlefilled);
loess x=rural_perc y=smr3 / lineattrs=(color=red);
yaxis label="SMR" type=log logstyle=linear grid;
run;

proc sgplot data=sh026544.proj4_smr_black noautolegend;
scatter x=mcare_adv_wtperc y=smr3/ markerattrs=(color=black symbol=circlefilled);
loess x=mcare_adv_wtperc y=smr3 / lineattrs=(color=red);
yaxis label="SMR" type=log logstyle=linear grid;
run;

proc sgplot data=sh026544.proj4_smr_black ;
styleattrs wallcolr=CXF0F0F0;
scatter x=mean_op y=smr3/ colormodel=TwoColorRamp colorresponse=rural_perc markerattrs=(symbol=circlefilled);
loess x=mean_op y=smr3 / lineattrs=(color=red);
yaxis label="SMR" type=log logstyle=linear grid;
run;

proc sgplot data=sh026544.proj4_smr_black noautolegend;
scatter x=median_op y=smr3/markerattrs=(color=black symbol=circlefilled);
loess x=median_op y=smr3 / lineattrs=(color=red);
yaxis label="SMR" type=log logstyle=linear grid;
run;

proc sgplot data=sh026544.proj4_smr_black ;
scatter x=ortho_per_100000 y=smr3/ colorresponse=rural_perc colormodel=TwoColorRamp markerattrs=( symbol=circlefilled);
loess x=ortho_per_100000 y=smr3 / lineattrs=(color=red);
yaxis label="SMR" type=log logstyle=linear grid;
run;

title "Races side by side";
data smr_overall;
set sh026544.proj4_smr_white sh026544.proj4_smr_black;
run;

proc sgpanel data=smr_overall ;
panelby race/ rows=1;
scatter x=mean_op y=smr3/ colorresponse=rural_perc colormodel=TwoColorRamp markerattrs=( symbol=circlefilled);
loess x=mean_op y=smr3 / lineattrs=(color=red);
rowaxis label="SMR" type=log logstyle=linear grid;
run;
proc sgpanel data=smr_overall ;
panelby race/ rows=1;
scatter x=ortho_per_100000 y=smr3/ colorresponse=rural_perc colormodel=TwoColorRamp markerattrs=( symbol=circlefilled);
loess x=ortho_per_100000 y=smr3 / lineattrs=(color=red);
rowaxis label="SMR" type=log logstyle=linear grid;
run;
*/

/* SMR vs expected probabilities */
/*
data white_smr_exp;
set sh026544.proj4_smr_white;
expect_prob = exp3/py;
keep hrr exp3 smr3 expect_prob;
run;
proc contents data=white_smr_exp; run;

proc sgplot data=white_smr_exp noautolegend;
scatter x= expect_prob y=smr3 /  markerattrs=(color=black symbol=circlefilled);
loess x=expect_prob y = smr3 / lineattrs=(color=red);
xaxis label="Expected probability of replacement";
yaxis label="SMR";
run;
*/

