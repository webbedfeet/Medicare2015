/* Obtaining a sub-sample of the data for actual operational testing */

/*
proc surveyselect data=sh026544.project4_hrr_end15 out=sh026544.project4_hrr_end15_sampled noprint method=srs sampsize=500000 seed=5424;
*cluster bene_id;
run; /*works, but not cluster sampling */

proc sql noprint;
	* This grabs the unique patient ids*
	create table sh026544.tmp_id as
		select distinct bene_id from sh026544.project4_hrr_end15;
run;

proc surveyselect data=sh026544.tmp_id out=sh026544.tmp_sampled_id method=srs seed=745278 sampsize=500000 noprint; /* Sampling the patient ids */
run;

proc sql noprint; /* Create cluster sample by patient id */
	create table sh026544.proj4_hrr_end15_sample as
		select A.*, B.* from
			sh026544.tmp_sampled_id A left join sh026544.project4_hrr_end15 B
			on A.bene_id = B.bene_id
		order by bene_enrollmt_ref_yr;

data sh026544.proj4_hrr_end15_sample;
	set sh026544.proj4_hrr_end15_sample;
	keep acutemi afib age_at_end_ref_yr agecat male race bene_enrollmt_ref_yr bene_id breast_past chf ckd colorectal_past copd dementia depress diab endometrial_past
		hememalignancy hiv ihd liver ltime lung_past prostate_past pvd stroke ulcers koa_visits koa kneesymptom_visits kneesymptoms allkneevisits knee_patient
		op_visits dead personyrs tka hrr obese_wtperc physjob_t_wtperc smoking_wtperc mcare_adv_wtperc ortho_per_100000 poor zscore rural;
run;

data sh026544.proj4_hrr_end15_sample;
	set sh026544.proj4_hrr_end15_sample;
	ltime = log(personyrs);
run;

/********************************************
 * Done with cluster sampling
 * Now for verification of data sampling
 *********************************************/
proc contents data=sh026544.proj4_hrr_end15_sample;
run;

proc sql;
	create table sh026544.tmp_hrrfreq1 as
		select hrr, count(distinct bene_id) as number_pt from sh026544.proj4_hrr_end15_sample
			group by hrr;

proc sql;
	create table sh026544.tmp_hrrfreq2 as
		select hrr, count(distinct bene_id) as number_pt_total from sh026544.project4_hrr_end15
			group by hrr;

proc sql;
	select A.*, B.* from
		sh026544.tmp_hrrfreq1 A left join sh026544.tmp_hrrfreq2 B
		on A.hrr=B.hrr;
