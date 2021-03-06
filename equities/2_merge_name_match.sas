/* *************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    Sept 2010                                                                                                            
/* PROG NAME:       eq_name_match.sas                                                              
/* Project:         Market Interconnectedness and Fires Sales, Momentum
/* This File:       Match the names with no cusips to names in CRSP
/************************************************************************************/
 
%include 'marketnet_header.sas'; *header file with basic options and libraries;


/* Datasets required to run:
 * mktnet.equities_raw				: Equities with no cusips; security cusip port_date fundid year
 * mkn_work.cumulative&n			: where n = 1 to 317, which is the number of port_dates to iterate
 */
 
/* Datasets Produced:
 * mktnet.equities_matched			: name match data combined and appended to main dataset
 * mktnet.equities_unmatched		: same data, still not yet matched to an NCUSIP
 */

%macro combine_matched_data(ds=,start=,finish=);

data &ds;
	set mkn_work.cumulative1;
run;

%do a=2=&start % to &finish ;
	proc append base = &ds data = mkn_work.cumulative&a ; run;
%end;

%mend combine_matched_data;


** First, we combine all the jobarray output datasets into one;

*%combine_matched_data(ds=mkn_work.combined_matched_data,start=2,finish=317);
* NOTE: The data set MKN_WORK.COMBINED_MATCHED_DATA has 612365 observations and 14 variables;



* should have identical columns but now cusip is updated;
data name_matched_data (drop = ncusip);
	set mkn_work.combined_matched_data (drop = comnam totalscore CompA CompB FirstLetterA FirstLetterB NAMEDT NAMEENDT);
	cusip = ncusip;
run;

data equivalent_name_matched_data;
	set mkn_work.combined_matched_data (drop = comnam totalscore ncusip CompA CompB FirstLetterA FirstLetterB NAMEDT NAMEENDT);
run;

* should have identical columns and identical rows;
proc contents data = equivalent_name_matched_data; run;
proc contents data = mktnet.equities_raw; run;

*check it - this should have same nobs as equities_raw because other is a subset;
proc sql;
	create table test_union as
	select * from mktnet.equities_raw
	UNION
	select * from equivalent_name_matched_data;
quit;

/* Dataset observation check:
1. Total non-valid cusip data:
NOTE: The data set MKN_WORK.EQUITIES_RAW has 1020331 observations and 6 variables.
now subdivided into name_matched_data and else
*/

*this gets the unmatched portion of the db but only works if whole row is identical;
proc sql;
	create table mktnet.equities_unmatched as
	select *
	from mktnet.equities_raw
	EXCEPT ALL
	select * from 
	equivalent_name_matched_data;
quit;

/* Dataset observation check:
2. Combine matched data (now with CRSP-based cusips) together with existing good cusip data
NOTE: The data set MKTNET.EQUITIES_VALID_CUSIP has 45696912 observations and 32 variables.
plus name_matched_data above
*/


* need to merge pared down data with full holdings data by rowid;
* should have same NOBS as name_matched_data;
proc sql;
	CREATE TABLE mkn_work.full_data_added_cusip as
	SELECT 	a.rowid, a.fundid, a.port_date, a.port_year, b.cusip, a.type_cd, a.security, a.shares, a.sharechange,
			a.marketvalue, a.weight, a.maturity, a.mat_year, a.coupon, a.type_name, a.prv_port_date, a.num_holdings, a.tot_investment,
			a.eq_style_box, a.fi_style_box,
			a.pct_long_bond, a.pct_long_stock, a.pct_long_preferred, a.pct_long_convertible, a.pct_long_cash, a.pct_long_other,
			a.pct_net_bond, a.pct_net_stock, a.pct_net_preferred, a.pct_net_convertible, a.pct_net_cash, a.pct_net_other
	FROM mktnet.equities_no_cusip as a
	RIGHT JOIN
	name_matched_data as b 
	ON a.rowid = b.rowid;
	
quit;

data mktnet.equities_matched;
	set mktnet.equities_valid_cusip;
run;

proc append base = mktnet.equities_matched data = mkn_work.full_data_added_cusip; run;