data proj4_white_lincoln proj4_white_wichita proj4_white_slc;
set sh026544.proj4_mod3_white;
if (hrrnum = 277) then output proj4_white_lincoln;
if (hrrnum = 201) then output proj4_white_wichita;
if (hrrnum = 423) then output proj4_white_slc;
run;



data proj4_white_lincoln;
set proj4_white_lincoln;
if zip in ('68501','68502','68503','68504','68505','68506','68507','68508','68510','68512',
		   '68514','68516','68520','68521','68522','68523','68524','68526','68527','68528',
		   '68529','68542','68544','68583','68588') then city=1;
else city=0;
run;

data proj4_white_wichita;
set proj4_white_wichita;
if zip in ("67052","67101","67106","67201","67202","67203","67204","67205","67206","67207",
		   "67208","67209","67210","67211","67212","67213","67214","67215","67216","67217",
		   "67218","67219","67220","67223","67226","67228","67230","67235","67260","67275",
		   "67276","67277","67278") then city = 1;
else city=0;
run;

data proj4_white_slc;
set proj4_white_slc;
if zip in ("84044","84050","84101","84102","84103","84104","84105","84106","84108","84109",
		   "84110","84111","84112","84113","84114","84115","84116","84119","84120","84122",
		   "84128","84132","84133","84134","84136","84138","84139","84141","84143","84145",
		   "84147","84148","84150","84151","84152","84158","84180","84184","84189","84190",
		   "84199") then city = 1;
else city = 0;
run;

proc sql;
select mean(city) as city_perc from proj4_white_slc;
select mean(city) as city_perc from proj4_white_wichita;
select mean(city) as city_perc from proj4_white_lincoln;


%macro urban_smr(cty);
proc sql;
create table smr_&cty as 
	select city, sum(tka) as obs, sum(predicted) as expected from proj4_white_&cty group by city;
data smr_&cty;
set smr_&cty;
smr3 = obs/expected;
run;
%mend;

%urban_smr(slc);
%urban_smr(wichita);
%urban_smr(lincoln);


