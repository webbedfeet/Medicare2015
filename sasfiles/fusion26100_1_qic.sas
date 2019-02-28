%macro qic(

version ,

/* PROC */
data=_last_ ,
Poptions=   ,

/* CLASS */
class= ,        /* REQUIRED */

/* MODEL */
response= ,     /* REQUIRED */
model= ,
dist= ,         /* REQUIRED */
Moptions= ,

/* REPEATED */
subject= ,      /* REQUIRED */
type= ,         /* TYPE= or LOGOR= REQUIRED */
within= ,
logor= ,        /* TYPE= or LOGOR= REQUIRED */
Roptions= ,

/* OUTPUT */
out=_outr ,
p=_p ,
Ooptions= ,

/* WEIGHT */
weight= ,

/* FREQ */
freq= ,

/* Other statements */
stmts=,

/* macro options */
outqic=_qic ,
appendto=,
label=,
QICoptions=

);

%let _version=1.2;
%if &version ne %then %put &sysmacroname macro Version &_version;

%if %sysevalf(&sysver < 8.2) %then %do;
   %put ERROR: SAS 8.2 or later is required.  Terminating.;
   %let opts=;
   %goto exit;
%end;

%let opts = %sysfunc(getoption(notes))
            _last_=&out;
%if &version ne d %then %str(options nonotes;);


/* Check for newer version */
 %if %sysevalf(&sysver >= 7) %then %do;
  filename _ver url 'http://ftp.sas.com/techsup/download/stat/versions.dat'  termstr=crlf;
  data _null_;
    infile _ver;
    input name:$15. ver;
    if upcase(name)="&sysmacroname" then call symput("_newver",ver);
    run;
  %if &syserr ne 0 %then
    %put &sysmacroname: Unable to check for newer version;
  %else %if %sysevalf(&_newver > &_version) %then %do;
    %put &sysmacroname: A newer version of the &sysmacroname macro is available.;
    %put %str(         ) You can get the newer version at this location:;
    %put %str(         ) http://support.sas.com/ctx/samples/index.jsp;
  %end;
 %end;


/***************** Syntax checks *******************/
%if %quote(&subject)= %then %do;
  %put ERROR: SUBJECT= must be specified;
  %goto exit;
%end;
%if %quote(&type)= and %quote(&logor)= %then %do;
  %put ERROR: TYPE= or LOGOR= must be specified;
  %goto exit;
%end;
%if %quote(&response)= %then %do;
  %put ERROR: RESPONSE= must be specified;
  %goto exit;
%end;
%if %quote(&class)= %then %do;
  %put ERROR: CLASS= must be specified;
  %goto exit;
%end;
%if &dist= %then %do;
  %put ERROR: DIST= must be specified;
  %goto exit;
%end;
%let sp=%str( );
%let dist=&dist&sp;
%if %upcase(%substr(&dist,1,1)) ne B and
    %upcase(%substr(&dist,1,1)) ne N and
    %upcase(%substr(&dist,1,1)) ne P and
    %upcase(%substr(&dist,1,1)) ne G and
    %upcase(%substr(&dist,1,2)) ne IG
%then %do;
  %put ERROR: DIST= must be B (binomial), N (normal), P (poisson), G (gamma), or IG (inverse gaussian);
  %goto exit;
%end;
%if %quote(&response)= %then %do;
  %put ERROR: RESPONSE= must be specified;
  %goto exit;
%end;
%let trials=;
%if %index(&response,/)>0 %then %do;
  %let trials=%scan(&response,2);
  %let events=%scan(&response,1);
%end;
%if %index(&stmts,by%str( ))>0 %then %do;
  %put ERROR: The BY statement may not be used.;
  %goto exit;
%end;
%if %index(&Ooptions,%str(p=))>0 or %index(&Ooptions,%str(pred=))>0 or
    %index(&Ooptions,%str(prob=))>0 or %index(&Ooptions,%str(predicted=))>0
%then %do;
  %put QIC: P= is ignored. Predicted values will be output to variable %upcase(&P).;
%end;
%if &label eq %then %let label=&type &logor / &model;


/******************************************************************
   Fit the GEE model with desired correlation structure and save
   the empirical covariance matrix, Vr, fitted values, and parameter
   vector.
*/
options notes;
%if %index(%upcase(&Roptions),ECOVB)=0 %then %str(ods exclude geercov;);
%if %index(%upcase(&Roptions),MODELSE)=0 %then %str(ods exclude geemodpest;);
%if %index(%upcase(&QICoptions),NOPRINT) ne 0 %then %str(ods exclude all;);
proc genmod data=&data &Poptions
  %if %upcase(%substr(&dist,1,1))=B and &trials= %then descending;
  ;
  %if %quote(&class) ne %then %str(class &class;);
  model &response = &model / &Moptions dist=&dist;
  repeated subject=&subject / &Roptions ecovb modelse
      %if %quote(&within) ne %then within=&within;
      %if %quote(&type) ne %then type=&type;
      %if %quote(&logor) ne %then logor=&logor;
      ;
  %if &weight ne %then %str(weight &weight;);
  %if &freq ne %then %str(freq &freq;);
  &stmts;
  output out=&out p=&p &Ooptions;
  ods output geercov=_vr geemodpest=_pe convergencestatus=_cs1;
  run;
%if &syserr > 4 %then %goto exit;
%if %index(%upcase(&QICoptions),NOPRINT) ne 0 %then %str(ods select all;);
%if &version ne d %then %str(options nonotes;);
data _null_; set _cs1;
  call symput('geestatus1',status);
  run;
%if &geestatus1 > 2 %then %goto exit;

%if %quote(&logor) ne %then %do;
  data _vr;
    set _vr;
    where index(rowname,'Alpha')=0;
    drop alpha:;
    run;
%end;

/* Extract intercept and parms */
data _null_;
 length _init $ 32767;
 retain _init "";
 set _pe end=_eof;
 if _n_=1 then call symput('int',estimate);
 else if _eof then do;
   call symput('scale',estimate);
   call symput('initial',_init);
 end;
 else %if %sysevalf(&sysver >= 9) %then %do;
        _init=catx(" ",_init,estimate);
      %end; %else %do;
        _init=trim(left(_init))||" "||trim(left(estimate));
      %end;
 run;


/*****************************************************************
   Fit the same model with independence structure and previously
   fitted parameters to get the model-based covariance matrix, Oir.
*/
%if %index(%upcase(&QICoptions),INDMODEL)=0 %then %str(ods exclude all;);
proc genmod data=&data &Poptions
  %if %upcase(%substr(&dist,1,1))=B and &trials= %then descending;
  ;
  %if %quote(&class) ne %then %str(class &class;);
  model &response = &model / &Moptions scale=&scale noscale dist=&dist;
  repeated subject=&subject / &Roptions mcovb
      %if %quote(&within) ne %then within=&within;
      intercept=&int
      %if %quote(&model) ne %then initial=&initial ;
      maxiter=0 type=ind;
  %if &weight ne %then %str(weight &weight;);
  %if &freq ne %then %str(freq &freq;);
  &stmts;
  ods output geencov=_oir convergencestatus=_cs2;
  run;
%if &syserr > 4 %then %goto exit;
%if %index(%upcase(&QICoptions),INDMODEL)=0 %then %str(ods select all;);
data _null_; set _cs2;
  call symput('geestatus2',status);
  run;
%if &geestatus2 > 2 %then %do;
  %put ERROR: Independence model fit failed.  Terminating.;
  %goto exit;
%end;
%put QIC: The "Iteration limit exceeded" warning can be ignored.;


/*****************************************************************
   Compute quasilikelihood and QIC statistics
*/
proc iml;
use _vr; read all into vr;
use _oir; read all into oir;
use &out;

%if &trials ne %then %do;
    %let response=&events;
    read all var {&trials} into t;
%end;
read all var {&response} into y;
read all var {&p} into mur;
%if %upcase(%substr(&dist,1,1))=B and &trials=
  %then %str(t=j(nrow(y),1););

%if &weight= %then %str(w=j(nrow(y),1););
  %else %do;
    read all var {&weight} into w;
    w=choose(w<=0,.,w);
  %end;
%if &freq= %then %str(f=j(nrow(y),1););
  %else %do;
    read all var {&freq} into f;
    f=choose(f<=0,.,f);
  %end;

/* Compute quasilikelihoods */
/* BINOMIAL */
%if %upcase(%substr(&dist,1,1))=B %then
  %str(qr=w#f#((y/t)#log(mur/(1-mur))+log(1-mur)););
  /* or: %str(qr=f#((y/t)#log(mur)+(1-y/t)#log(1-mur));); */
/* NORMAL */
%else %if %upcase(%substr(&dist,1,1))=N %then
    %str(qr=w#f#-0.5#(y-mur)##2;);
/* POISSON */
%else %if %upcase(%substr(&dist,1,1))=P %then
    %str(qr=w#f#(y#log(mur)-mur););
/* GAMMA */
%else %if %upcase(%substr(&dist,1,1))=G %then
    %str(qr=w#f#(-y/mur-log(mur)););
/* INVERSE NORMAL */
%else %if %upcase(%substr(&dist,1,2))=IG %then
    %str(qr=w#f#(-y/(2*mur##2)+1/mur););

%if %index(%upcase(&Moptions),NOINT)=0 %then %do;
  qr=qr/&scale.##2;
%end; %else %do;
  phi2=(f[+,1]-nrow(vr)-1)/(f[+,1]-nrow(vr));
  qr=qr/(phi2*(&scale.##2));
%end;

/* Compute QIC(R), QICu */
qicr=-2*qr[+,1]+2*trace(inv(oir)*vr);
qicu=-2*qr[+,1]+2*nrow(vr);

/* Create output data set, OUTQIC= */
qic=qicr // qicu;
criterion={"QIC" "QICu"};
cname={"Value"};
create &outqic from qic [rowname=criterion colname=cname];
append from qic [rowname=criterion];
quit;

%if &syserr ne 0 %then %do;
  %put QIC: Error in computing QIC or QICu.  Aborting.;
  %goto exit;
%end;

proc transpose data=&outqic out=_tqic(drop=_name_);
   var value; id criterion;
   run;
data _tqic;
  length label $ 40; label="&label";
  set _tqic;
  run;
%if &appendto ne %then %do;
  proc append base=&appendto data=_tqic; run;
%end;

/*****************************************************************
   Create ODS table containing QIC statistics
*/
%if %index(%upcase(&QICoptions),NOPRINT) ne 0 %then %goto exit;

/* Define and save GEE Fit Criteria table */
proc template;
   define table GEEFitCriteria / store = SASUSER.TEMPLAT;
      notes "GEE Fit Criteria";
      column Criterion Value;
      header head;

      define head;
         split='/';
         text "/The QIC Macro//GEE Fit Criteria";
         space = 1;
      end;

      define Criterion;
         print_headers = OFF;
      end;

      define Value;
         format = 12.4;
         print_headers = OFF;
      end;
   end;
   run;

/* Display GEE Fit Criteria table */
data _null_;
  set &outqic;
  file print ods=(template='GEEFitCriteria'
                  object=GEEFitCriteria
                  objectlabel="Fit Criteria");
  put _ods_;
  run;

%exit:
options &opts;
title;
ods select all;
%mend;

