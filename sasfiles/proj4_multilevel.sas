/* 
Program for setting up and performing multilevel modeling for the Mediare data

Abhijit Dasgupta

Obtaining a sub-sample of the data for actual operational testing
*/

/*
proc surveyselect data = sh026544.project5_hrr_end15 out=sh026544.project4_hrr_end15_sampled noprint method=srs sampsize=500000 seed=5424;
	*cluster bene_id;
run; /* works, but not cluster sampling */

proc sql noprint;
	create table sh026544.tmp_id as
	select distinct bene_id from sh026544.project4_hrr_end15;
run;

proc surveyselect data=s026544.tmp_id out=sh026544.tmp_sampled_id method=srs seed=745278 sampsize=500000 noprint; /* Sampling the patient IDs */
run;

proc sql noprint; /* Create cluster sample by patient id */
	create table sh026544.proj4_hrr_end15_sample as
		select A.* B.* from 
			sh026544.tmp_sampled_id A left join sh026544.project4_hrr_end15 B
			on A.bene_id = B.bene_id
			order by bene_id, bene_enrollmt_ref_yr;
run;

data sh026544.proj4_hrr_end15_sample;
	set sh026544.proj4_hrr_end15_sample;
	keep acutemi afib age_at_end ref_yr agecat male race bene_enrollmt_ref_yr bene_id breast_past chf ckd colorectal_past copd dementia depress diab endometrial hememalignancy hiv ihd liver ltime lung_past prostate_past pvd stroke ulcers koa_visits koa kneesymptom_visits kneesymptoms allkneevisits kenn_patient op_visits dead personyrs tka hrr obese_wtperc physjob_t_wtperc smoking_wtperc mcare_adv_wtperc ortho_per_100000 poor zscore rural;
run;

data sh026544.proj4_hrr_end15_sample;
	set sh026544.proj4_hrr_end15_sample;
	ltime = log(personyrs);
run;

/*
* Verifying data sampling
*/

proc sql;
	create table sh026544.tmp_hrrfreq1 as
	select hrr, count(distinct bene_id) as number_pt from sh026544.proj4_hrr_end15_sample
	group by hrr;
run;

proc sql;
	create table sh026544.tmp_hrrfreq2 as
	select hrr, count(distinct bene_id) as number_pt_total from sho026544.project4_hrr_end15
	group by hrr;
run;

proc sql;
	select A.* B.* from 
	sh026544.tmp_hrrfreq1 A left join sh026544.tmp_hrrfreq2 B 
	on A.hrr=B.hrr;
run;

/***********************************************************************/

/* Model 1: Age, race and sex */

/* TODO: There are some observations with missing personyrs */

proc means data=sh026544.proj4_hrr_end15_sample nmiss n;
	var personyrs;
run; /* roughly 1% */

options cmplib-work.cmplib;

/*
proc glimmix data=sh026544.proj4_hrr_end15_sample noclprint;
	class male race bene_id hrr agecat;
	model tka=agecat / dist=poisson DDFM=betwithin;
	random int / subject=bene_id type=cs;
run;

proc gee data=sh026544.proj4_hrr_end15_sample;
	class male race(ref='1') bene_id hrr agecat bene_enrollmt_ref_yr;
	model tka = agecat race male bene_enrollmt_ref_yr / dist=poisson offset=ltime;
	output out=sh026544.proj4_hrr_mod1_out pred=Predicted;
	repeated subject=bene_id(hrr);
run;
*/

/* EDA */

/* GEE modeling */
proc genmod data=sh026544.proj4_hrr_end15_sample;
	class male race bene_id hrr agecat;
	model tka = agecat*male race*male /dist=poisson offset=ltime;
	repeated subject=bene_id(hrr) / corr=exch corrw;
	output out=sh026544.proj4_hrr_mod1_out pred=Predicted;
run;

proc genmod data=sh026544.proj4_hrr_end15_sample;
	class male race bene_id hrr agecat knee_patient;
	model tka = agecat*male race*male knee_patient obese_wtperc physjob_t_wtperc smoking_wt_perc /dist=poisson offset=ltime;
	repeated subject=bene_id(hrr) / corr=exch corrw;
	output out=sh026544.proj4_hrr_mod2_out pred=Predicted;
run;

proc genmod data=sh026544.proj4_hrr_end15_sample;
	class male race bene_id hrr agecat knee_patient bene_enrollmt_ref_yr;
	model tka = agecat*male race*male bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc acutemi*bene_enrollmt_ref_yr afib*bene_enrollmt_ref_yr breast_past chf ckd*bene_enrollmt_ref_yr colorectal_past copd dementia depress*bene_enrollmt_ref_yr diab*bene_enrollmt_ref_yr endometrial_past hememalignancy hiv ihd liver lung_past prostate_past pvd stroke ulcers*bene_enrollmt_ref_yr /dist=poisson offset=ltime;
	repeated subject=bene_id(hrr) / corr=exch corrw;
	output out=sh026544.proj4_hrr_mod3_out pred=Predicted;
run;


proc genmod data=sh026544.proj4_hrr_end15_sample;
	class male race bene_id hrr agecat;
	model tka = agecat*male race*male  bene_enrollmt_ref_yr knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc acutemi*bene_enrollmt_ref_yr afib*bene_enrollmt_ref_yr breast_past chf ckd*bene_enrollmt_ref_yr colorectal_past copd dementia depress*bene_enrollmt_ref_yr diab*bene_enrollmt_ref_yr endometrial_past hememalignancy hiv ihd liver lung_past prostate_past pvd stroke ulcers*bene_enrollmt_ref_yr poor*bene_enrollmt_ref_yr zscore rural op_visits mcare_adv_wtperc ortho_per_100000/dist=poisson offset=ltime;
	repeated subject=bene_id(hrr) / corr=exch corrw;
	output out=sh026544.proj4_hrr_mod4_out pred=Predicted;
run;

proc sql;
	create table sh026544.proj4_hrr_obs as
	select hrr, sum(tka)/sum(personyrs)*100000 as total_knee from sh026544.proj4_hrr_end15_sample
	group by hrr;
	create table sh026544.proj4_hrr_exp1 as
	select hrr, sum(Predicted*personyrs)/sum(personyrs)*100000 as expected_knee1 from sh026544.proj4_hrr_mod1_out
	group by hrr;
	create table sh026544.proj4_hrr_exp2 as
	select hrr, sum(Predicted*personyrs)/sum(personyrs)*100000 as expected_knee2 from sh026544.proj4_hrr_mod2_out
	group by hrr;
	create table sh026544.proj4_hrr_exp3 as
	select hrr, sum(Predicted*personyrs)/sum(personyrs)*100000 as expected_knee3 from sh026544.proj4_hrr_mod3_out
	group by hrr;
	create table sh026544.proj4_hrr_exp4 as
	select hrr, sum(Predicted*personyrs)/sum(personyrs)*100000 as expected_knee4 from sh026544.proj4_hrr_mod4_out
	group by hrr;
create table sh026544.proj4_hrr_modsummary as
	select * from sh026544.proj_hrr_obs
		natural join sh026544.proj4_hrr_exp1
		natural join sh026544.proj4_hrr_exp2
		natural join sh026544.proj4_hrr_exp3
		natural join sh026544.proj4_hrr_exp4;
run;

proc sgplot data=sh026544.proj4_hrr_modsummary;
	loess x=expected_knee1 y=total_knee /lineattrs=(color=green);
	loess x=expected_knee2 y=total_knee /lineattrs=(color=blue);
	loess x=expected_knee3 y=total_knee /lineattrs=(color=orange);
	loess x=expected_knee4 y=total_knee /lineattrs=(color=red);
	lineparm x=0 y=0 slope=1 / lineattrs=(color=green);
run;

data sh026544.proj4_hrr_modsummary;
	set sh026544.proj4_hrr_modsummary;
	diff1=(total_knee - expected_knee1);
	diff2=(total_knee - expected_knee2);
	diff3=(total_knee - expected_knee3);
	diff4=(total_knee - expected_knee4);
run;

proc means data=sh026544.proj4_hrr_modsummary var;
	vars total_knee expected_knee1 expected_knee2 expected_knee3 expected_knee4;
run;

proc sgplot data=sh026544.proj4_hrr_modsummary;
	scatter x=total_knee y=expected_knee4;
	loess x=total_knee y=expected_knee4;
	lineparm x=0 y=0 slope=1;
run;

proc sql;
	select(mean((total_knee-expected_knee)*(total_knee-expected_knee)) as MSE from sh026544.proj4_hrr_obs_exp; /* can't find generating code for this data set */
run;

proc sgplot data=sh026544.proj4_hrr_obs_exp;
	scatter x=total_knee y=expected_knee;
	loess x=total_knee y=expected_knee / lineattrs=(color=red);
	lineparm x=0 y=0 slope=1;
	xaxis grid; yaxis grid;
run;




