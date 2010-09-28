/* *************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    Aug 2010                                                                                                            
/* PROG NAME:       bonds.sas                                                              
/* Project:         Market Interconnectedness and Fires Sales, Momentum
/* This File:       Analyze the bond holdings. Not sure how this will work.
/************************************************************************************/
 
%include 'marketnet_header.sas'; *header file with basic options and libraries;


/* Datasets required to run:
 * morn.master_morn_holdings				: Master Dataset with all holdings and fund stats
 * morn.portfolio_type_codes_renamed		: Excel Sheet converted to SAS via Stat Transfer, type code names
 * morn.sector_codes						: Twelve Sector Codes manually input into dataset
 * morn.porthold_main_clean_fixed			: Text Files convered via Stat Transfer, merged, cleaned, holdings only
 * morn.portfolio_statistics_only			: Fund level stats, unique by fundid, portfolio date
 */
 
/* Datasets Produced:
 * 
 */

* OK, so first extract only the bonds;
/*
data mkn_work.bonds_only_w_cusip mkn_work.bonds_no_cusip;
	set morn.master_morn_holdings;
	where substr(type_cd,1,1) = 'B'; *starts with B;
	if missing(cusip) then output mkn_work.bonds_no_cusip;
	else output mkn_work.bonds_only_w_cusip;
run;
*/
proc contents data = mkn_work.bonds_no_cusip; run;

proc freq data = mkn_work.bonds_no_cusip;
tables sector_code industry_code mat_year port_year type_cd country;
run;

options ls = max;
proc means data = mkn_work.bonds_no_cusip N NMISS mean min p25 p50 p75 max;
var shares sharechange marketvalue weight coupon;
run;