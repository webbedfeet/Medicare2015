/*
proc print data=sh026544.proj4_mod3_white_2011 (obs=10);run;

data proj4_mod3_tka;
set sh026544.proj4_mod3_white_2011
	sh026544.proj4_mod3_white_2012
	sh026544.proj4_mod3_white_2013
	sh026544.proj4_mod3_white_2014
	sh026544.proj4_mod3_white_2015;
	keep bene_id bene_enrollmt_ref_yr hrr tka;
run;

data proj4_mod3_probs ;
set sh026544.proj4_mod3_white_2011
	sh026544.proj4_mod3_white_2012
	sh026544.proj4_mod3_white_2013
	sh026544.proj4_mod3_white_2014
	sh026544.proj4_mod3_white_2015;
keep bene_id Predicted;
run;

proc sql;
create table avgprobs as
	select bene_id, mean(Predicted) as probs from proj4_mod3_probs
	group by bene_id;

proc rank data=avgprobs out=sh026544.proj4_quartiles groups=4;
var probs;
ranks quarts;
run;

proc sql;
select quarts, mean(probs) as avg_probs , min(probs) as mins, max(probs) as maxs from sh026544.proj4_quartiles group by quarts;

proc sql;
create table tmp as
	select * from proj4_mod3_tka a left join quartiles b on a.bene_id=b.bene_id;
proc sql;select quarts,sum(tka) as tka, sum(probs) as expected from tmp group by quarts;


proc sql;
create table with_quarts as
	select * from sh026544.proj4_hrr_end15_white a left join quartiles b on a.bene_id=b.bene_id;

data sh026544.proj4_hrr_white_q1 sh026544.proj4_hrr_white_q2 sh026544.proj4_hrr_white_q3 sh026544.proj4_hrr_white_q4;
set with_quarts;
ltime = log(personyrs);
if (quarts=0) then output sh026544.proj4_hrr_white_q1;
if (quarts=1) then output sh026544.proj4_hrr_white_q2;
if (quarts=2) then output sh026544.proj4_hrr_white_q3;
if (quarts=3) then output sh026544.proj4_hrr_white_q4;
run;
*/

%macro model3(q);
/* Model 2 + 20 comorbidities (Model 3)*/
ods output ParameterEstimates=sh026544.proj4_mod3_params_&q; /* save parameter estimates */

proc hpgenselect data= sh026544.proj4_hrr_white_&q;
title "Running model3, &q";
	class male agecat knee_patient ;
	model tka = agecat male agecat*male knee_patient obese_wtperc physjob_t_wtperc smoking_wtperc 
		acutemi afib breast_past chf ckd colorectal_past copd dementia 
		depress diab endometrial_past hememalignancy hiv ihd liver 
		lung_past prostate_past pvd stroke ulcers poor zscore/  dist=poisson offset=ltime; /* added zscore and poor to model 3*/
	id bene_id;
	output out=mod3_&q pred=Predicted;
run;
proc sql;
	create table sh026544.proj4_mod3_summary_&q as
	select a.bene_id, a.hrr, a.tka, b.Predicted from mod3_&q as b natural join sh026544.proj4_hrr_white_&q as a where a.bene_id = b.bene_id;
%mend model3;

%model3(q1);
%model3(q2);
%model3(q3);
%model3(q4);

%macro aggregate(q);
proc sql;
create table sh026544.proj4_mod3_hrr_&q as
	select hrr, sum(tka) as tka, sum(Predicted) as exp3 from sh026544.proj4_mod3_summary_&q group by hrr;
%mend;
%aggregate(q1);
%aggregate(q2);
%aggregate(q3);
%aggregate(q4);
