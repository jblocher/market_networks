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

proc sql;
	select distinct type_cd, type_name
	from mktnet.mastmornhold_equities;
quit;

* OK, so first extract only the equity holdings, subdivide by CUSIP;
/* Did this elsewhere
data mkn_work.equities_only_w_cusip mkn_work.equities_no_cusip;
	set mktnet.mastmornhold_equities;
	where substr(type_cd,1,1) = 'E'; *starts with E;
	if missing(cusip) then output mkn_work.equities_no_cusip;
	else output mkn_work.equities_only_w_cusip;
run;
 */

data mkn_work.not_equities_w_cusip mkn_work.not_equities_no_cusip;
	set mktnet.mastmornhold_equities;
	if missing(cusip) then output mkn_work.munis_no_cusip;
	else output mkn_work.munis_only_w_cusip;
run;

%include '/netscr/jabloche/util/cusip_validation.sas';
* validate the cusips we do have;
%validateCusips(ds_in=mkn_work.not_equities_w_cusip, cusip=cusip ,ds_out=mkn_work.validate_non_equity_cusip, valid=validCusip );


proc univariate data = mkn_work.validate_non_equity_cusip;
var validCusip;
run;
/*
results:
 */

* Now, combine invalid cusips with no cusip data for name matching;
data mkn_work.validate_non_equity_cusip (drop = validCusip) invalid_cusip (drop = validCusip);
	set mkn_work.validate_non_equity_cusip;
	if validCusip = 1 then output mkn_work.nonequities_valid_cusip;
	else output invalid_cusip;
run;

proc append base = mkn_work.not_equities_no_cusip data = invalid_cusip;
run;


/* do this later. Check Cusips first 
data mkn_work.bonds_only_w_cusip mkn_work.bonds_no_cusip;
	set mktnet.mastmornhold_equities;
	where substr(type_cd,1,1) = 'B'; *starts with B for Bonds;
	if missing(cusip) then output mkn_work.bonds_no_cusip;
	else output mkn_work.bonds_only_w_cusip;
run;

data mkn_work.munis_only_w_cusip mkn_work.munis_no_cusip;
	set mktnet.mastmornhold_equities;
	where position=prxmatch('/\d/', type_cd); *type_cd is a numeric digit - muni bonds;
	if missing(cusip) then output mkn_work.munis_no_cusip;
	else output mkn_work.munis_only_w_cusip;
run;
*/

