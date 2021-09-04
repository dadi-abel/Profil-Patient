		  /******************************************************************************************/
		 /*					CREATE A LOOP THAT RECOVER THE LAST 5 LINE PER PATIENT				   */
		/******************************************************************************************/
libname AB19001 "H:\AB19001\02_ SASPrograms\Metrics\Data In" access=readonly; 
option fmtsearch=(AB19001);
LIBNAME Reports "M:\21 Data Management\DADI\AB19001\Profil Patient";

/**/
proc sql;
	create table Rep_fvc as
	select *, 
	case			when SUBJEVENTNAME='BASELINE' then '0'
					when SUBJEVENTNAME='SCREENING' then '-1'
					when SUBJEVENTNAME='FINAL VISIT' then '52'
					/*when SUBJEVENTNAME='Final Visit' then '29'*/
					when SUBJEVENTNAME like 'W%' then substr(SUBJEVENTNAME,3,2)
					end as ORDRE
	from AB19001.Rep_fvc a
	order by SUBJID, ORDRE desc;
quit;

data Reports.Rep_fvc_by_group;
	set Rep_fvc;
	FVCTVAIR1C = put(FVCTVAIR1,15.1);
	FVCPVAL1C = put(FVCPVAL1,15.1);
	FVCTVAIR2C = put(FVCTVAIR2,15.1);
	FVCPVAL2C = put(FVCPVAL2,15.1);
	FVCTVAIR3C = put(FVCTVAIR3,15.1);
	FVCPVAL3C = put(FVCPVAL3,15.1);
	by SUBJID;
 
	retain n;
	if first.SUBJID then do;
		n = 1;
		output;
	end;
	else if n lt 5 then do;
		n = n + 1;
		output;
	end;
	drop n ORDRE;
run;

/*Medical History (LE)*/
proc sort data = Ab19001.Rep_mh_le out=Reports.Rep_mh_le;
	by SUBJID;
run;

/*Changing the length of a character variable*/
proc sql;
alter table Reports.Rep_mh_le
  modify MHONGO char(20) format=$20.,
		MHCONTRT char(20) format=$20.;
quit;

/*Prev/Current CM*/
proc sort data = Ab19001.Rep_cm out=Reports.Rep_cm;
	by SUBJID;
run;

/*Changing the length of a character variable*/
proc sql;
alter table Reports.Rep_cm
  modify CMONGO char(20) format=$20.,
		CMPRIOR char(20) format=$20.;
quit;

/*SECTION REP_CM EN DEUX TABLES*/
proc sql;
create table Reports.Rep_cm1 as
select SUBJID, CMNUM,put(CMNUM, 24.) AS CMNUM1, CMTRT, CMINDC, CMROUTE, CMDOSE,put(CMDOSE, 24.) AS CMDOSE1, CMDOSEU
from Reports.Rep_cm;
quit;

proc sql;
create table Reports.Rep_cm2 as
select SUBJID, CMDOSEFRQ, CMSTDAT, CMENDAT, CMONGO, CMPRIOR, CMREAS
from Reports.Rep_cm;
quit;

/*Créer une structure de table (table vide)*/
proc sql;
   create table Reports.TAB (CIOMS char(255),
                      HOSPTAL_RECORDS_REPORT char(32),
                      ENCALS char(32),
					  REVIEWER_S char(32));
quit;

proc sql ;
   insert into Reports.TAB (CIOMS , HOSPTAL_RECORDS_REPORT, ENCALS, REVIEWER_S)
   values (' ', ' ', ' ', ' ')
   ;
quit ;

PROC SQL ;
	CREATE TABLE Reports.PT_LIST AS
	SELECT DISTINCT SUBJID 
	FROM Reports.Rep_vd; 
quit;

/*MAKE A JOIN*/
DATA Reports.TAB1(KEEP=SUBJID CIOMS );
SET Reports.PT_LIST Reports.TAB;
run;

DATA Reports.TAB1_BIS(KEEP=SUBJID HOSPTAL_RECORDS_REPORT );
SET Reports.PT_LIST Reports.TAB;
run;

DATA Reports.TAB2(KEEP=SUBJID ENCALS);
SET Reports.PT_LIST Reports.TAB;
run;

DATA Reports.TAB2_BIS(KEEP=SUBJID REVIEWER_S);
SET Reports.PT_LIST Reports.TAB;
run;
