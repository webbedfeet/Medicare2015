data ortho1;
set sh026544.project4_alltka_2011 ;
keep op_physn_npi zip_cd_surg;
run;
data ortho2;
set sh026544.project4_alltka_2012 ;
keep op_physn_npi zip_cd_surg;
run;
data ortho3;
set sh026544.project4_alltka_2013 ;
keep op_physn_npi zip_cd_surg;
run;
data ortho4;
set sh026544.project4_alltka_2014 ;
keep op_physn_npi zip_cd_surg;
run;
data ortho5;
set sh026544.project4_alltka_2015 ;
keep op_physn_npi zip_cd_surg;
run;

data ortho1;
set ortho1;
if op_physn_npi ne . then year=2011;
else year=.;
run;
data ortho2;
set ortho2;
if op_physn_npi ne . then year=2012;
else year=.;
run;
data ortho3;
set ortho1;
if op_physn_npi ne . then year=2013;
else year=.;
run;
data ortho4;
set ortho4;
if op_physn_npi ne . then year=2014;
else year=.;
run;
data ortho5;
set ortho5;
if op_physn_npi ne . then year=2015;
else year=.;
run;





data ortho;
set ortho1 ortho2 ortho3 ortho4 ortho5;
zip=substr(zip_cd_surg,1,5);
run;
data orthoall;
set ortho;
format zip $5.;
run;

proc sql;
create table hrr as
select distinct zip, hrr
from sh026544.project4_hrrgood15;
quit;

proc sql;
create table orthonew as 
select * from orthoall as x
left join hrr as y
on x.zip=y.zip;
quit;

data orthonew1;
set orthonew;
if hrr=. then delete;
run;

proc print data=orthonew1 (obs=200);
run;

proc sort data=orthonew1;
by year ;
run;
data orthonew_2011;
set orthonew1;
if year=2011;
run;
proc sort data=orthonew_2011;
by op_physn_npi;
run;
data orthonew_2011n;
set orthonew_2011;
by op_physn_npi;
if first.op_physn_npi then count=0;
count+1;
if last.op_physn_npi then output;
run;
proc print data=orthonew_2011n (obs=200);
run;


data orthonew_2012;
set orthonew1;
if year=2012;
run;
proc sort data=orthonew_2012;
by op_physn_npi;
run;
data orthonew_2012n;
set orthonew_2012;
by op_physn_npi;
if first.op_physn_npi then count=0;
count+1;
if last.op_physn_npi then output;
run;
proc print data=orthonew_2012n (obs=200);
run;

data orthonew_2013;
set orthonew1;
if year=2013;
run;
proc sort data=orthonew_2013;
by op_physn_npi;
run;
data orthonew_2013n;
set orthonew_2013;
by op_physn_npi;
if first.op_physn_npi then count=0;
count+1;
if last.op_physn_npi then output;
run;
proc print data=orthonew_2013n (obs=200);
run;



data orthonew_2014;
set orthonew1;
if year=2014;
run;
proc sort data=orthonew_2014;
by op_physn_npi;
run;
data orthonew_2014n;
set orthonew_2014;
by op_physn_npi;
if first.op_physn_npi then count=0;
count+1;
if last.op_physn_npi then output;
run;
proc print data=orthonew_2014n (obs=200);
run;


data orthonew_2015;
set orthonew1;
if year=2015;
run;
proc sort data=orthonew_2015;
by op_physn_npi;
run;
data orthonew_2015n;
set orthonew_2015;
by op_physn_npi;
if first.op_physn_npi then count=0;
count+1;
if last.op_physn_npi then output;
run;
proc print data=orthonew_2015n (obs=200);
run;

data sh026544.ortho2011;
set orthonew_2011n;
run;
data sh026544.ortho2012;
set orthonew_2012n;
run;
data sh026544.ortho2013;
set orthonew_2013n;
run;
data sh026544.ortho2014;
set orthonew_2014n;
run;
data sh026544.ortho2015;
set orthonew_2015n;
run;

proc print data=sh026544.ortho2015 (obs=14); run;

data sh026544.ortho_overall;
set sh026544.ortho2011
	sh026544.ortho2012
	sh026544.ortho2013
	sh026544.ortho2014
	sh026544.ortho2015;
keep op_physn_npi hrr count;
run;
proc sql;
create table ortho_counts as 
	select op_physn_npi, hrr, sum(count) as count from sh026544.ortho_overall group by op_physn_npi, hrr;

proc sql;
create table py as
	select hrr, sum(personyrs) as personyrs from sh026544.proj4_hrr_end15_white group by hrr;
proc sql;
create table sh026544.proj4_phys_rates as
	select * from ortho_counts a left join py b on a.hrr=b.hrr;
