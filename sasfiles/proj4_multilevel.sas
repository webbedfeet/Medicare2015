/* Program for setting up and performing multilevel modeling for the Medicare data */
/* Abhijit Dasgupta */

/* Cluster sampling is in proj4_cluster_sampling */

	/*******************************************************************************************************/

options cmplib=work.cmplib;

data proj4_hrr_end15;
	set sh026544.project4_hrr_end15;
	ltime = log(personyrs);
run;


/*   GEE modeling */

/* Age, sex, race (Model 1)*/
proc genmod data=proj4_hrr_end15;
	class male race(ref='1') bene_id hrr agecat;
	model tka = agecat*male race*male / dist=poisson offset=ltime;
	repeated subject=bene_id(hrr)/ corr=exch corrw;
	output out=mod1_out pred=Predicted;
run;

/* Model 1 + kneepatient + hrr level (Model 2) */
proc genmod data=proj4_hrr_end15;
	class male race(ref='1') bene_id hrr agecat knee_patient;
	model tka = agecat*male race*male knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc / dist=poisson offset=ltime;
	repeated subject=bene_id(hrr)/ corr=exch corrw;
	output out=mod2_out pred=Predicted;
run;

/* Model 1 + koa + kneesymptoms + ... (Model 2a)*/
proc genmod data=proj4_hrr_end15;
	class male race(ref='1') bene_id hrr agecat knee_patient;
	model tka = agecat*male race*male kneesymptoms obese_wtperc physjob_t_wtperc smoking_wtperc / dist=poisson offset=ltime;
	repeated subject=bene_id(hrr)/ corr=exch corrw;
	output out=mod2a_out pred=Predicted;
run;

/* Model 2 + 20 comorbidities (Model 3)*/
proc genmod data=proj4_hrr_end15;
	class male race(ref='1') bene_id hrr agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers/ dist=poisson offset=ltime;
	repeated subject=bene_id(hrr)/ corr=exch corrw;
	output out=mod3_out pred=Predicted;
run;

/* Model 2a + 20 comorbs (Model 3a) */
proc genmod data=proj4_hrr_end15;
	class male race(ref='1') bene_id hrr agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat*male race*male bene_enrollmt_ref_yr kneesymptoms obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers/ dist=poisson offset=ltime;
	repeated subject=bene_id(hrr)/ corr=exch corrw;
	output out=mod3a_out pred=Predicted;
run;

/* Model 3 + poor + ...  (Model 4)*/
proc genmod data=proj4_hrr_end15;
	class male race(ref='1') bene_id hrr agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers 
		poor zscore rural op_visits mcare_adv_wtperc ortho_per_100000/ dist=poisson offset=ltime;
	repeated subject=bene_id(hrr)/ corr=exch corrw;
	output out=mod4_out predicted=Predicted ucl=UCL lcl=LCL;
run;

/* Model 3a + poor + ... (Model 4a) */
proc genmod data=proj4_hrr_end15;
	class male race(ref='1') bene_id hrr agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat*male race*male bene_enrollmt_ref_yr kneesymptoms obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers/ dist=poisson offset=ltime;
	repeated subject=bene_id(hrr)/ corr=exch corrw;
	output out=mod4a_out pred=Predicted;

	/*
	data sh026544.proj4_full_model_gee;
	set mod4_out;
	keep bene_id bene_enrollmt_ref_yr hrr tka Predicted LCL UCL;
	run;
	*/
/*
PROC SQL;
	create table proj4_hrr_obs as 
		select hrr, sum(tka)/sum(personyrs)*100000 as total_knee from proj4_hrr_end15
			group by hrr;
	create table proj4_hrr_exp1 as
		select hrr, sum(Predicted*personyrs)/sum(personyrs)*100000 as expected_knee1 from mod1_out
			group by hrr;
	create table proj4_hrr_exp2 as
		select hrr, sum(Predicted*personyrs)/sum(personyrs)*100000 as expected_knee2 from mod2_out
			group by hrr;
	create table proj4_hrr_exp3 as
		select hrr, sum(Predicted*personyrs)/sum(personyrs)*100000 as expected_knee3 from mod3_out
			group by hrr;
	create table proj4_hrr_exp4 as 
		select hrr, sum(Predicted*personyrs)/sum(personyrs)*100000 as expected_knee4 from mod4_out
			group by hrr;
	create table proj4_hrr_exp2a as
		select hrr, sum(Predicted*personyrs)/sum(personyrs)*100000 as expected_knee2a from mod2a_out
			group by hrr;
	create table proj4_hrr_exp3a as
		select hrr, sum(Predicted*personyrs)/sum(personyrs)*100000 as expected_knee3a from mod3a_out
			group by hrr;
	create table proj4_hrr_exp4a as 
		select hrr, sum(Predicted*personyrs)/sum(personyrs)*100000 as expected_knee4a from mod4a_out
			group by hrr;
	create table sh026544.proj4_hrr_modsummary as
		select * from sh026544.proj4_hrr_obs
			natural join proj4_hrr_exp1
			natural join proj4_hrr_exp2
			natural join proj4_hrr_exp3
			natural join proj4_hrr_exp4
			natural join proj4_hrr_exp2a
			natural join proj4_hrr_exp3a
			natural join proj4_hrr_exp4a;
*/
PROC SQL;
	create table proj4_hrr_obs as 
		select hrr, sum(tka) as total_knee from proj4_hrr_end15
			group by hrr;
	create table proj4_hrr_exp1 as
		select hrr, sum(Predicted*personyrs) as expected_knee1 from mod1_out
			group by hrr;
	create table proj4_hrr_exp2 as
		select hrr, sum(Predicted*personyrs) as expected_knee2 from mod2_out
			group by hrr;
	create table proj4_hrr_exp3 as
		select hrr, sum(Predicted*personyrs) as expected_knee3 from mod3_out
			group by hrr;
	create table proj4_hrr_exp4 as 
		select hrr, sum(Predicted*personyrs) as expected_knee4 from mod4_out
			group by hrr;
	create table proj4_hrr_exp2a as
		select hrr, sum(Predicted*personyrs) as expected_knee2a from mod2a_out
			group by hrr;
	create table proj4_hrr_exp3a as
		select hrr, sum(Predicted*personyrs) as expected_knee3a from mod3a_out
			group by hrr;
	create table proj4_hrr_exp4a as 
		select hrr, sum(Predicted*personyrs) as expected_knee4a from mod4a_out
			group by hrr;
	create table sh026544.proj4_hrr_modsummary as
		select * from proj4_hrr_obs
			natural join proj4_hrr_exp1
			natural join proj4_hrr_exp2
			natural join proj4_hrr_exp3
			natural join proj4_hrr_exp4
			natural join proj4_hrr_exp2a
			natural join proj4_hrr_exp3a
			natural join proj4_hrr_exp4a;

	/*
	proc sgplot data=sh026544.proj4_hrr_modsummary;
	loess x=expected_knee1 y=total_knee /lineattrs=(color=green);
	loess x=expected_knee2 y=total_knee/ lineattrs=(color=blue);
	loess x=expected_knee3 y=total_knee/ lineattrs=(color=orange);
	loess x = expected_knee4 y=total_knee/ lineattrs=(color=red);
	lineparm x=0 y= 0 slope=1 / lineattrs=(color=green);
	run;
	*/
/*
data sh026544.proj4_hrr_modsummary;
	set sh026544.proj4_hrr_modsummary;
	diff1 = (total_knee-expected_knee1);
	diff2 = (total_knee-expected_knee2);
	diff3 = (total_knee-expected_knee3);
	diff4 = (total_knee-expected_knee4);
	diff2a = (total_knee-expected_knee2a);
	diff3a = (total_knee-expected_knee3a);
	diff4a = (total_knee-expected_knee4a);
run;
*/
/*
proc means data=sh026544.proj4_hrr_modsummary var;
vars total_knee expected_knee1 expected_knee2 expected_knee3 expected_knee4;
run;

proc sgplot data=sh026544.proj4_hrr_modsummary;
scatter x=total_knee y=expected_knee4;
loess x=total_knee y=expected_knee4;
lineparm x=0 y=0 slope=1;
run;
*/

/***************************************************************************************************************
Try using GLMs by year, and see how things compare with mod4
/***************************************************************************************************************/

/*
proc genmod data=proj4_hrr_end15;
class male race bene_id hrr agecat knee_patient bene_enrollmt_ref_yr;
model tka = agecat*male race*male knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
	acutemi afib breast_past chf ckd colorectal_past copd dementia 
	depress diab endometrial_past hememalignancy hiv ihd liver 
	lung_past prostate_past pvd stroke ulcers 
	poor zscore rural op_visits mcare_adv_wtperc ortho_per_100000/ dist=poisson offset=ltime;
by bene_enrollmt_ref_yr;
output out=glm_model predicted=Predicted ucl=UCL lcl=LCL;
run;

data sh026544.proj4_full_model_glm;
set glm_model;
keep bene_id bene_enrollmt_ref_yr hrr tka Predicted LCL UCL;
run;

proc sql;
create table sh026544.gee_glm_compare as
	select b.bene_id, b.bene_enrollmt_ref_yr, b.hrr, b.tka, b.Predicted as pred_glm, b.LCL as lcl_glm, b.UCL as ucl_glm,
		a.Predicted as pred_gee, a.LCL as lcl_gee, a.UCL as ucl_gee
	from sh026544.proj4_full_model_glm b,
		sh026544.proj4_full_model_gee a
	where a.bene_id=b.bene_id and a.bene_enrollmt_ref_yr = b.bene_enrollmt_ref_yr
	order by bene_enrollmt_ref_yr;

proc sql;
create table obs_exp as
	select hrr,count(*) as N, 
		sum(tka) as Observed, 
		sum(pred_gee) as Expected_gee,
		sum(pred_glm) as Expected_glm
	from sh026544.gee_glm_compare
	group by hrr
	order by hrr;
proc print data=obs_exp;
run;

/* Some tests
proc sgplot data=obs_exp;
scatter x=Expected_glm y=Expected_gee;
run;
proc corr data=obs_exp;
run;
*/

/* change wide to long format */
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
proc sort data=proj4_smr;
	by hrr;
	run;
proc transpose data=proj4_smr out=sh026544.proj4_smr (drop=_name_);
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



