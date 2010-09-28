/* *************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    Aug 2010                                                                                                            
/* PROG NAME:       eq_name_match.sas                                                              
/* Project:         Market Interconnectedness and Fires Sales, Momentum
/* This File:       Match the names with no cusips to names in CRSP - JOBARRAY FILE
/************************************************************************************/
 
%include 'marketnet_header.sas'; *header file with basic options and libraries;


/* Datasets required to run:
 * mktnet.equities_raw				: Equities with no cusips; security cusip port_date fundid rowid
 * mktnet.crsp_raw					: CRSP msenames Data; namedt nameendt comnam ncusip shrcd
 
 */
 
/* Datasets Produced:
 * mkn_work.cumulative&n			: where n = 1 to 317, which is the number of port_dates to iterate
 */

/* testing 
proc freq data = mktnet.equities_raw;
tables port_date;
run;

proc freq data = mktnet.crsp_raw;
tables namedt nameendt;
run;


* run this one time prior to jobarray;
proc sort data = mktnet.equities_raw out = mktnet.date_list nodupkey;
by port_date;
run;
*NOTE: The data set MKTNET.DATE_LIST has 317 observations and 6 variables;

%let n = 2; 
* end testing;
*/


* the real deal;
%let n = %sysget(LSB_JOBINDEX); *sysget is the jobarray function to get index from unix system;

data _null_;
set mktnet.date_list (keep = port_date);
if _N_ = &n then do;
	call symput('thisdate', PUT(port_date, z8.));
	call symput('thisdatef', PUT(port_date, yymmdd10.));
	end;
run;

data eq_match_date (drop = datec);
	set mktnet.equities_raw;
	where port_date = &thisdate;
	* test to be sure it is resolving properly and can read in the log;
	datec = &thisdatef;
run;
proc print data = eq_match_date (obs = 100); run;

data crsp_match_date;
	set mktnet.crsp_raw;
	if (namedt <= &thisdate <= nameendt) then output;
run;

%include '/netscr/jabloche/util/company_macro.sas';
%mfmatch(dataset1=eq_match_date,var1=security,dataset2=crsp_match_date,var2=comnam,out_ds=mkn_work.cumulative&n.);

proc print data = mkn_work.cumulative&n (obs = 100);
var fundid port_date security comnam compa compb totalscore ncusip;
run;