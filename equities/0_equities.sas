/* *************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    Sept 2010                                                                                                            
/* PROG NAME:       subdivide_holdings.sas                                                              
/* Project:         Market Interconnectedness and Fires Sales, Momentum
/* This File:       Divides up our "equity" group - i.e. those portfolios with some nonzero equity holdings.
/************************************************************************************/
 
%include 'marketnet_header.sas'; *header file with basic options and libraries;


/* Datasets required to run:
 * mktnet.mastmornhold_equities				: Master Dataset with all nonzero equity holdings
 */
 
/* Datasets Produced:
 * mktnet.equities_valid_cusip				: Equity holdings with valid CRSP Cusip
 * mktnet.equities_raw						: Equity holdings without a valid CUSIP to be processed by name match
 * mktnet.equities_no_cusip					: equities_raw but with all of the other columns
 */

/* Plan:
 * 1. Extract Equities
 *		1a. Extract valid CUSIPs based on checksum
 *		1b. Match names with CRSP
 *		1c. Match names with Compustat
 * 		1d. How many left? We'll have to see what to do with remainder
 * Ditto with Bonds but done elsewhere
 */
proc contents data = mktnet.mastmornhold_equities; run;
proc freq data = mktnet.mastmornhold_equities; 
tables type_cd;
run;

* OK, so first extract only the equity holdings, subdivide by CUSIP;

data mkn_work.equities_only_w_cusip mkn_work.equities_no_cusip;
	set mktnet.mastmornhold_equities;
	where substr(type_cd,1,1) = 'E'; *starts with E;
	if missing(cusip) then output mkn_work.equities_no_cusip;
	else output mkn_work.equities_only_w_cusip;
run;

/*
NOTE: There were 46717243 observations read from the data set MKTNET.MASTMORNHOLD_EQUITIES.
      WHERE SUBSTR(type_cd, 1, 1)='E';
NOTE: The data set MKN_WORK.EQUITIES_ONLY_W_CUSIP has 45697207 observations and 32 variables.
NOTE: The data set MKN_WORK.EQUITIES_NO_CUSIP has 1020036 observations and 32 variables.
NOTE: DATA statement used (Total process time):
      real time           10:39.56
      cpu time            1:12.14
*/


proc sql;
	title 'Number of obs missing CUSIP and also description is 44';
	select count(*) as count_desc from
	mkn_work.equities_no_cusip
	where missing(security);
quit;

%include '/netscr/jabloche/util/cusip_validation.sas';
* validate the cusips we do have;
%validateCusips(ds_in=mkn_work.equities_only_w_cusip, cusip=cusip ,ds_out=mkn_work.validate_equity_cusip, valid=validCusip );


proc univariate data = mkn_work.validate_equity_cusip;
var validCusip;
run;
/*
 = 295 invalid Cusips
                  N                    45697207    Sum Weights           45697207
                  Mean               0.99999354    Sum Observations      45696912
 */

* Now, combine invalid cusips with no cusip data for name matching;
data mkn_work.equities_valid_cusip (drop = validCusip) invalid_cusip (drop = validCusip);
	set mkn_work.validate_equity_cusip;
	if validCusip = 1 then output mkn_work.equities_valid_cusip;
	else output invalid_cusip;
run;

proc append base = mkn_work.equities_no_cusip data = invalid_cusip;
run;

*keep it simple, just what we need for name matching. Merge the rest back later;
data mktnet.equities_raw;
	set mkn_work.equities_no_cusip (keep = security cusip port_date fundid rowid);
	year = year(port_date);
run;
data mktnet.equities_valid_cusip;
	set mkn_work.equities_valid_cusip;
run;
data mktnet.equities_no_cusip;
	set mkn_work.equities_no_cusip;
run;