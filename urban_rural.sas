/*
Script for looking at rural/urban shift in OER within select HRRs that have a good
rural-urban mix, but with different overall OERs

Cities are Albuquerque, Bakersfield, Lexington, Lincoln, Phoenix (Greater Phoenix), 
Salt Lake City, San Antonio, Syracuse, Wichita

AUTHOR: Abhijit Dasgupta
*/


%macro urban_smr(cty); /* Compute OER for each HRR */
proc sql;
create table tmp as
  	select distinct hrrnum, city, sum(tka) as obs, sum(predicted) as expected, count(*) as tot 
	from proj4_white_&cty 
	group by city;
create table smrs as 
	select hrrnum, city, obs, expected, 
		obs/expected as smr3, tot/sum(tot) as Percent format=percent7.2 
	from tmp;
create table smr_&cty as
select * from smrs as a left join (select hrr, smr3 as overall_smr from sh026544.proj4_smr_white) as b on a.hrrnum=b.hrr;
data smr_&cty;
	set smr_&cty;
	location = "&cty";
run;
%mend;

data proj4_white_albuquerque  proj4_white_bakersfield  proj4_white_lexington  
	proj4_white_lincoln  proj4_white_phoenix  proj4_white_slc  
	proj4_white_san_antonio  proj4_white_syracuse  proj4_white_wichita  ;
	set sh026544.proj4_mod3_white;
	if (hrrnum = 293) then output proj4_white_albuquerque;
	if (hrrnum = 25)  then output proj4_white_bakersfield;
	if (hrrnum = 204) then output proj4_white_lexington;
	if (hrrnum = 277) then output proj4_white_lincoln;
	if (hrrnum = 12)  then output proj4_white_phoenix;
	if (hrrnum = 423) then output proj4_white_slc;
	if (hrrnum = 412) then output proj4_white_san_antonio;
	if (hrrnum = 307) then output proj4_white_syracuse;
	if (hrrnum = 201) then output proj4_white_wichita;
run;

data proj4_white_albuquerque;
	set proj4_white_albuquerque;
	if zip in ('87048','87102','87104','87105','87106','87107','87108','87109','87110','87111','87112','87113','87114','87116','87117','87120','87121','87122','87123','87501','87505','87506','87507','87508','87544','87545') then city=1;
	else city = 0;
run;

%urban_smr(albuquerque)

data proj4_white_bakersfield;
	set proj4_white_bakersfield;
	if zip in ('93203','93220','93301','93304','93305','93306','93307','93308','93309','93311','93312','93313','93314') then city=1;
	else city = 0;
run;

%urban_smr(bakersfield)

data proj4_white_lexington;
	set proj4_white_lexington;
	if zip in ('40361','40502','40503','40504','40505','40506','40507','40508','40509','40510','40511','40513','40514','40515','40516','40517') then city=1;
	else city = 0;
run;

%urban_smr(lexington)

data proj4_white_lincoln;
	set proj4_white_lincoln;
	if zip in ('68336','68430','68502','68503','68504','68505','68506','68507','68508','68510','68512','68514','68516','68517','68520','68521','68522','68523','68524','68526','68528','68531') then city=1;
	else city = 0;
run;

%urban_smr(lincoln)

data proj4_white_phoenix;
	set proj4_white_phoenix;
	if zip in ('85003','85004','85006','85007','85008','85009','85012','85013','85014','85015','85016','85017','85018','85019','85020','85021','85022','85023','85024','85027','85028','85029','85031','85032','85033','85034','85035','85037','85040','85041','85042','85043','85044','85045','85048','85050','85051','85053','85054','85083','85085','85086','85087','85118','85119','85120','85121','85122','85123','85128','85131','85132','85137','85138','85139','85140','85141','85142','85143','85145','85147','85172','85173','85193','85194','85201','85202','85203','85204','85205','85206','85207','85208','85209','85210','85212','85213','85215','85224','85225','85226','85233','85234','85248','85249','85250','85251','85253','85254','85255','85256','85257','85258','85259','85260','85262','85263','85264','85266','85268','85281','85282','85283','85284','85286','85295','85296','85297','85298','85301','85302','85303','85304','85305','85306','85307','85308','85309','85310','85320','85322','85323','85326','85331','85335','85337','85338','85339','85340','85342','85343','85345','85351','85353','85354','85355','85361','85363','85373','85374','85375','85377','85379','85381','85382','85383','85387','85388','85390','85392','85395','85396','85618','85623','85631') then city=1;
	else city = 0;
run;

%urban_smr(phoenix)

data proj4_white_slc;
	set proj4_white_slc;
	if zip in ('84044','84101','84102','84103','84104','84105','84106','84108','84109','84111','84112','84113','84115','84116','84119','84120','84128','84144','84180') then city=1;
	else city = 0;
run;

%urban_smr(slc)

data proj4_white_san_antonio;
	set proj4_white_san_antonio;
	if zip in ('78023','78056','78073','78109','78112','78154','78201','78202','78203','78204','78205','78207','78208','78209','78210','78211','78212','78213','78214','78215','78216','78217','78218','78219','78220','78221','78222','78223','78224','78225','78226','78227','78228','78229','78230','78231','78232','78233','78234','78235','78236','78237','78238','78239','78240','78242','78243','78244','78245','78247','78248','78249','78250','78251','78252','78253','78254','78255','78256','78257','78258','78259','78260','78263','78264','78266') then city=1;
	else city = 0;
run;

%urban_smr(san_antonio)

data proj4_white_syracuse;
	set proj4_white_syracuse;
	if zip in ('13120','13202','13203','13204','13205','13206','13207','13208','13210','13214','13215','13219','13224','13290') then city=1;
	else city = 0;
run;

%urban_smr(syracuse)

data proj4_white_wichita;
	set proj4_white_wichita;
	if zip in ('67037','67052','67067','67101','67106','67202','67203','67204','67205','67206','67207','67208','67209','67210','67211','67212','67213','67214','67215','67216','67217','67218','67219','67220','67223','67226','67228','67230','67235','67260') then city=1;
	else city = 0;
run;

%urban_smr(wichita)


data sh026544.proj4_smr_rural_urban;
	set
		smr_albuquerque
		smr_bakersfield
		smr_lexington
		smr_lincoln
		smr_phoenix
		smr_slc
		smr_san_antonio
		smr_syracuse
		smr_wichita; 
run;
