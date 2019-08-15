title "Plotting SMR patterns by race";
proc sql;
	create table tmp as 
	select * from sh026544.proj4_overall_smr natural join sh026544.proj4_race;

ods text="Using Model 1 SMRs";

proc sgpanel data=tmp;
	panelby race;
	scatter x=Percent y=SMR1;
	*reg x=Percent y=SMR / degree=2;
	rowaxis label='SMR' type=log logstyle=logexpand values=(0.5 to 2 by 0.25);
	run;

ods text= "Using Model 3 SMRs";

proc sgpanel data=tmp;
	panelby race;
	scatter x=Percent y=SMR3;
	*reg x=Percent y=SMR / degree=2;
	rowaxis label='SMR' type=log logstyle=logexpand values=(0.5 to 2 by 0.25);
	run;

/*
Expected rate from model
*/
title "Overall expected rate from Model 3, per 1000";
proc sql;
	create table tmp as 
		select 	sum(expected_knee3) as expected_total,
				sum(py) as tot_py 
		from sh026544.proj4_hrr_modsummary_overall;


data sh026544.proj4_expected_rate;
set tmp;
expected_rate = expected_total / tot_py * 1000;
run;
proc print data=sh026544.proj4_expected_rate;
run;

title "Expected rates by race, per 1000";
/* Expected rate by race */
proc sql;
	create table tmp2 as
		select	race, 
				sum(expected_knee3) as expected_total,
				sum(py) as tot_py
		from sh026544.proj4_hrr_modsummary_overall
		group by race;
data sh026544.proj4_expected_rate_race;
	set tmp2;
	rate = expected_total / tot_py * 1000;
run;
proc print data=sh026544.proj4_expected_rate_race;
run;



/*
proc sql;
create table whites as select hrr, sum(total_knee) as tot_w,  sum(expected_knee3) as exp_w   from sh026544.proj4_hrr_modsummary_overall where race=1
	group by hrr;
create table blacks as select hrr, sum(total_knee) as tot_b, sum(expected_knee3) as exp_b  from sh026544.proj4_hrr_modsummary_overall where race=2
	group by hrr;
create table hispanic as select hrr, sum(total_knee) as tot_h, sum(expected_knee3) as exp_h  from sh026544.proj4_hrr_modsummary_overall where race=3
	group by hrr;
create table wb as select * from whites natural join blacks natural join hispanic;

data wb_plot;
set wb;
smr3_b = tot_b/exp_b;
smr3_w = tot_w/exp_w;
smr3_h = tot_h/exp_h;
where tot_b > 20;
run;
proc print data=wb_plot;
run;

proc sgplot data=wb_plot noautolegend;
title 'SMRs of whites vs blacks, model 3 standardization';
title2 'restricted to HRRs with at least 20 black tka';
scatter x=smr3_w  y=smr3_b/  markerattrs=graphdata2(symbol=circlefilled);
lineparm x=0 y=0 slope=1;
xaxis grid LABEL='White';yaxis grid label='Black';
run;
*/

proc sql;
select count(*) from sh026544.proj4_hrr_end15_2013 group by hrr;
