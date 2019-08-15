/* Create race-specific data sets */
/*
proc sql;
create table sh026544.proj4_hrr_end15_white as
	select * from sh026544.project4_hrr_end15
	where race=1;
create table sh026544.proj4_hrr_end15_black as
	select * from sh026544.project4_hrr_end15
	where race=2;
create table sh026544.proj4_hrr_end15_hispanic as
	select * from sh026544.project4_hrr_end15
	where race=3;
*/

/* Split into yearly datasets*/
/*
%macro create_data(race);
	%do i=2011 %to 2015;
		%let dataset_&i = %sysfunc(catx(%str(_), &race, &i));
	%end;
	data sh026544.proj4_hrr_end15_&dataset_2011 sh026544.proj4_hrr_end15_&dataset_2012 sh026544.proj4_hrr_end15_&dataset_2013 
		sh026544.proj4_hrr_end15_&dataset_2014 sh026544.proj4_hrr_end15_&dataset_2015;
	set sh026544.proj4_hrr_end15_&race;
	ltime = log(personyrs);
	if (bene_enrollmt_ref_yr = 2011) then output sh026544.proj4_hrr_end15_&dataset_2011;
	if (bene_enrollmt_ref_yr = 2012) then output sh026544.proj4_hrr_end15_&dataset_2012;
	if (bene_enrollmt_ref_yr = 2013) then output sh026544.proj4_hrr_end15_&dataset_2013;
	if (bene_enrollmt_ref_yr = 2014) then output sh026544.proj4_hrr_end15_&dataset_2014;
	if (bene_enrollmt_ref_yr = 2015) then output sh026544.proj4_hrr_end15_&dataset_2015;
	run;
%mend create_data;

%create_data(white);
%create_data(black);
%create_data(hispanic);
*/
/*******************************************************************************************
/* Macros for models 1, 2, 3
/*******************************************************************************************/

%macro model1(race, yr);
%let dataset=%sysfunc(catx(%str(_),&race,&yr));
proc hpgenselect data= sh026544.proj4_hrr_end15_&dataset;
title "Running model1, &dataset";
	class male agecat;
	model tka = agecat male  agecat*male  / dist=poisson offset=ltime;
	id bene_id;
	output out=mod1_&dataset predicted=Predicted;
run;
proc sql;
	create table mod1_&dataset as
	select * from mod1_&dataset as a natural join sh026544.proj4_hrr_end15_&dataset as b where a.bene_id = b.bene_id;
%mend model1;


%macro model2(race, yr);
%let dataset=%sysfunc(catx(%str(_),&race,&yr));
/* Model 1 + kneepatient + hrr level (Model 2) */
proc hpgenselect data= sh026544.proj4_hrr_end15_&dataset;
title "Running model2, &dataset";
	class male agecat knee_patient ;
	model tka = agecat male  agecat*male  knee_patient 
		obese_wtperc physjob_t_wtperc smoking_wtperc /  dist=poisson offset=ltime;
	id bene_id;
	output out=mod2_&dataset predicted=Predicted;
run;
proc sql;
	create table mod2_&dataset as
	select * from mod2_&dataset as a natural join sh026544.proj4_hrr_end15_&dataset as b where a.bene_id = b.bene_id;
%mend model2;

%macro model3(race, yr);
%let dataset=%sysfunc(catx(%str(_),&race,&yr));
/* Model 2 + 20 comorbidities (Model 3)*/
ods output ParameterEstimates=mod3_params_&dataset; /* save parameter estimates */

proc hpgenselect data= sh026544.proj4_hrr_end15_&dataset;
title "Running model3, &dataset";
	class male agecat knee_patient ;
	model tka = agecat male agecat*male knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers poor zscore/  dist=poisson offset=ltime; /* added zscore and poor to model 3*/
	id bene_id;
	output out=mod3_&dataset pred=Predicted;
run;
/*proc sql;
	create table mod3_&dataset as
	select * from mod3_&dataset as a natural join sh026544.proj4_hrr_end15_&dataset as b where a.bene_id = b.bene_id;*/
%mend model3;
/* Next bit is from the web (https://communities.sas.com/t5/SAS-Programming/sas-loop-over-datasets/td-p/492696)

%macro do_all(name_list=);
%local i next_name;
%do i=1 %to %sysfunc(countw(&name_list));
	%let next_name = %scan(&name_list, &i);
	%mymacro(&next_name);
%end;
%mend do_all;
 %do_all(name_list=a b c d e f);
*/




data sh026544.mod3_params;
set mod3_params_white_2011
	mod3_params_white_2012
	mod3_params_white_2013
	mod3_params_white_2014
	mod3_params_white_2015;
run;

data smr_white;
set sh026544.proj4_smr_white;
keep hrr total_knee exp3 smr3 race;
run;

proc print data=sh026544.proj4_smr_white; run;

%macro loop_through(race_list=, yr_list=);
%local i j next_race next_yr;
%do i=1 %to %sysfunc(countw(&race_list));
	%do j= 1 %to %sysfunc(countw(&yr_list));
		%let next_race = %scan(&race_list, &i);
		%let next_yr = %scan(&yr_list, &j);
		%put &next_race;%put &next_yr;
/*		%model1(&next_race, &next_yr);
		%model2(&next_race, &next_yr);*/
		%model3(&next_race, &next_yr);
	%end;
%end;
%mend loop_through;

/*******************************************************************************************
/* Now let's run through the datasets and compute the models
/*******************************************************************************************/
%loop_through(race_list=white, yr_list=2011 2012 2013 2014 2015);

data sh026544.proj4_mod3_white_2011;
set mod3_white_2011 ;
run;
data sh026544.proj4_mod3_white_2012;
set mod3_white_2012 ;
run;
data sh026544.proj4_mod3_white_2013;
set mod3_white_2013 ;
run;
data sh026544.proj4_mod3_white_2014;
set mod3_white_2014 ;
run;
data sh026544.proj4_mod3_white_2015;
set mod3_white_2015 ;
run;

proc print data=sh026544.proj4_mod3_white_2011 (obs= 10); run;

%loop_through(race_list=white black hispanic, yr_list = 2011 2012 2013 2014 2015);

/* Aggregating data */

%macro aggregate_model(race, yr);
%let dataset = %sysfunc(catx(%str(_), &race, &yr));
%let datasetout = &dataset;
%if &race=hispanic %then %let datasetout = %sysfunc(catx(%str(_), hisp,&yr));
proc sql;
	create table proj4_hrr_obs as 
		select hrr,race,bene_enrollmt_ref_yr, sum(tka) as total_knee, sum(personyrs) as py from sh026544.proj4_hrr_end15_&dataset
			group by hrr, race, bene_enrollmt_ref_yr;
	create table proj4_hrr_exp1 as
		select hrr, race,bene_enrollmt_ref_yr,sum(Predicted*personyrs) as expected_knee1 from mod1_&dataset
			group by hrr, race, bene_enrollmt_ref_yr;
	create table proj4_hrr_exp2 as
		select hrr, race,bene_enrollmt_ref_yr,sum(Predicted*personyrs) as expected_knee2 from mod2_&dataset
			group by hrr, race, bene_enrollmt_ref_yr;
	create table proj4_hrr_exp3 as
		select hrr, race,bene_enrollmt_ref_yr, sum(Predicted*personyrs) as expected_knee3 from mod3_&dataset
			group by hrr, race, bene_enrollmt_ref_yr;
	create table sh026544.proj4_hrr_modsummary_&datasetout as
		select * from proj4_hrr_obs
			natural join proj4_hrr_exp1
			natural join proj4_hrr_exp2
			natural join proj4_hrr_exp3;
%mend aggregate_model;
%macro aggregate_models(race_list=, yr_list=);
%local i j next_race next_yr;
%do i=1 %to %sysfunc(countw(&race_list));
	%do j= 1 %to %sysfunc(countw(&yr_list));
		%let next_race = %scan(&race_list, &i);
		%let next_yr = %scan(&yr_list, &j);
		%aggregate_model(&next_race, &next_yr);
	%end;
%end;
%mend aggregate_datasets;

%aggregate_models(race_list=white black hispanic, yr_list = 2011 2012 2013 2014 2015);
%aggregate_models(race_list=hispanic, yr_list=2011 2012 2013 2014 2015);


/* Person years aggregation */

proc sql;
create table sh026544.proj4_py as 
select hrr, race, bene_enrollmt_ref_yr, sum(personyrs) as py from sh026544.project4_hrr_end15
	group by hrr, race, bene_enrollmt_ref_yr;

/* HRR-level variables */
proc sql;
create table sh026544.proj4_hrrlevel as
	select distinct hrr, race,mean(op_visits) as mean_op, median(op_visits) as median_op, mean(rural)*100 as rural_perc, mcare_adv_wtperc, ortho_per_100000,
		mean(koa_visits) as mean_koa_visits, median(koa_visits) as median_koa_visits, mean(koa) as frac_koa 
	from sh026544.project4_hrr_end15
	group by hrr, race;
proc sgplot data=sh026544.proj4_hrrlevel;
histogram frac_koa;
run;

proc print data=sh026544.project4_hrr_end15 (obs=20);run;

%macro check_data(race_list=, yr_list=);
%local i j next_race next_yr;
%do i=1 %to %sysfunc(countw(&race_list));
	%do j=1 %to %sysfunc(countw(&yr_list));
		%let race = %scan(&race_list, &i);
		%let yr = %scan(&yr_list, &j);
		%let dataset = %sysfunc(catx(%str(_), &race, &yr));
		title "Contents for &dataset";
		proc contents data=sh026544.proj4_hrr_modsummary_&dataset; run;
	%end;
%end;
%mend check_data;

%check_data(race_list = white black hispanic, yr_list = 2011 2012 2013 2014 2015);

data sh026544.proj4_mod3_white;
set sh026544.proj4_mod3_white_2011
    sh026544.proj4_mod3_white_2012
	sh026544.proj4_mod3_white_2013
	sh026544.proj4_mod3_white_2014
	sh026544.proj4_mod3_white_2015;
run;

