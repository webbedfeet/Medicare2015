

/* Model 2 + 20 comorbidities (Model 3)*/
proc genmod data= sh026544.proj4_hrr_end15_2011;
	class male race(ref='1')  agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat male race agecat male race agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers/ dist=poisson offset=ltime;
	output out=mod3_out pred=Predicted;
run;

	/*
	data sh026544.proj4_full_model_gee;
	set mod4_out;
	keep bene_id bene_enrollmt_ref_yr hrr tka Predicted LCL UCL;
	run;
	*/
	proc sql;
	create table proj4_hrr_obs as 
		select hrr,race,  sum(tka) as total_knee, sum(personyrs) as py from sh026544.proj4_hrr_end15_2011
			group by hrr,race;
	create table proj4_hrr_exp3 as
		select hrr,race, sum(Predicted*personyrs) as expected_knee3 from mod3_out
			group by hrr, race;
	create table sh026544.proj4_hrr_modsummary_2011 as
		select * from proj4_hrr_obs
			natural join proj4_hrr_exp3;

proc datasets library=work;
	delete  mod3_out ;
run;
ods text="Done with 2011";

/* Age, sex, race (Model 1)*/

/* Model 2 + 20 comorbidities (Model 3)*/
proc genmod data= sh026544.proj4_hrr_end15_2012;
	class male race(ref='1')  agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat male race agecat male race agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers/ dist=poisson offset=ltime;
	output out=mod3_out pred=Predicted;
run;


	/*
	data sh026544.proj4_full_model_gee;
	set mod4_out;
	keep bene_id bene_enrollmt_ref_yr hrr tka Predicted LCL UCL;
	run;
	*/
	proc sql;
	create table proj4_hrr_obs as 
		select hrr, sum(tka) as total_knee, sum(personyrs) as py from sh026544.proj4_hrr_end15_2012
			group by hrr;
	create table proj4_hrr_exp3 as
		select hrr, sum(Predicted*personyrs) as expected_knee3 from mod3_out
			group by hrr;
	create table sh026544.proj4_hrr_modsummary_2012 as
		select * from proj4_hrr_obs
			natural join proj4_hrr_exp3;

proc datasets library=work;
	delete mod3_out ;
run;

ods text="Done with 2012";


/* Model 2 + 20 comorbidities (Model 3)*/
proc genmod data= sh026544.proj4_hrr_end15_2013;
	class male race(ref='1')  agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat male race agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers/ dist=poisson offset=ltime;
	output out=mod3_out pred=Predicted;
run;

	proc sql;
	create table proj4_hrr_obs as 
		select hrr, sum(tka) as total_knee from sh026544.proj4_hrr_end15_2013
			group by hrr;
	create table proj4_hrr_exp3 as
		select hrr, sum(Predicted*personyrs) as expected_knee3 from mod3_out
			group by hrr;
	create table sh026544.proj4_hrr_modsummary_2013 as
		select * from proj4_hrr_obs
			natural join proj4_hrr_exp3;

proc datasets library=work;
	delete mod3_out;
run;
ods text="Done with 2013";


/* Model 2 + 20 comorbidities (Model 3)*/
proc genmod data= sh026544.proj4_hrr_end15_2014;
	class male race(ref='1')  agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat male race agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers/ dist=poisson offset=ltime;
	output out=mod3_out pred=Predicted;
run;

	proc sql;
	create table proj4_hrr_obs as 
		select hrr, sum(tka) as total_knee from sh026544.proj4_hrr_end15_2014
			group by hrr;
	create table proj4_hrr_exp3 as
		select hrr, sum(Predicted*personyrs) as expected_knee3 from mod3_out
			group by hrr;
	create table sh026544.proj4_hrr_modsummary_2014 as
		select * from proj4_hrr_obs
			natural join proj4_hrr_exp3;
proc datasets library=work;
	delete mod3_out;
run;
ods text="Done with 2014";

/* Model 2 + 20 comorbidities (Model 3)*/
proc genmod data= sh026544.proj4_hrr_end15_2015;
	class male race(ref='1')  agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat male race agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers/ dist=poisson offset=ltime;
	output out=mod3_out pred=Predicted;
run;

	proc sql;
	create table proj4_hrr_obs as 
		select hrr, sum(tka) as total_knee from sh026544.proj4_hrr_end15_2015
			group by hrr;
	create table proj4_hrr_exp3 as
		select hrr, sum(Predicted*personyrs) as expected_knee3 from mod3_out
			group by hrr;
	create table sh026544.proj4_hrr_modsummary_2015 as
		select * from proj4_hrr_obs
			natural join proj4_hrr_exp3;
proc datasets library=work;
	delete mod3_out ;
run;
ods text="Done with 2015";

title "Concatenating datasets";

data sh026544.proj4_hrr_modsummary_overall;
	set sh026544.proj4_hrr_modsummary_2011
		sh026544.proj4_hrr_modsummary_2012
		sh026544.proj4_hrr_modsummary_2013
		sh026544.proj4_hrr_modsummary_2014
		sh026544.proj4_hrr_modsummary_2015;
run;

proc sql;
	create table proj4_overall_summary as 
		select hrr, sum(total_knee) as total_knee, sum(expected_knee3) as expected_knee3 from sh026544.proj4_hrr_modsummary_overall
		group by hrr;

data proj4_overall_summary;
set proj4_overall_summary;
SMR = total_knee / expected_knee3;
run;

title 'getting race % by hrr for 2013';

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

proc sql;
	create table tmp as 
	select * from proj4_overall_summary natural join sh026544.proj4_race;

proc sgplot data=proj4_overall_summary;
density SMR;
xaxis type=log;
run;

ods pdf dpi=600 ;
title "SMR by Race";
proc sgpanel data=tmp;
	panelby race;
	scatter x=Percent y=SMR;
	*reg x=Percent y=SMR / degree=2;
	rowaxis label='SMR' type=log logstyle=logexpand values=(0.5 to 2 by 0.25);
	run;
ods pdf close;


proc means data=proj4_overall_summary;
	var SMR;
run;

