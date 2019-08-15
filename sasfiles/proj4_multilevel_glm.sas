/* Program for setting up and performing multilevel modeling for the Medicare data */
/* Abhijit Dasgupta */

/* Cluster sampling is in proj4_cluster_sampling */

	/*******************************************************************************************************/

options cmplib=work.cmplib;

/*
data proj4_hrr_end15;
	set sh026544.project4_hrr_end15;
	ltime = log(personyrs);
run;
*/

/* Split data by year */
/*
data proj4_hrr_end15_2011 proj4_hrr_end15_2012 proj4_hrr_end15_2013 proj4_hrr_end15_2014 proj4_hrr_end15_2015;
	set sh026544.project4_hrr_end15;
	ltime = log(personyrs);
	if bene_enrollmt_ref_yr = 2011 then output proj4_hrr_end15_2011;
	else if bene_enrollmt_ref_yr = 2012 then output proj4_hrr_end15_2012;
	else if bene_enrollmt_ref_yr = 2013 then output proj4_hrr_end15_2013;
	else if bene_enrollmt_ref_yr = 2014 then output proj4_hrr_end15_2014;
	else output proj4_hrr_end15_2015;
run;
data sh026544.proj4_hrr_end15_2011;
set proj4_hrr_end15_2011;
run;
data sh026544.proj4_hrr_end15_2012;
set proj4_hrr_end15_2012;
run;
data sh026544.proj4_hrr_end15_2013;
set proj4_hrr_end15_2013;
run;
data sh026544.proj4_hrr_end15_2014;
set proj4_hrr_end15_2014;
run;
data sh026544.proj4_hrr_end15_2015;
set proj4_hrr_end15_2015;
run;


proc contents data= sh026544.proj4_hrr_end15_2011;
run;

proc hpgenselect data=sh026544.proj4_hrr_end15_2011;
	class male race(ref='1')  agecat;
	model tka = agecat male race agecat*male race*male / dist=poisson offset=ltime;
	output pred=Predicted;
run;
*/


/*   Annual Poisson regression modeling */

/* Age, sex, race (Model 1)*/

proc genmod data= sh026544.proj4_hrr_end15_2011;
	class male race(ref='1')  agecat;
	model tka = agecat male race agecat male race agecat*male race*male / dist=poisson offset=ltime;
	output out=mod1_out pred=Predicted;
run;

/* Model 2 + 20 comorbidities (Model 3)*/
proc genmod data= sh026544.proj4_hrr_end15_2011;
	class male race(ref='1')  agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat male race agecat male race agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers poor zscore/  dist=poisson offset=ltime; /* added zscore and poor to model 3*/
	output out=mod3_out pred=Predicted;
run;


	proc sql;
	create table proj4_hrr_obs as 
		select hrr, race, sum(tka) as total_knee, sum(personyrs) as py from sh026544.proj4_hrr_end15_2011
			group by hrr, race;
	create table proj4_hrr_exp1 as
		select hrr, race, sum(Predicted*personyrs) as expected_knee1 from mod1_out
			group by hrr, race;
	create table proj4_hrr_exp3 as
		select hrr, race, sum(Predicted*personyrs) as expected_knee3 from mod3_out
			group by hrr, race;
	create table sh026544.proj4_hrr_modsummary_2011 as
		select * from proj4_hrr_obs
			natural join proj4_hrr_exp1
			natural join proj4_hrr_exp3;

proc datasets library=work;
	delete mod1_out  mod3_out;
run;
ods text="Done with 2011";

/* Age, sex, race (Model 1)*/
proc genmod data= sh026544.proj4_hrr_end15_2012;
	class male race(ref='1')  agecat;
	model tka = agecat male race agecat male race agecat*male race*male / dist=poisson offset=ltime;
	output out=mod1_out pred=Predicted;
run;

/* Model 2 + 20 comorbidities (Model 3)*/
proc genmod data= sh026544.proj4_hrr_end15_2012;
	class male race(ref='1')  agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat male race agecat male race agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers poor zscore/ dist=poisson offset=ltime;
	output out=mod3_out pred=Predicted;
run;

	proc sql;
	create table proj4_hrr_obs as 
		select hrr,race,sum(tka) as total_knee, sum(personyrs) as py from sh026544.proj4_hrr_end15_2012
			group by hrr, race;
	create table proj4_hrr_exp1 as
		select hrr, race,sum(Predicted*personyrs) as expected_knee1 from mod1_out
			group by hrr, race;
	create table proj4_hrr_exp3 as
		select hrr, race, sum(Predicted*personyrs) as expected_knee3 from mod3_out
			group by hrr, race;
	create table sh026544.proj4_hrr_modsummary_2012 as
		select * from proj4_hrr_obs
			natural join proj4_hrr_exp1
			natural join proj4_hrr_exp3;
proc datasets library=work;
	delete mod1_out  mod3_out;
run;

ods text="Done with 2012";

/* Age, sex, race (Model 1)*/
proc genmod data= sh026544.proj4_hrr_end15_2013;
	class male race(ref='1')  agecat;
	model tka = agecat male race agecat*male race*male / dist=poisson offset=ltime;
	output out=mod1_out pred=Predicted;
run;


/* Model 2 + 20 comorbidities (Model 3)*/
proc genmod data= sh026544.proj4_hrr_end15_2013;
	class male race(ref='1')  agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat male race agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers poor zscore/ dist=poisson offset=ltime;
	output out=mod3_out pred=Predicted;
run;

	proc sql;
	create table proj4_hrr_obs as 
		select hrr, race, sum(tka) as total_knee, sum(personyrs) as py from sh026544.proj4_hrr_end15_2013
			group by hrr, race;
	create table proj4_hrr_exp1 as
		select hrr, race, sum(Predicted*personyrs) as expected_knee1 from mod1_out
			group by hrr, race;
	create table proj4_hrr_exp3 as
		select hrr,race, sum(Predicted*personyrs) as expected_knee3 from mod3_out
			group by hrr, race;

	create table sh026544.proj4_hrr_modsummary_2013 as
		select * from proj4_hrr_obs
			natural join proj4_hrr_exp1
			natural join proj4_hrr_exp3;
proc datasets library=work;
	delete mod1_out  mod3_out ;
run;
ods text="Done with 2013";

/* Age, sex, race (Model 1)*/
proc genmod data= sh026544.proj4_hrr_end15_2014;
	class male race(ref='1')  agecat;
	model tka = agecat male race agecat*male race*male / dist=poisson offset=ltime;
	output out=mod1_out pred=Predicted;
run;
/* Model 2 + 20 comorbidities (Model 3)*/
proc genmod data= sh026544.proj4_hrr_end15_2014;
	class male race(ref='1')  agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat male race agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers poor zscore/ dist=poisson offset=ltime;
	output out=mod3_out pred=Predicted;
run;

proc sql;
	create table proj4_hrr_obs as 
		select hrr,race, sum(tka) as total_knee, sum(personyrs) as py from sh026544.proj4_hrr_end15_2014
			group by hrr, race;
	create table proj4_hrr_exp1 as
		select hrr, race,sum(Predicted*personyrs) as expected_knee1 from mod1_out
			group by hrr, race;
	create table proj4_hrr_exp3 as
		select hrr,race, sum(Predicted*personyrs) as expected_knee3 from mod3_out
			group by hrr, race;
	create table sh026544.proj4_hrr_modsummary_2014 as
		select * from proj4_hrr_obs
			natural join proj4_hrr_exp1
			natural join proj4_hrr_exp3;
proc datasets library=work;
	delete mod1_out  mod3_out ;
run;
ods text="Done with 2014";
/* Age, sex, race (Model 1)*/
proc genmod data= sh026544.proj4_hrr_end15_2015;
	class male race(ref='1')  agecat;
	model tka = agecat male race agecat*male race*male / dist=poisson offset=ltime;
	output out=mod1_out pred=Predicted;
run;


/* Model 2 + 20 comorbidities (Model 3)*/
proc genmod data= sh026544.proj4_hrr_end15_2015;
	class male race(ref='1')  agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat male race agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers poor zscore/ dist=poisson offset=ltime;
	output out=mod3_out pred=Predicted;
run;

	proc sql;
	create table proj4_hrr_obs as 
		select hrr,race, sum(tka) as total_knee, sum(personyrs) as py from sh026544.proj4_hrr_end15_2015
			group by hrr,race;
	create table proj4_hrr_exp1 as
		select hrr, race,sum(Predicted*personyrs) as expected_knee1 from mod1_out
			group by hrr, race;
	create table proj4_hrr_exp3 as
		select hrr, race, sum(Predicted*personyrs) as expected_knee3 from mod3_out
			group by hrr, race;
	create table sh026544.proj4_hrr_modsummary_2015 as
		select * from proj4_hrr_obs
			natural join proj4_hrr_exp1
			natural join proj4_hrr_exp3
;
proc datasets library=work;
	delete mod1_out  mod3_out ;
run;
ods text="Done with 2015";

data sh026544.proj4_hrr_modsummary_overall;
	set sh026544.proj4_hrr_modsummary_2011
		sh026544.proj4_hrr_modsummary_2012
		sh026544.proj4_hrr_modsummary_2013
		sh026544.proj4_hrr_modsummary_2014
		sh026544.proj4_hrr_modsummary_2015;
run;

ods text="Datasets put together";
proc sql;
	create table proj4_overall_summary as 
		select hrr, sum(total_knee) as total_knee, sum(expected_knee1) as expected_knee1, sum(expected_knee3) as expected_knee3 
			from sh026544.proj4_hrr_modsummary_overall
		group by hrr;

data sh026544.proj4_overall_SMR;
set proj4_overall_summary;
SMR1 = total_knee / expected_knee1;
SMR3 = total_knee / expected_knee3;
run;

proc sql;
	title 'Race percentage';
	create table race_count as
		select hrr,  race, count(*) as Count from sh026544.proj4_hrr_end15_2013
		group by hrr,  race;
	create table race_total as
		select hrr,  count(*) as Subtotal from sh026544.proj4_hrr_end15_2013
			group by hrr;
	create table race as
		select * from race_count natural join race_total;
data sh026544.proj4_race;
	set race;
	Percent = Count/Subtotal * 100;
	keep hrr race Percent;
run;

proc print data=sh026544.proj4_overall_smr;
run;

ods html;
ods text="Plotting SMR patterns by race";
proc sql;
	create table tmp as 
	select * from sh026544.proj4_overall_smr natural join sh026544.proj4_race;

	proc print data=sh026544.proj4_hrr_modsummary_overall;
	run;

proc sql;
create table whites as select hrr, total_knee as tot_w,  expected_knee3 as exp_w   from sh026544.proj4_hrr_modsummary_overall where race=1;
create table blacks as select hrrr, total_knee as tot_b, expected_knee3 as exp_b  from sh026544.proj4_hrr_modsummary_overall where race=2;
create table wb as select * from whites natural join blacks;

data wb_plot;
set wb;
smr3_b = tot_b/exp3_b;
smr3_w = tot_w/exp3_w;
run;

proc sgplot data=wb_plot;
scatter x= smr3_w y=smr3_b / markerattrs=graphdata2(symbol=circlefilled) transparency=0.8;
xaxis grid;
yaxis grid;
run;
title "Using Model 1 SMRs";

proc sgpanel data=tmp;
	panelby race;
	scatter x=Percent y=SMR1;
	*reg x=Percent y=SMR / degree=2;
	rowaxis label='SMR' type=log logstyle=logexpand values=(0.5 to 2 by 0.25);
	run;

title "Using Model 3 SMRs";

proc sgpanel data=tmp;
	panelby race;
	scatter x=Percent y=SMR3;
	*reg x=Percent y=SMR / degree=2;
	rowaxis label='SMR' type=log logstyle=logexpand values=(0.5 to 2 by 0.25);
	run;

/*
Expected rate from model
*/
title "Overall expected rate from Model 3, per 1000";
proc sql;
	create table tmp as 
		select 	sum(expected_knee3) as expected_total,
				sum(py) as tot_py 
		from sh026544.proj4_hrr_modsummary_overall;


data sh026544.proj4_expected_rate;
set tmp;
expected_rate = expected_total / tot_py * 1000;
run;
proc print data=sh026544.proj4_expected_rate;
run;

title "Expected rates by race, per 1000";
/* Expected rate by race */
proc sql;
	create table tmp2 as
		select	race, 
				sum(expected_knee3) as expected_total,
				sum(py) as tot_py
		from sh026544.proj4_hrr_modsummary_overall
		group by race;
data sh026544.proj4_expected_rate_race;
	set tmp2;
	rate = expected_total / tot_py * 1000;
run;
proc print data=sh026544.proj4_expected_rate_race;
run;


ods html off;
proc datasets library=work;
	delete tmp tmp2;
run;

proc contents data=sh026544.proj4_expected_rate_race;
run;

/* change wide to long format */
			/*
data long;
	set sh026544.proj4_hrr_modsummary;
	model = 'model1 ';
	expected = expected_knee1;
	output;
	model = 'model2 ';
	expected = expected_knee2;
	output;
	model = 'model2a';
	expected = expected_knee2a;
	output;
	model = 'model3 ';
	expected = expected_knee3;
	output;
	model = 'model3a';
	expected = expected_knee3a;
	output;
	model = 'model4 ';
	expected = expected_knee4;
	output;
	model = 'model4a';
	expected = expected_knee4a;
	output;
	drop expected_knee1 expected_knee2 expected_knee3 expected_knee4 expected_knee2a expected_knee3a expected_knee4a;
run;

data proj4_smr;
	set long;
	SMR = total_knee / expected;
	keep hrr model SMR;
run;
proc sort data= sh026544.proj4_smr;
	by hrr;
	run;
proc transpose data= sh026544.proj4_smr out=sh026544.proj4_smr (drop=_name_);
	by hrr;
	var SMR;
	id model;
	run;

data proj4_funnel_dat;
	set long;
	SMR = total_knee/expected;
	L95 = 1 - 1.96 * sqrt(1/expected);
	U95 = 1 + 1.96 * sqrt(1/expected);
	L99 = 1 - 2.58 * sqrt(1/expected);
	U99 = 1 + 2.58 * sqrt(1/expected);
	if SMR > U95 then
		result95 = 'high';
	else if SMR < L95 then
		result95 = 'low';
	else result95 = 'norm';
	if SMR > U99 then
		result99 = 'high';
	else if SMR < L99 then
		result99 = 'low';
	else result99 = 'norm';
run;


data funnel95;
	set proj4_funnel_dat;
	keep hrr model result95;
run;
proc transpose data=funnel95 out=sh026544.proj4_funnel95 (drop=_name_);
	by hrr;
	var result95;
	id model;
run;

data funnel99;
	set proj4_funnel_dat;
	keep hrr model result99;
run;
proc transpose data=funnel99 out=sh026544.proj4_funnel95 (drop=_name_);
	by hrr;
	var result99;
	id model;
run;

*/

