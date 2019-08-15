/*
Descriptive analysis for Medicare HRR project (project 4)
Abhijit Dasgupta
*/

/* 
2019-03-07

/*****************************************************************************************************************
Do HRR level variables vary with time?
/*****************************************************************************************************************/

PROC SQL;
CREATE TABLE timevary as
	SELECT DISTINCT hrr, bene_enrollmt_ref_yr, obese_wtperc, physjob_t_wtperc, smoking_wtperc, mcare_adv_wtperc, ortho_per_100000
	FROM sh026544.proj4_hrr_end15_sample;

PROC FREQ DATA=timevary;
	TABLES hrr*bene_enrollmt_ref_yr/ nocum nopercent norow nocol;
	run;

/* So all the HRR variables are constant over time within HRR */

/*****************************************************************************************************************
Do zipcode-level variable vary with time

These appear to be computed by individual based on their zip code and aggregated within HRR. They are not constant
within HRR
/*****************************************************************************************************************/
PROC SQL;
CREATE TABLE timevary as
	SELECT DISTINCT hrr, bene_enrollmt_ref_yr, mean(poor) as poor, mean(zscore) as zscore
	FROM sh026544.proj4_hrr_end15_sample
	GROUP BY hrr, bene_enrollmt_ref_yr;

PROC SGPLOT DATA=timevary;
	series x=bene_enrollmt_ref_yr y=poor / group=hrr;
	run;

PROC SGPLOT DATA=timevary;
	series x=bene_enrollmt_ref_yr y=zscore / group=hrr;
	run;

/*****************************************************************************************************************
 How much does zscore and poor vary over time? 
/*****************************************************************************************************************/

proc reg data=timevary;
	model zscore=bene_enrollmt_ref_yr;
	by hrr;
	ods output parameterestimates=want2;
	run;
data want3;
set want2;
keep hrr Variable Estimate;
if (Variable="BENE_ENROLLMT_REF_YR");
RUN;
proc sgplot data=want3;
histogram Estimate;
run;
proc means data=want3;
var Estimate;
run;

proc reg data=timevary;
	model poor=bene_enrollmt_ref_yr;
	by hrr;
	ods output parameterestimates=want2;
	run;
data want3;
set want2;
keep hrr Variable Estimate;
if (Variable="BENE_ENROLLMT_REF_YR");
RUN;
proc sgplot data=want3;
histogram Estimate;
run;
proc means data=want3;
var Estimate;
run;

/*****************************************************************************************************************
How much variability across HRRs do the individual level data have? across space and time
/*****************************************************************************************************************/

proc sql;
	create table indiv_level as
	select hrr, bene_enrollmt_ref_yr, mean(age_at_end_ref_yr) as age, mean(male) as perc_male, 
		mean(case when race=1 then 1 else 0 end) as perc_white, mean(case when race=2 then 1 else 0 end) as perc_black, mean(acutemi) as acutemi, 
		mean(afib) as afib,
		mean(breast_past) as breast_past, mean(chf) as chf, mean(ckd) as ckd, mean(colorectal_past) as colorectal_past,
		mean(copd) as copd, mean(dementia) as dementia, mean(depress) as depress, mean(diab) as diab, mean(endometrial_past) as endometrial_past,
		mean(hememalignancy) as hememalignancy, mean(hiv) as hiv, mean(ihd) as ihd, mean(liver) as liver, mean(lung_past) as lung_past, 
		mean(prostate_past) as prostate_past, mean(pvd) as pvd, mean(stroke) as stroke, mean(ulcers) as ulcers, mean(koa_visits) as avg_koavisits,
		mean(koa) as perc_koa, mean(kneesymptom_visits) as avg_kneevisits, mean(kneesymptoms) as perc_kneevisits, 
		mean(allkneevisits) as avg_kneevisits, mean(knee_patient) as perc_kneepatient, mean(dead) as perc_died, 
		sum(personyrs) as total_py, sum(tka)/sum(personyrs) as tka_rate
	from sh026544.proj4_hrr_end15_sample
	group by hrr, bene_enrollmt_ref_yr;

data indiv_knee;
	set sh026544.proj4_hrr_end15_sample;
	if koa=1;
run;
proc contents data=indiv_knee;
	run;
ods select nlevels;
proc freq data=indiv_knee nlevels;
	tables bene_id;
	run;

proc sql;
	create table indiv_knee as
	select hrr, bene_enrollmt_ref_yr, mean(age_at_end_ref_yr) as age, mean(male) as perc_male, 
		mean(case when race=1 then 1 else 0 end) as perc_white, mean(case when race=2 then 1 else 0 end) as perc_black, mean(acutemi) as acutemi, 
		mean(afib) as afib,
		mean(breast_past) as breast_past, mean(chf) as chf, mean(ckd) as ckd, mean(colorectal_past) as colorectal_past,
		mean(copd) as copd, mean(dementia) as dementia, mean(depress) as depress, mean(diab) as diab, mean(endometrial_past) as endometrial_past,
		mean(hememalignancy) as hememalignancy, mean(hiv) as hiv, mean(ihd) as ihd, mean(liver) as liver, mean(lung_past) as lung_past, 
		mean(prostate_past) as prostate_past, mean(pvd) as pvd, mean(stroke) as stroke, mean(ulcers) as ulcers, mean(koa_visits) as avg_koavisits,
		mean(koa) as perc_koa, mean(kneesymptom_visits) as avg_kneevisits, mean(kneesymptoms) as perc_kneevisits, 
		mean(allkneevisits) as avg_kneevisits, mean(knee_patient) as perc_kneepatient, mean(dead) as perc_died, 
		sum(personyrs) as total_py, sum(tka)/sum(personyrs) as tka_rate
	from sh026544.proj4_hrr_end15_sample
	group by hrr, bene_enrollmt_ref_yr
	where koa = 1;
proc sgplot data=indiv_level;
series x=bene_enrollmt_ref_yr y=age / group=hrr;
run;

proc sgplot data=indiv_level;
	vbox avg_koavisits / category=bene_enrollmt_ref_yr;
run;
proc sgplot data=indiv_level;
	scatter x=age y=avg_koavisits;
	loess x=age y=avg_koavisits;
run;


proc sgplot data=indiv_level;
*scatter x= age y=tka_rate;
loess x=age y=tka_rate/ group=bene_enrollmt_ref_yr;
run;

proc sgpanel data=indiv_level;
panelby bene_enrollmt_ref_yr;
loess x=age y=tka_rate;
scatter x=age y=tka_rate/transparency=0.7;
run;


/*****************************************************************************************************************
Does age vary by year?
/*****************************************************************************************************************/

proc contents data=sh026544.proj4_hrr_end15_sample;
run;

ods select nlevels;
proc freq data=sh026544.proj4_hrr_end15_sample nlevels;
	tables bene_id;
	run;

proc sql;
create table tmp as
	select min(age_at_end_ref_yr) as min_age,
		max(age_at_end_ref_yr) as max_age, 
		min(bene_enrollmt_ref_yr) as min_yr,
		max(bene_enrollmt_ref_yr) as max_yr,
		bene_id
	from sh026544.proj4_hrr_end15_sample
	group by bene_id
	order by bene_id;

/*****************************************************************************************************************
how many people are associated with different hrrs
/*****************************************************************************************************************/

proc sql;
	create table tmp as
		select distinct bene_id, hrr from sh026544.proj4_hrr_end15_sample
	order by bene_id;
proc sql;
	create table tmp2 as
		select bene_id, count(*) as N from tmp
		group by bene_id;
proc sql;
	create table tmp3 as
	select N, count(*) as N1 from tmp2 group by N;
proc sql;
	select N, N1, N1/sum(N1)*100 as Perc from tmp3;

proc freq data=tmp;
	tables bene_id;
run;


/*****************************************************************************************************************
How many replacements per HRR per year
/*****************************************************************************************************************/

proc sql;
	create table replacements as
		select bene_enrollmt_ref_yr, hrr, sum(tka) as tka
		from sh026544.proj4_hrr_end15_sample
		group by bene_enrollmt_ref_yr, hrr
		order by hrr;

proc sgplot data=replacements;
	series x=bene_enrollmt_ref_yr y=tka / group=hrr;
run;

/*****************************************************************************************************************
How many people had multiple replacements in a year?
/*****************************************************************************************************************/

proc freq data=sh026544.proj4_hrr_end15_sample;
	table tka*bene_enrollmt_ref_yr;
run;


/****************************************************************************************************************
Frequencies of comorbidities
/****************************************************************************************************************/
proc freq data=sh026544.proj4_hrr_end15_sample;
	tables (acutemi -- ulcers)*bene_enrollmt_ref_yr / nocum nopercent nofreq;
run;

/****************************************************************************************************************
Variability in comorbidity prevalence across HRR
/****************************************************************************************************************/
data temp;
set sh026544.proj4_hrr_end15_sample;
keep hrr acutemi -- ulcers;
run;

proc means data=temp Mean;
class hrr;
run;

proc tabulate data=temp out=prevalence;
class hrr;
var acutemi -- ulcers;
tables hrr, (acutemi -- ulcers)*(mean);
run;

ods select BasicMeasures Histogram;
proc univariate data=prevalence noprint ;
	var acutemi_Mean -- ulcers_Mean;
	histogram;
run;
ods select all;




proc sql;
	create table proj4_hrr_level as
		select hrr, sum(tka)/sum(personyrs)*1000 as tka, mean(obese_wtperc) as obese_wtperc, mean(physjob_t_wtperc) as physjob_t_wtperc,
			mean(smoking_wtperc) as smoking_wtperc, mean(ortho_per_100000) as ortho_per_100000, 
			mean(poor) as poor, mean(zscore) as zscore, mean(rural) as rural from sh026544.proj4_hrr_end15_sample
		group by hrr;

proc sgplot data=proj4_hrr_level;
	scatter x=obese_wtperc y=tka;
	loess x=obese_wtperc y=tka;
run;

proc sgplot data=proj4_hrr_level;
	scatter x=physjob_t_wtperc y=tka;
	loess x=physjob_t_wtperc y=tka;
run;

proc sgplot data=proj4_hrr_level;
	scatter x=smoking_wtperc y=tka;
	loess x=smoking_wtperc y=tka;
run;

proc sgplot data=proj4_hrr_level;
	scatter x=ortho_per_100000 y=tka;
	loess x=ortho_per_100000 y=tka;
run;

proc sgplot data=proj4_hrr_level;
	scatter x=poor y=tka;
	loess x=poor y=tka;
run;

proc sgplot data=proj4_hrr_level;
	scatter x=zscore y=tka;
	loess x=zscore y=tka;
run;

proc sgplot data=sh026544.proj4_hrr_level;
	scatter x=rural y=tka;
	loess x=rural y=tka;
run;


/* Creating a funnel plot for the rates */

proc sql;
	create table sh026544.funneldat as 
		select hrr, sum(tka) as Events, round(sum(personyrs)) as Population, sum(tka)/sum(personyrs) as rate from sh026544.proj4_hrr_end15_sample
		group by hrr;
run;

proc sgplot data=sh026544.funneldat;
	scatter x=Population y=rate;
	run;


proc means data=sh026544.funneldat n mean max min range std fw=8;
var Population;
run;

/* Code adapted from Rick Wicklin's blog*/
proc iml;
use sh026544.funneldat;
read all var {hrr Events Population};
close sh026544.funneldat;

/* 1. compute observed rates */
Rate = Events/Population;
call histogram(Rate);

/* 2. compute overall rate */
theta = sum(Events)/sum(Population);
Expected = theta * Population;
print (sum(Events))[L="NumEvents"] (sum(Population))[L="Population"] theta;

call symputx("AvgRate", theta);

results = Rate || Expected;
labels = {"Rate" "Expected"};
create Stats from results[colname=labels];
append from results;
close;


/* 3. Compute confidence limits for a range of sample sizes */
/*plot limits at equally spaced points */

minN = min(Population); maxN=max(Population);
/*n = T( do(minN, maxN, (maxN-minN)/50));*/
n = Population;
n = round(n); /* maintaining integer value */
p = {0.001 0.025 0.975 0.999}; /* lower, upper limits */
/* compute matrix with four columns, one for each CL */
limits = j(nrow(n), ncol(p));

do i = 1 to ncol(p);
	do j=1 to nrow(n);
	r = quantile("poisson", p[i], n[j]*theta);
	/* Following Spiegelhalter */
	numer = cdf("poisson", r, theta) - p[i];
	denom = cdf("poisson", r, theta) - cdf("poisson", r-1, theta);
	alpha = numer/denom;
	limits[j,i] = (r)/n[j];
	end;
end;


results = n || limits;
labels = {"N" "L3sd" "L2sd" "U2sd" "U3sd"};
create Limits from results[colname=labels];
append from results;
close;
quit;

/* merge data with rates */
data sh026544.funneldat; merge sh026544.funneldat Stats; run;
proc sort data=sh026544.funneldat; by Population; run;
proc sort data=WORK.limits; by N; run;
/* append control limits */

data sh026544.Funnel;
	merge sh026544.funneldat(rename=(Population=N)) Work.limits;
	by N;
	Label = hrr;
	if L3sd <= Rate <= U3sd then Label="";
	run;

/*data sh026544.Funnel; set sh026544.funneldat Limits; run;*/

/* 4. Plot rates versus sample size. Overlay control limits */
proc sgplot data=sh026544.Funnel;
band x=N lower=L3sd upper=U3sd /
	nofill lineattrs=(color=lipk)
	legendlabel="99.8% limits" name="band99";
band x=N lower=L2sd upper=U2sd /
	nofill lineattrs=(color=gray)
	legendlabel="95% limits" name="band95";
refline &AvgRate / axis=y;
scatter x=N y=Rate / datalabel=Label;
keylegend "band95" "band99" / location=inside position=bottomright;
yaxis grid values=(0 to 0.02 by 0.001); xaxis grid;
run;

	/* TODO: There are some observations with missing personyrs */
proc means data=sh026544.project4_hrr_end15 nmiss n;
	var personyrs;
run; /* Roughly 0.7 percent */
