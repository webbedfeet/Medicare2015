
proc sql;
select hrr, sum(personyrs) as py from sh026544.project4_hrr_end15
	group by hrr;
