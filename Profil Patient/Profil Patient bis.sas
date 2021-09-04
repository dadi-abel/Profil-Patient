/*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
> STUDY         AB19001 tracker           													<   				  
>																							<
> AUTHOR        Halima / Dadi Abel															<
>																							<
> VERSION       n°1																			<
> DATE          20210728																	<
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

LIBNAME AB19001 "H:\AB19001\02_ SASPrograms\Metrics\Data In";
LIBNAME Reports "M:\21 Data Management\DADI\AB19001\Profil Patient";

	 /*********************************************************************************************/
	/*********************************************************************************************/
proc sort data = Ab19001.Rep_cm out=Rep_cm;
	by SUBJID;
run;
proc sort data = Ab19001.Rep_alsfrs out=Rep_alsfrs;
	by SUBJID;
run;
proc sort data = Ab19001.Rep_fvc out=Rep_fvc;
	by SUBJID;
run;
proc sort data = Ab19001.Rep_vs out=Rep_vs;
	by SUBJID;
run;

     /*********************************************************************************************/
	/*********************************************************************************************/
PROC SQL;
	CREATE TABLE test AS 
	SELECT distinct E.*
	FROM 

	(SELECT distinct A.COUNTRYID, A.SITEID, A.SUBJID, A.SUBJEVENTNAME, A.WEIGHT, A.WEIGHTU, B.ALSFRSSCR
	FROM Rep_vs AS a LEFT JOIN Rep_alsfrs AS b
	ON a.SUBJID=b.SUBJID and a.SUBJEVENTNAME=b.SUBJEVENTNAME)E
	;
QUIT;

/*PROC SQL;
	CREATE TABLE test1 AS 
	SELECT distinct F.*
	FROM 

	(SELECT distinct D.SUBJID,D.SUBJEVENTNAME, C.FVCTVAIR1, C.FVCPVAL1, C.FVCTVAIR2, C.FVCPVAL2, C.FVCTVAIR3, C.FVCPVAL3
	FROM Rep_vs AS D LEFT JOIN Rep_fvc AS C 
	ON D.SUBJID=C.SUBJID and D.SUBJEVENTNAME=C.SUBJEVENTNAME)F
	;
QUIT;*/

proc sort data = test out=testBIS;
	by SUBJID;
run;

proc sql;
	create table testBIS1 as
	select COUNTRYID, SITEID, SUBJID, SUBJEVENTNAME, WEIGHT, WEIGHTU, ALSFRSSCR,
	case			when SUBJEVENTNAME='BASELINE' then '0'
					when SUBJEVENTNAME='SCREENING' then '-1'
					when SUBJEVENTNAME='FINAL VISIT' then '52'
					/*when SUBJEVENTNAME='Final Visit' then '29'*/
					when SUBJEVENTNAME like 'W%' then substr(SUBJEVENTNAME,3,2)
					end as ORDRE
	from testBIS a
	order by SUBJID, ORDRE desc;
quit;

/*TURN TO CHARACTERE TE WEIGHT OF PATIENT FOR THE ODS PRINT*/
data Reports.FIND;
	set testBIS1;
	LENGTH WEIGHTUC $15.;
	WEIGHTC = put(WEIGHT,15.1);
	WEIGHTUC = WEIGHTU;
	ALSFRSSCRC = put(ALSFRSSCR,15.1);
run;
/*proc sql ; 
create table Reports.FIND as
select COUNTRYID, SITEID, SUBJID, SUBJEVENTNAME, WEIGHT, WEIGHTU, WEIGHTC, WEIGHTUC, ALSFRSSCR, ORDRE 
from testBIS2;
quit;*/


     /*********************************************************************************************/
	/*********************************************************************************************/
proc sort data=AB19001.Rep_vd out=Reports.Rep_vd ; by SUBJID; run;
data Reports.Rep_vd;
	set Reports.Rep_vd ;
	if first.SUBJID;
	by SUBJID;
	keep STUDYID SITEID SUBJID;
run;

proc sort data=AB19001.Rep_vs out=Reports.Rep_vs ; by STUDYID SUBJID; run;
data Reports.Rep_vs;
	set Reports.Rep_vs ;
	if first.SUBJID;
	by SUBJID;
run;

proc sort data=AB19001.Rep_ifc_dm out=Reports.Rep_ifc_dm ; by SUBJID; run;

/*CREATED A HEIGHT TABLE*/
proc sql;
	create table taille
	as select SUBJID, HEIGHT from Reports.Rep_vs where SUBJEVENTNAME="SCREENING"
	order by SUBJID;
quit;

/*CREATED A WEIGHT TABLE*/
data poids;
	set Reports.Rep_vs;
	if last.SUBJID;
	by SUBJID;
	keep SUBJID WEIGHT BMI;
run;

/*MAKE A JOIN*/
data Reports.DEMO;
	merge Reports.Rep_ifc_dm  taille poids;
	AGEBISC = put(AGEBIS,15.);
	HEIGHTC = put(HEIGHT,15.1);
	WEIGHTC = put(WEIGHT,15.1);
	BMIC = put(BMI,15.2);
	/*if not missing(AGEBISC) then AGEBISC=AGEBISC;
	else AGEBISC='Unknown';*/
	by SUBJID;
	keep SITEID SUBJID AGEBIS SEX ETHINICITY HEIGHT WEIGHT BMI AGEBISC HEIGHTC WEIGHTC BMIC;
run;

  /*******************************************************************************************/
 /*								ADD THE PROFIL PATIENT DETACHEMENT							*/
/*******************************************************************************************/

%INCLUDE "M:\21 Data Management\DADI\AB19001\Profil Patient\Script\Profil Patient Detachement.sas";

/*STEP 1: DEFINE THE STYLE TEMPLATE*/

ods path work.templat(write) sasuser.templat(update) sashelp.tmplmst(read);
proc template;
	define style Styles.Profile / store=work.templat(write);
	parent = styles.rtf;
	style Body from Body /
	leftmargin = 1.0in rightmargin = 1.0in topmargin = 1.0in
	bottommargin = 1.0in rules=none frame=void;
	style Table from Output /
	frame = void rules = none cellspacing = 0 cellpadding = 3pt;
	replace fonts from Fonts /
	'TitleFont2' = ("Courier New",10pt)
	'TitleFont' = ("Courier New",10pt)
	'StrongFont' = ("Courier New",10pt,bold)
	'EmphasisFont' = ("Courier New",8pt,italic)
	'FixedEmphasisFont' = ("Courier New",8pt,italic)
	'FixedStrongFont' = ("Courier New",8pt,bold)
	'FixedHeadingFont' = ("Courier New",8pt,bold)
	'BatchFixedFont' = ("Courier New",8pt)
	'FixedFont' = ("Courier New",8pt)
	'HeadingEmphasisFont' = ("Courier New",8pt,italic)
	'HeadingFont' = ("Courier New",8pt,bold)
	'DocFont' = ("Courier New",8pt);
	replace TitlesAndFooters from TitlesAndFooters/
	font=Fonts('TitleFont2')
	vjust=T just=L cellspacing=0 cellpadding=3pt;
	style SystemTitle from TitlesAndFooters / protectspecialchars=off;
	style SystemFooter from TitlesAndFooters / protectspecialchars=on;
	replace Cell from Cell / font=Fonts('DocFont') protectspecialchars=off;
	replace HeadersAndFooters from HeadersAndFooters /
	font=Fonts('HeadingFont') protectspecialchars=off background=white;
	style RowHeader from HeadersAndFooters;
	style ColumnHeader from HeadersAndFooters;
	style Data from Cell;
	end;
run;

/*STEP 2: DEFINE THE TABLE TEMPLATE*/

** Define Patient-Level Table;
** This table has 6 columns, 3 columns of labels (mixed case variables) and
** 3 columns of text (upper case variables);
proc template;
	define table Reports.Rep_vd / store=templat;
	column StudyNumber STUDYID SiteNumber SITEID PatientNumber SUBJID;

		define column StudyNumber;
			** Column will always take the value defined in the "compute as" statement;
			compute as 'Study Number: ';
			print_headers=OFF; **do not print a column header;
			just=left;
			** use the RowHeader style defined above in the style template;
			style=RowHeader{CellWidth=1in};
		end;
		define column STUDYID;
			** Column is not computed here and is not "generic", so when called, the
			** template will expect a variable named STUDYID;
			print_headers=OFF;
			just=center;
			style=Cell {CellWidth=0.75in}; ** use the Cell style defined above;
		end;

		define column SiteNumber;
			compute as 'Site Number: ';
			print_headers=OFF;
			just=left;
			style=RowHeader{CellWidth=1.25in};
		end;
		define column SITEID;
			print_headers=OFF;
			just=center;
			style=Cell{CellWidth=0.75in};
		end;

		define column PatientNumber;
			compute as 'Patient Number: ';
			print_headers=OFF;
			just=left;
			style=RowHeader{CellWidth=1.25in};
		end;
		define column SUBJID;
			print_headers=OFF;
			just=center;
			style=Cell{CellWidth=1in};
		end;

		newpage=off;
		center=off;
		balance=off;
	end;

** Define Demographics;
** This table is similar to the patient-level table – labels are to the left of
** the data, so labels will be defined in their own columns;
** Table has 8 columns, 4 columns of labels (mixed case variables) and
** 4 columns of text (upper case variables);
	define table Reports.DEMO / store=templat;
	column AgeLab AGEBISC Gender SEX HgtLab HEIGHT LabBMI BMIC;

		define column AgeLab;
			compute as 'Age (yrs): ';
			print_headers=OFF;
			just=left;
			style=RowHeader{CellWidth=0.75in};
		end;
		define column AGEBISC;
			print_headers=OFF;
			just=center;
			style=Cell{CellWidth=0.5in};
		end;

		define column Gender;
			compute as 'Gender: ';
			print_headers=OFF;
			just=left;
			style=RowHeader{CellWidth=0.75in};
		end;
		define column SEX;
			print_headers=OFF;
			just=center;
			style=Cell{CellWidth=0.75in};
		end;

		define column HgtLab;
			compute as 'Height (cm): ';
			print_headers=OFF;
			just=left;
			style=RowHeader{CellWidth=1in};
		end;
		define column HEIGHT;
			print_headers=OFF;
			just=left;
			style=Cell{CellWidth=0.75in};
		end;

		define column LabBMI;
			compute as 'BMI (kg/m²): ';
			print_headers=OFF;
			just=left;
			style=RowHeader{CellWidth=0.9in};
		end;
		define column BMIC;
			print_headers=OFF;
			just=center;
			style=Cell{CellWidth=0.75in};
		end;	

		newpage=off;
		center=off;
		balance=off;
	end;

** Define ALSFR Table - ALS Functional Rating Scale - Revised 
** This table has 4 columns and an optional header row. Text for
** header is defined dynamically through the variable _HEAD;
	define table Reports.FIND / store=templat;
		dynamic _HEAD;
		column SUBJEVENTNAME WEIGHTC WEIGHTUC ALSFRSSCRC ;
		** optional header - define value of dynamic variable _HEAD in data step,
		** when calling this report template;
		define header hdr1;
			text _HEAD;
			space=1;
			/*spill_margin=on;*/
			just=left;
			style=ColumnHeader;
		end;

		define column SUBJEVENTNAME;
			header="Event Name:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=1.2in};
			/*blank_dups=on;*/
			** Column is defined as "generic" so any variable can be used to fill
			** this column in the template. The variable will be named when the
			** template is called in step 3 below;
			generic=on;
		end;

		define column WEIGHTC;
			** Column will have a label, or header, in the first row.
			** Header is defined here and "print_headers" is turned on;
			header="Weight:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=1in};
			/*blank_dups=on;*/
			** Column is defined as "generic" so any variable can be used to fill
			** this column in the template. The variable will be named when the
			** template is called in step 3 below;
			generic=on;
		end;

		define column WEIGHTUC;
			header="Unit Weight:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=1.2in};
			/*blank_dups=on;*/
			generic=on;
		end;

		define column ALSFRSSCRC;
			header="ALSFRS Score:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=1.2in};
			generic=on;
		end;

		newpage=off;
		center=off;
		balance=off;
	end;


** Define FVC Table - Forced Vital Capacity (FVC) 
** This table has 7 columns and an optional header row. Text for
** header is defined dynamically through the variable _HEAD;
	define table Reports.Rep_fvc_by_group / store=templat;
		dynamic _HEAD;
		column SUBJEVENTNAME FVCTVAIR1C FVCPVAL1C FVCTVAIR2C FVCPVAL2C FVCTVAIR3C FVCPVAL3C ;
		** optional header - define value of dynamic variable _HEAD in data step,
		** when calling this report template;
		define header hdr1;
			text _HEAD;
			space=1;
			spill_margin=on;
			just=center;
			style=ColumnHeader;
		end;

		define column SUBJEVENTNAME;
			header="Event Name:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.8in};
			** Column is defined as "generic" so any variable can be used to fill
			** this column in the template. The variable will be named when the
			** template is called in step 3 below;
			generic=on;
		end;

		define column FVCTVAIR1C;
			** Column will have a label, or header, in the first row.
			** Header is defined here and "print_headers" is turned on;
			header="Total volume air blowed forcefully following a full inhalation (in Liters):";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			** Column is defined as "generic" so any variable can be used to fill
			** this column in the template. The variable will be named when the
			** template is called in step 3 below;
			generic=on;
		end;

		define column FVCPVAL1C;
			header="First % of the predicted value:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column FVCTVAIR2C;
			header="Total volume air blowed forcefully following a full inhalation (in Liters):";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column FVCPVAL2C;
			header="Second % of the predicted value:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column FVCTVAIR3C;
			header="Total volume air blowed forcefully following a full inhalation (in Liters):";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column FVCPVAL3C;
			header="Third % of the predicted value:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		newpage=off;
		center=off;
		balance=off;
	end;


** Define MH_LE Table - Medical History (LE) 
** This table has 6 columns and an optional header row. Text for
** header is defined dynamically through the variable _HEAD;
	define table Reports.Rep_mh_le / store=templat;
		dynamic _HEAD;
		column SUBJPARENTEVENTNAME MHTERM MHSTDAT MHONGO MHENDAT MHCONTRT;
		** optional header - define value of dynamic variable _HEAD in data step,
		** when calling this report template;
		define header hdr1;
			text _HEAD;
			space=1;
			spill_margin=on;
			just=center;
			style=ColumnHeader;
		end;

		define column SUBJPARENTEVENTNAME;
			header="Parent Visit Name:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.8in};
			** Column is defined as "generic" so any variable can be used to fill
			** this column in the template. The variable will be named when the
			** template is called in step 3 below;
			generic=on;
		end;

		define column MHTERM;
			** Column will have a label, or header, in the first row.
			** Header is defined here and "print_headers" is turned on;
			header="History / Current Condition:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			** Column is defined as "generic" so any variable can be used to fill
			** this column in the template. The variable will be named when the
			** template is called in step 3 below;
			generic=on;
		end;

		define column MHSTDAT;
			header="Start Date:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column MHONGO;
			header="Ongoing:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column MHENDAT;
			header="End Date:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column MHCONTRT;
			header="Treated at Screening or at Baseline:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		newpage=off;
		center=off;
		balance=off;
	end;



** Define CM Table - Prev/Current CM (Part I)
** This table has 6 columns and an optional header row. Text for
** header is defined dynamically through the variable _HEAD;
	define table Reports.Rep_cm1 / store=templat;
		dynamic _HEAD;
		column CMNUM CMTRT CMINDC CMROUTE CMDOSE CMDOSEU;
		** optional header - define value of dynamic variable _HEAD in data step,
		** when calling this report template;
		define header hdr1;
			text _HEAD;
			space=1;
			spill_margin=on;
			just=center;
			style=ColumnHeader;
		end;

		define column CMNUM;
			header="Concomitant Medication number:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.8in};
			** Column is defined as "generic" so any variable can be used to fill
			** this column in the template. The variable will be named when the
			** template is called in step 3 below;
			generic=on;
		end;

		define column CMTRT;
			** Column will have a label, or header, in the first row.
			** Header is defined here and "print_headers" is turned on;
			header="Drug name (INN or Trade Name):";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			** Column is defined as "generic" so any variable can be used to fill
			** this column in the template. The variable will be named when the
			** template is called in step 3 below;
			generic=on;
		end;

		define column CMINDC;
			header="Indication:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column CMROUTE;
			header="Route:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column CMDOSE;
			header="Dose per intake:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column CMDOSEU;
			header="Dose Unit:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		newpage=off;
		center=off;
		balance=off;
	end;

** Define CM Table - Prev/Current CM (Partie II)
** This table has 6 columns and an optional header row. Text for
** header is defined dynamically through the variable _HEAD;
	define table Reports.Rep_cm2 / store=templat;
		dynamic _HEAD;
		column CMDOSEFRQ CMSTDAT CMENDAT CMONGO CMPRIOR CMREAS;
		** optional header - define value of dynamic variable _HEAD in data step,
		** when calling this report template;
		define header hdr1;
			text _HEAD;
			space=1;
			spill_margin=on;
			just=center;
			style=ColumnHeader;
		end;

		define column CMDOSEFRQ;
			header="Frequency:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.8in};
			/*blank_dups=on;*/
			** Column is defined as "generic" so any variable can be used to fill
			** this column in the template. The variable will be named when the
			** template is called in step 3 below;
			generic=on;
		end;

		define column CMSTDAT;
			** Column will have a label, or header, in the first row.
			** Header is defined here and "print_headers" is turned on;
			header="Start date:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			** Column is defined as "generic" so any variable can be used to fill
			** this column in the template. The variable will be named when the
			** template is called in step 3 below;
			generic=on;
		end;

		define column CMENDAT;
			header="End date:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column CMONGO;
			header="Ongoing:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column CMPRIOR;
			header="Was the treatment taken prior to the study?:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		define column CMREAS;
			header="Reason for medication:";
			print_headers=ON;
			just=center;
			style=Cell{CellWidth=0.9in};
			generic=on;
		end;

		newpage=off;
		center=off;
		balance=off;
	end;

** Define TAB1 Table;
** 1 columns of text (upper case variables);
	define table Reports.TAB1 / store=templat;
	column cioms1 CIOMS ;

		define column cioms1;
			** Column will always take the value defined in the "compute as" statement;
			compute as 'CIOMS: ';
			print_headers=OFF; **do not print a column header;
			just=left;
			** use the RowHeader style defined above in the style template;
			style=RowHeader{CellWidth=1in};
		end;

		define column CIOMS;
			** Column is not computed here and is not "generic", so when called, the
			** template will expect a variable named STUDYID;
			print_headers=OFF;
			just=center;
			style=Cell {CellWidth=5in}; ** use the Cell style defined above;
		end;

		newpage=off;
		center=off;
		balance=off;
	end;

** Define TAB1_BIS Table;
** 1 columns of text (upper case variables);

	define table Reports.TAB1_BIS / store=templat;
	column  hospital HOSPTAL_RECORDS_REPORT;

		define column hospital;
			compute as 'Hospital Records/report (if death occurred in hospital): ';
			print_headers=OFF;
			just=left;
			style=RowHeader{CellWidth=1in};
		end;

		define column HOSPTAL_RECORDS_REPORT;
			** Column is not computed here and is not "generic", so when called, the
			** template will expect a variable named STUDYID;
			print_headers=OFF;
			just=center;
			style=Cell {CellWidth=5in}; ** use the Cell style defined above;
		end;

		newpage=off;
		center=off;
		balance=off;
	end;


** Define TAB2 Table;
** 1 columns of text (upper case variables);
	define table Reports.TAB2 / store=templat;
	column  encal ENCALS ;

		define column encal;
			compute as 'Encals Predicted survival: ';
			print_headers=OFF;
			just=left;
			style=RowHeader{CellWidth=1in};
		end;

		define column ENCALS;
			** Column is not computed here and is not "generic", so when called, the
			** template will expect a variable named STUDYID;
			print_headers=OFF;
			just=center;
			style=Cell {CellWidth=5in}; ** use the Cell style defined above;
		end;

		newpage=off;
		center=off;
		balance=off;
	end;

** Define TAB2_BIS Table;
** 2 columns of text (upper case variables);
	define table Reports.TAB2_BIS / store=templat;
	column reviewer REVIEWER_S;

		define column reviewer;
			compute as "Reviewer's opinion on cause of death: ";
			print_headers=OFF;
			just=left;
			style=RowHeader{CellWidth=1in};
		end;

		define column REVIEWER_S;
			print_headers=OFF;
			just=center;
			style=Cell {CellWidth=5in}; ** use the Cell style defined above;
		end;

		newpage=off;
		center=off;
		balance=off;
	end;


run;

/*STEP 3: PRODUCE THE PROFILE*/

options orientation=portrait nodate nonumber missing=' ' nocenter
papersize=letter leftmargin=1in rightmargin=1in topmargin=1in
bottommargin=1in;
ods escapechar="~";

*** MACRO RUNTAB(x) will run a single patient profile for USUBJID=x ***;
%macro runtab(x);
	title ;
	footnote;
	ods listing close;

** Output Unique Subject Identifiers into the macro variable [SUBJID];
**(Used in defining patient-specific Filename below);
	proc sql ;
		select compress(SUBJID) into :USUBJID from AB19001.Rep_ifc_dm where SUBJID="&x";
	quit;

	filename _rtf_
	"M:\21 Data Management\DADI\AB19001\Profil Patient\data out\%sysfunc(compress(&USUBJID)).rtf";
	ods rtf file=_rtf_ newfile=none nokeepn startpage=no record_separator=none
	headery=770 footery=770 /*style=styles.Profile  STYLE= minimal*/ STYLE=Rtf/*Defined in Step 1 above*/;
	** J= means justify, L for left, C for center, R for right;
	** ~ is the ODS escape character defined above;
	** {THISPAGE} and {LASTPAGE} are RTF-specific codes for producing pagination
	** fields in Word;
	title1 j=L "Patient Profile &x";

** Patient-Level Table **;
	ods rtf anchor='PatientInfo';
	data _NULL_;
		set AB19001.Rep_ifc_dm;
		where SUBJID="&x";
		** These columns are not generic, so they are expecting variable names
		** matching those defined in the template above;
		file print ods=(template='Reports.Rep_vd'
		columns=( STUDYID SITEID SUBJID ));
		put _ods_;
	run;

** Demographics **;
	ods rtf anchor='Demographics';
	data _NULL_;
		merge Reports.Demo/*Rep_ifc_dm Reports.Rep_vs*/ ;
		by SUBJID;
		where SUBJID="&x";

		if not missing(AGEBISC) then AGEBISC=AGEBISC;
		else AGEBISC='Unknown';

		if not missing(SEX) then SEX=SEX;
		else SEX='Unknown';

		if not missing(BMIC) then BMIC=BMIC;
		else BMIC='Unknown';

		file print ods=(template='Reports.DEMO'
		columns=(AGEBISC SEX HEIGHT BMIC));
		put _ods_;
	run;

** ALS Functional Rating Scale - Revised and weight Values **;
	ods rtf anchor='ALSFRS_WEIGHT';
	data _NULL_ ;
		set Reports.FIND;
		where SUBJID="&x";

		if not missing(WEIGHTUC) then WEIGHTUC=WEIGHTUC;
		else WEIGHTUC='Unknown';

		if not missing(WEIGHTC) then WEIGHTC=WEIGHTC;
		else WEIGHTC='Unknown';

		if not missing(ALSFRSSCRC) then ALSFRSSCRC=ALSFRSSCRC;
		else ALSFRSSCRC='Unknown';

		file print ods=(template='Reports.FIND'
		dynamic=( _HEAD="ALS Functional Rating Scale - Revised and weight Values:" )
		columns=( SUBJEVENTNAME = SUBJEVENTNAME (generic=on)
		WEIGHTC = WEIGHTC (generic=on)
		WEIGHTUC = WEIGHTUC (generic=on)
		ALSFRSSCRC = ALSFRSSCRC (generic=on)));
		put _ods_;
	run;

** Forced Vital Capacity (FVC) Values **;
	ods rtf anchor='FVC';
	data _NULL_;
		set Reports.Rep_fvc_by_group;
		where SUBJID="&x";
		if not missing(FVCTVAIR1C) then FVCTVAIR1C=FVCTVAIR1C;
		else FVCTVAIR1C='Unknown';

		if not missing(FVCPVAL1C) then FVCPVAL1C=FVCPVAL1C;
		else FVCPVAL1C='Unknown';

		if not missing(FVCTVAIR2C) then FVCTVAIR2C=FVCTVAIR2C;
		else FVCTVAIR2C='Unknown';

		if not missing(FVCPVAL2C) then FVCPVAL2C=FVCPVAL2C;
		else FVCPVAL2C='Unknown';

		if not missing(FVCTVAIR3C) then FVCTVAIR3C=FVCTVAIR3C;
		else FVCTVAIR3C='Unknown';

		if not missing(FVCPVAL3C) then FVCPVAL3C=FVCPVAL3C;
		else FVCPVAL3C='Unknown';

		file print ods=(template='Reports.Rep_fvc_by_group'
		dynamic=( _HEAD="Forced Vital Capacity (FVC) Values" )
		columns=( SUBJEVENTNAME = SUBJEVENTNAME (generic=on)
		FVCTVAIR1C = FVCTVAIR1C (generic=on)
		FVCPVAL1C = FVCPVAL1C (generic=on)
		FVCTVAIR2C = FVCTVAIR2C (generic=on)
		FVCPVAL2C = FVCPVAL2C (generic=on)
		FVCTVAIR3C = FVCTVAIR3C (generic=on)
		FVCPVAL3C = FVCPVAL3C (generic=on)));
		put _ods_;
	run;

** Medical History (LE) Values **;
	ods rtf anchor='MH_LE';
	data _NULL_;
		set Reports.Rep_mh_le;
		where SUBJID="&x";

		if not missing(MHTERM) then MHTERM=MHTERM;
		else MHTERM='Unknown';

		if not missing(MHSTDAT) then MHSTDAT=MHSTDAT;
		else MHSTDAT='Unknown';

		if not missing(MHONGO) then MHONGO=MHONGO;
		else MHONGO='Unknown';

		if not missing(MHENDAT) then MHENDAT=MHENDAT;
		else MHENDAT='Unknown';

		if not missing(MHCONTRT) then MHCONTRT=MHCONTRT;
		else MHCONTRT='Unknown';

		file print ods=(template='Reports.Rep_mh_le'
		dynamic=( _HEAD="Medical History (LE) Values" )
		columns=( SUBJPARENTEVENTNAME = SUBJPARENTEVENTNAME (generic=on)
		MHTERM = MHTERM (generic=on)
		MHSTDAT = MHSTDAT (generic=on)
		MHONGO = MHONGO (generic=on)
		MHENDAT = MHENDAT (generic=on)
		MHCONTRT = MHCONTRT (generic=on)));
		put _ods_;
	run;       

** Prev/Current CM Values(Part I) **;
	ods rtf anchor='CM';
	data _NULL_;
		set Reports.Rep_cm1;
		where SUBJID="&x";

		/*if not missing(CMNUM) then CMNUM1=CMNUM1;
		else CMNUM='Unknown';*/

		if not missing(CMTRT) then CMTRT=CMTRT;
		else CMTRT='Unknown';

		if not missing(CMINDC) then CMINDC=CMINDC;
		else CMINDC='Unknown';

		if not missing(CMROUTE) then CMROUTE=CMROUTE;
		else CMROUTE='Unknown';

		/*if not missing(CMDOSE) then CMDOSE1=CMDOSE1;
		else CMDOSE='Unknown';*/

		if not missing(CMDOSEU) then CMDOSEU=CMDOSEU;
		else CMDOSEU='Unknown';

		file print ods=(template='Reports.Rep_cm1'
		dynamic=( _HEAD="Prev/Current CM Values(Part I)" )
		columns=( CMNUM = CMNUM (generic=on)
		CMTRT = CMTRT (generic=on)
		CMINDC = CMINDC (generic=on)
		CMROUTE = CMROUTE (generic=on)
		CMDOSE = CMDOSE (generic=on)
		CMDOSEU = CMDOSEU (generic=on)));
		put _ods_;
	run;   

** Prev/Current CM Values(Part II) **;
	ods rtf anchor='CM';
	data _NULL_;
		set Reports.Rep_cm2;
		where SUBJID="&x";

		if not missing(CMDOSEFRQ) then CMDOSEFRQ=CMDOSEFRQ;
		else CMDOSEFRQ='Unknown';

		if not missing(CMSTDAT) then CMSTDAT=CMSTDAT;
		else CMSTDAT='Unknown';

		if not missing(CMENDAT) then CMENDAT=CMENDAT;
		else CMENDAT='Unknown';

		if not missing(CMONGO) then CMONGO=CMONGO;
		else CMONGO='Unknown';

		if not missing(CMPRIOR) then CMPRIOR=CMPRIOR;
		else CMPRIOR='Unknown';

		if not missing(CMREAS) then CMREAS=CMREAS;
		else CMREAS='Unknown';

		file print ods=(template='Reports.Rep_cm2'
		dynamic=( _HEAD="Prev/Current CM Values(Part II)" )
		columns=( CMDOSEFRQ = CMDOSEFRQ (generic=on)
		CMSTDAT = CMSTDAT (generic=on)
		CMENDAT = CMENDAT (generic=on)
		CMONGO = CMONGO (generic=on)
		CMPRIOR = CMPRIOR (generic=on)
		CMREAS = CMREAS (generic=on)));
		put _ods_;
	run;  

** 	ADDITIONAL PATIENT INFORMATION PART I 	**;
	ods rtf anchor='PatientInfoBis_I';
	data _NULL_;
		set Reports.tab1;
		where SUBJID="&x";
		** These columns are not generic, so they are expecting variable names
		** matching those defined in the template above;
		file print ods=(template='Reports.tab1'
		columns=( CIOMS ));
		put _ods_;
	run;

** 	ADDITIONAL PATIENT INFORMATION PART II	**;
	ods rtf anchor='PatientInfoBis_II';
	data _NULL_;
		set Reports.TAB1_BIS;
		where SUBJID="&x";
		** These columns are not generic, so they are expecting variable names
		** matching those defined in the template above;
		file print ods=(template='Reports.TAB1_BIS'
		columns=( HOSPTAL_RECORDS_REPORT ));
		put _ods_;
	run;

** 	ADDITIONAL PATIENT INFORMATION PART III 	**;
	ods rtf anchor='PatientInfoBis_III';
	data _NULL_;
		set Reports.tab2;
		where SUBJID="&x";
		** These columns are not generic, so they are expecting variable names
		** matching those defined in the template above;
		file print ods=(template='Reports.tab2'
		columns=( ENCALS ));
		put _ods_;
	run;

** 	ADDITIONAL PATIENT INFORMATION PART IV 	**;
	ods rtf anchor='PatientInfoBis_IV';
	data _NULL_;
		set Reports.TAB2_BIS;
		where SUBJID="&x";
		** These columns are not generic, so they are expecting variable names
		** matching those defined in the template above;
		file print ods=(template='Reports.TAB2_BIS'
		columns=(  REVIEWER_S ));
		put _ods_;
	run;


ods rtf close;                
ods listing;

%mend runtab;

/*create a patient list*/
PROC SQL NOPRINT;
	SELECT DISTINCT SUBJID INTO: PatientNumber SEPARATED BY ','
	FROM Reports.Rep_vd; 
quit;

