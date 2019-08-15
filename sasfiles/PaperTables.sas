/* Descriptive tables for paper */


proc sql;
create table summaries  as 
	select hrr, mean(age_at_end_ref_yr) as age, mean(male) as male, mean(acutemi) as acutemi,
	mean(afib) as afib, mean(breast_past) as breast, mean(chf) as chf, mean(ckd) as ckd, 
	mean(colorectal_past) as colorectal, mean(copd) as copd, mean(dementia) as dementia, 
	mean(depress) as depress, mean(diab) as diab, mean(endometrial_past) as endometrial_past, 
	mean(hememalignancy) as hememalignancy, mean(hiv) as hiv, mean(ihd) as ihd,
	mean(liver) as liver, mean(lung_past) as lung, mean(prostate_past) as prostate, mean(pvd) as pvd,
	mean(stroke) as stroke, mean(ulcers) as ulcers, mean(koa) as koa, mean(kneesymptoms) as kneesymptoms,
	mean(knee_patient) as knee_patient, mean(op_visits) as op_visits, mean(obese_wtperc) as obese, mean(physjob_t_wtperc) as physjob,
	mean(smoking_wtperc) as smoking, mean(mcare_adv_wtperc) as mcare, mean(poor) as poor, 
	mean(zscore) as zscore, mean(rural) as rural 
	from sh026544.proj4_hrr_end15_white
	group by hrr;
create table perc_white as
	select hrr, mean(race=1) as race from sh026544.project4_hrr_end15
	group by hrr;
create table suppl1 as
	select * from summaries a left join perc_white b on a.hrr=b.hrr;

proc sql;
create table tkas as
	select sum(tka) as tka, count(*) as n, bene_enrollmt_ref_yr from sh026544.project4_hrr_end15 group by bene_enrollmt_ref_yr;
create table tkas_white as 
	select sum(tka) as tka, count(*) as n, bene_enrollmt_ref_yr from sh026544.proj4_hrr_end15_white group by bene_enrollmt_ref_yr;
	
proc freq data=sh026544.project4_hrr_end15;
tables race;
run;