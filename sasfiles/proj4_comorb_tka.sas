/* 
Looking for prevalence of comorbidities among those who have had a TKA, by HRR
We had already looked at prevalence of TKA among comorbid in Figure 4 (proj4_surgery_comorbs.sas)

data sh026544.proj4_dementia sh026544.proj4_chf sh026544.proj4_ulcers sh026544.proj4_pvd 
	sh026544.proj4_depression sh026544.proj4_poor sh026544.proj4_poorrisk;
set sh026544.proj4_hrr_end15_white;
if(dementia=1) then output sh026544.proj4_dementia;
if(chf=1) then output sh026544.proj4_chf;
if(ulcers=1) then output sh026544.proj4_ulcers;
if(pvd= 1) then output sh026544.proj4_pvd;
if (poor=1) then output sh026544.proj4_poor;
if (depress=1) then output sh026544.proj4_depression;
if (dementia=1 or chf=1 or ulcers=1 or pvd=1) then output sh026544.proj4_poorrisk;
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

*/

data proj4_tka;
set sh026544.proj4_hrr_end15_white ;
if tka > 0;
run;

data proj4_tka;
set proj4_tka;
comorbs = sum(of acutemi--ulcers);
if comorbs=0 and agecat=1 then healthy=1;
else healthy = 0;
run;

proc sql;
create table sh026544.proj4_comorb_tka_white as 
	select hrr,
		mean(dementia) as dementia,
		mean(depress) as depress,
		mean(pvd) as pvd,
	mean(ulcers) as ulcers,
	mean(chf) as chf,
	mean(healthy) as healthy,
	sum(tka) as tka,
	sum(personyrs) as py
	from proj4_tka 
	group by hrr;

proc print data=proj4_comorb_tka; run;
