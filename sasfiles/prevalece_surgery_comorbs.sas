/* Prevalence of replacement surgery among patients with dementia, CHF, HIV, lung cancer, depression, poor and its association with HRR-SMR */

proc print data=sh026544.proj4_hrr_end15_white (obs=10);run;


data sh026544.proj4_dementia sh026544.proj4_chf sh026544.proj4_ulcers sh026544.proj4_pvd 
	sh026544.proj4_depression sh026544.proj4_poor sh026544.proj4_poorrisk sh026544.proj4_contra 
	sh026544.proj4_diabetes;
set sh026544.proj4_hrr_end15_white;
if(dementia=1) then output sh026544.proj4_dementia;
if(chf=1) then output sh026544.proj4_chf;
if(ulcers=1) then output sh026544.proj4_ulcers;
if(pvd= 1) then output sh026544.proj4_pvd;
if (poor=1) then output sh026544.proj4_poor;
if (depress=1) then output sh026544.proj4_depression;
if (dementia=1 or chf=1 or ulcers=1 or pvd=1) then output sh026544.proj4_poorrisk;
if (chf=1 or ulcers=1 or pvd=1) then output sh026544.proj4_contra;
if (diab=1) then output sh026544.proj4_diabetes;
run;

data tmp;
set sh026544.proj4_hrr_end15_white;
comorbs = sum(of acutemi--ulcers);
where agecat=1;
run;
data sh026544.proj4_healthy;
set tmp;
where comorbs=0;
run;

data white_smr;
set sh026544.proj4_smr_white;
keep hrr smr3;
run;

%macro comorb_tka(condn);
proc sql;
create table tmp as
select distinct bene_id, hrr, personyrs from sh026544.proj4_&condn;
create table denom as 
	select hrr, sum(personyrs) as denom from tmp group by hrr;
create table num as 
	select hrr, sum(tka) as num from sh026544.proj4_&condn group by hrr;
create table sh026544.proj4_tka_&condn as 
	select a.hrr, a.num, b.denom,a.num/b.denom as prop, c.smr3
		from num a 
		left join denom b on a.hrr=b.hrr
		left join white_smr c on a.hrr=c.hrr;
data sh026544.proj4_tka_&condn;
set sh026544.proj4_tka_&condn;
condition = "&condn";
prop = 1000 * prop; /* per 1000 */
run;
%mend;

%comorb_tka(dementia);
%comorb_tka(ulcers);
%comorb_tka(pvd);
%comorb_tka(chf);
%comorb_tka(healthy);
%comorb_tka(poorrisk);
%comorb_tka(contra);
%comorb_tka(diabetes);

data proj4_tka_conditions;
set sh026544.proj4_tka_dementia sh026544.proj4_tka_ulcers sh026544.proj4_tka_pvd sh026544.proj4_tka_chf sh026544.proj4_tka_healthy sh026544.proj4_tka_poorrisk
	sh026544.proj4_tka_contra sh026544.proj4_tka_diabetes;
run;

/*
%macro comorb_plt_tka(condn);
proc sgplot data=tka_&condn noautolegend;
title "Whites: &condn";
scatter x=prop y=smr3 / markerattrs=(color=black symbol=circlefilled);
loess x=prop y = smr3 / lineattrs=(color=red);
yaxis label="SMR";/* type=log logstyle=linear grid;/
xaxis label="Proportion of &condn patients having replacements";
run;
%mend;

%comorb_plt_tka(dementia);
%comorb_plt_tka(chf);
%comorb_plt_tka(ulcers);
%comorb_plt_tka(pvd);
%comorb_plt_tka(depression);
%comorb_plt_tka(poor);
*/
