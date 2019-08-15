/* Linking subjects with physicians (linking datasets are project4_alltka_<yr> */

data alltka;
set 
	sh026544.project4_alltka_2011
	sh026544.project4_alltka_2012
	sh026544.project4_alltka_2013
	sh026544.project4_alltka_2014
	sh026544.project4_alltka_2015
;
keep bene_id op_physn_npi tka year;
run;

%macro ortho_join(year);
data tmp;
set sh026544.proj4_mod3_white_&year;
keep bene_id bene_enrollmt_ref_yr hrrnum predicted;
run;
proc sql;
create table tmp1_&year as
	select b.bene_id, b.op_physn_npi,b.tka, b.year, a.hrrnum, a.predicted 
	from  alltka as b right join tmp as a
	on a.bene_id = b.bene_id and a.bene_enrollmt_ref_yr = b.year
	where b.year=&year;
%mend;



%ortho_join(2011);
%ortho_join(2012);
%ortho_join(2013);
%ortho_join(2014);
%ortho_join(2015);

data sh026544.ortho_predicted;
set tmp1_2011 tmp1_2012 tmp1_2013 tmp1_2014 tmp1_2015;
run;

proc print data=sh026544.ortho_predicted (obs=50); run;
proc datasets lib=work;
delete tmp tmp_2011 tmp_2012 tmp_2013 tmp_2014 tmp_2015;
run;

proc sql;
create table ortho_smr as 
	select op_physn_npi, hrrnum, sum(tka) as obs, sum(predicted) as expect
	from sh026544.ortho_predicted
	group by op_physn_npi, hrrnum;

proc contents data=sh026544.ortho_predicted; run;

proc sgplot data=sh026544.ortho_predicted;
histogram predicted;
run;

proc sql;
create table tmp as
	select op_physn_npi, hrrnum, sum(tka) as ortho_volume, mean(predicted) as expect_prob
		from sh026544.ortho_predicted
		group by op_physn_npi, hrrnum;
proc sgplot data=tmp;
scatter x=expect_prob y=ortho_volume;
run;


data modsummary_white;
set sh026544.proj4_hrr_modsummary_white_2011
 sh026544.proj4_hrr_modsummary_white_2012
 sh026544.proj4_hrr_modsummary_white_2013
 sh026544.proj4_hrr_modsummary_white_2014
 sh026544.proj4_hrr_modsummary_white_2015;
run;

proc print data=sh026544.proj4_hrr_modsummary_white_2011 (obs=40); run;
proc sql;
create table smr_white as 
	select distinct hrr, race, sum(total_knee) as total_knee, sum(expected_knee1) as exp1,
	sum(expected_knee2) as exp2, sum(expected_knee3) as exp3, sum(py) as py
	from modsummary_white
	group by hrr;
data smr_white;
set smr_white;
smr1 = total_knee/exp1;
smr2 = total_knee/exp2;
smr3 = total_knee/exp3;
run;

proc sql;
create table graph1 as
	select a.hrr,  b.op_physn_npi, b.ortho_volume, b.expect_prob, a.smr3
	from smr_white as a right join tmp as b on a.hrr=b.hrrnum;

proc print data=tmp (obs=100); run;

data mod3_white_tka;
set sh026544.proj4_mod3_white_2011
	sh026544.proj4_mod3_white_2012
	sh026544.proj4_mod3_white_2013
	sh026544.proj4_mod3_white_2014
	sh026544.proj4_mod3_white_2015;
where tka > 0;
keep bene_id bene_enrollmt_ref_yr tka Predicted hrr;
run;
proc contents data=mod3_white_tka; run;

proc stdize data=mod3_white_tka Out=mod3_white_tka method=range;
var Predicted;
run;

proc sgplot data=mod3_white_tka;
histogram Predicted;
run;

proc sql;
create table tmp as
	select a.bene_id, a.year, a.op_physn_npi, a.tka, b.hrr, b.Predicted from
		alltka as a left join mod3_white_tka as b
		on a.bene_id = b.bene_id and a.year = b.bene_enrollmt_ref_yr;
create table ortho_summary as
	select op_physn_npi, hrr, sum(tka) as volume, mean(Predicted) as expect_prob from tmp
		group by op_physn_npi, hrr;

proc sgplot data=ortho_summary;
scatter x=expect_prob y=volume;
run;
proc univariate data=ortho_summary;
var expect_prob volume;
run;

proc rank data=ortho_summary groups=10 out=decs(keep= op_physn_npi hrr probq);
var expect_prob;
ranks probq;
run;

data ortho_summary;
merge ortho_summary decs;
by op_physn_npi hrr;
run;

proc sgplot data=ortho_summary;
vbox volume/category=probq;
yaxis grid type=log logstyle=LogExpand;
run;

/* Ortho rates within HRR overall and within healthy and poorrisk subsets */

data alltka;
set 
	sh026544.project4_alltka_2011
	sh026544.project4_alltka_2012
	sh026544.project4_alltka_2013
	sh026544.project4_alltka_2014
	sh026544.project4_alltka_2015
;
keep bene_id op_physn_npi tka year;
run;

proc sql;
create table sh026544.proj4_py_hrr as
	select hrr, sum(personyrs) as py from sh026544.proj4_hrr_end15_white
	group by hrr;

%macro surg_rate(grp);
proc sql;
create table &grp as
	select a.bene_id, a.hrrnum, a.personyrs, a.bene_enrollmt_ref_yr, b.op_physn_npi, b.tka from sh026544.proj4_&grp as a left join alltka as b
	on a.bene_id = b.bene_id and a.bene_enrollmt_ref_yr = b.year;
create table denom as select hrrnum, sum(personyrs) as py from &grp where tka ne . and hrrnum ne . group by hrrnum;
create table num as select hrrnum, op_physn_npi, sum(tka) as tka from &grp where tka ne . and hrrnum ne . group by hrrnum, op_physn_npi ;
create table composite_&grp as select * from num a left join denom b on a.hrrnum = b.hrrnum;

data composite_&grp;
set composite_&grp;
rate_&grp = tka/py * 100000;
run;
%mend;

%surg_rate(healthy);
%surg_rate(poorrisk);

proc sql;
create table overall as 
select a.bene_id, a.hrrnum, a.personyrs, a.bene_enrollmt_ref_yr, b.op_physn_npi, b.tka from sh026544.proj4_hrr_end15_white as a left join alltka as b
on a.bene_id = b.bene_id and a.bene_enrollmt_ref_yr=b.year;
create table denom as select hrrnum, sum(personyrs) as py from overall where tka ne . and hrrnum ne . group by hrrnum;
create table num as select hrrnum, op_physn_npi, sum(tka) as tka from overall where tka ne . and hrrnum ne . group by hrrnum, op_physn_npi ;
create table composite_overall as select * from num a left join denom b on a.hrrnum = b.hrrnum;
data composite_overall;
set composite_overall;
rate_overall = tka/py * 100000;
run;

proc sql;
create table sh026544.proj4_phys_rates as
	select a.hrrnum, a.op_physn_npi, a.rate_overall, b.rate_healthy, c.rate_poorrisk from 
		composite_overall as a left join composite_healthy as b on a.hrrnum=b.hrrnum and a.op_physn_npi = b.op_physn_npi
			left join composite_poorrisk as c on a.hrrnum = c.hrrnum and a.op_physn_npi = c.op_physn_npi;

