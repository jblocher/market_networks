/* *************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    Aug 2010                                                                                                            
/* PROG NAME:       equities.sas                                                              
/* Project:         Market Interconnectedness and Fires Sales, Momentum
/* This File:       Analyze the equity holdings we have - CUSIPs? Compare to Thomson s12.
/************************************************************************************/
 
%include 'marketnet_header.sas'; *header file with basic options and libraries;


/* Datasets required to run:
 * morn.master_morn_holdings				: Master Dataset with all holdings and fund stats
 */
 
/* Datasets Produced:
 * mktnet.mastmornhold_equities				: Removed columns not needed, bad portfolio weights
 */


** First, we drop some of the less necessary variables;

/*
data mkn_work.mornholdings_pared;
	set morn.master_morn_holdings (drop = 	pct_long_bond pct_long_cash pct_long_convertible pct_long_other pct_long_preferred pct_long_stock 
											pct_net_bond pct_net_cash pct_net_convertible pct_net_other pct_net_preferred pct_net_stock 
											pct_sector_1-pct_sector_12 country industry_code sector_code sector_name stkid);
run;

data mkn_work.mornholdings_pared;
	set morn.master_morn_holdings (drop = 	pct_sector_1-pct_sector_12 country industry_code sector_code sector_name stkid);
run;
/*
NOTE: There were 92561476 observations read from the data set MORN.MASTER_MORN_HOLDINGS.
NOTE: The data set MKN_WORK.MORNHOLDINGS_PARED has 92561476 observations and 32 variables.
NOTE: DATA statement used (Total process time):
      real time           52:17.02
      cpu time            1:40.90
*/

** Next, lets work with equities only for now;

** Need to be careful with sample selection - cannot just select portfolios with equities;
** Need to identify portfolios which have ever held equities and then choose a threshold whereby funds are excluded;
/*
proc sort data = mkn_work.mornholdings_pared out = mkn_work.fund_level_data nodupkey;
by port_date fundid;
run;
NOTE: There were 92561476 observations read from the data set MKN_WORK.MORNHOLDINGS_PARED.
NOTE: 92046362 observations with duplicate key values were deleted.
NOTE: The data set MKN_WORK.FUND_LEVEL_DATA has 515114 observations and 32 variables.
NOTE: PROCEDURE SORT used (Total process time):
      real time           16:47.59
      cpu time            1:27.35
*/

/*
data fund_level_data2;
	set mkn_work.fund_level_data;
	* this is intentional. If pct_net_stock is negative and long is 0, that means they are fully short, but we want to keep it;
	if ( pct_long_stock = 0 and pct_net_stock = 0 ) then no_stock = 1;
	else no_stock = 0;
run;

proc sql;
	create table nostock_summary as
	select fundid, sum(no_stock) as count_no_stock, count(*) as num_obs, 
			(calculated count_no_stock)/(calculated num_obs) as pct_no_stock
	from fund_level_data2
	group by fundid;
quit;


/* HISTOGRAM: Based on this U-shaped curve, cutoff of .8 looks good
proc univariate data = nostock_summary;
where 1 > pct_no-stock > 0;
histogram pct_no_stock;
run;
*/


/*
* Keep the set of fundids where they hold some stock 20% of the time;
proc sql;
	create table mkn_work.fund_level_equities_selection as
	select fundid
	from nostock_summary
	where pct_no_stock < 0.8;
quit;

** Here, we identify funds which have stock;

proc sql;
	create table mkn_work.equity_funds as
	select a.*
	from mkn_work.mornholdings_pared as a, mkn_work.fund_level_equities_selection as b
	where a.fundid = b.fundid;
quit;
/*
NOTE: Table MKN_WORK.EQUITY_FUNDS created, with 70835096 rows and 32 columns.

107        quit;
NOTE: PROCEDURE SQL used (Total process time):
      real time           35:44.96
      cpu time            1:25.90
*/


/*
*test should equal 8082 or same amount of records in mkn_work.fund_level_equities_selection;
proc sort data = mkn_work.equity_funds out = tester nodupkey;
by fundid;
run;

/*
NOTE: There were 70835096 observations read from the data set MKN_WORK.EQUITY_FUNDS.
NOTE: 70827014 observations with duplicate key values were deleted.
NOTE: The data set WORK.TESTER has 8082 observations and 32 variables.
NOTE: PROCEDURE SORT used (Total process time):
      real time           17:19.65
      cpu time            48.25 seconds
*/



	/*
	 * My investigation showed two things: 
	 * 1. Short positions were not listed as negative weights. Solved above.
	 * 2. Short position and Long position weights are based on Long-only denominator
	 * 3. This is not always a good assumption. In some portfolios, short = funding, others it is an investment
	 * 4. There are a handful of data errors, fixed below
	 */
	 
/*
data mkn_work.equity_funds_alt mkn_work.equity_funds_badweight;
	set mkn_work.equity_funds;

	* If marketvalue is negative, then by def it is a short position;
	if marketvalue < 0 and weight > 0 then weight = -1 * weight;
	
	 * fix data errors;
	 if missing(weight) then delete;
	 
	 if (weight > 3000) or (weight < -3000) then output mkn_work.equity_funds_badweight;
	 else output mkn_work.equity_funds_alt;
	 
run;

*Now, as a final check, lets see how our weight summary does;
*it still gives some outliers, which we have to assume are data errors;
*so, finally we truncate;

**** Now, lets get some stats on it ***;
**** REALLY long ******;
proc sql;
	create table morn_port_stats_sum as
	select 	port_date, fundid,
			sum(weight) as sum_port_weight, 
			sum(marketvalue) as sum_mkt_val,
			count(type_cd) as num_holdings_calc
	from mkn_work.equity_funds_alt
	group by port_date, fundid;
quit;
proc sort data = mkn_work.equity_funds_alt out = funds_only nodupkey;
by port_date fundid;
run;
proc sql;
	create table ms_work.morn_port_stats as
	select 	a.port_date, a.fundid, year(a.port_date) as port_year, b.sum_port_weight,
			a.tot_investment, b.sum_mkt_val,
			a.num_holdings, b.num_holdings_calc,
			a.pct_long_bond, a.pct_long_cash, a.pct_long_convertible, a.pct_long_other, a.pct_long_preferred, a.pct_long_stock, 
			a.pct_net_bond, a.pct_net_cash, a.pct_net_convertible, a.pct_net_other, a.pct_net_preferred, a.pct_net_stock
	from funds_only as a, morn_port_stats_sum as b
	where a.port_date = b.port_date and a.fundid = b.fundid;
quit;
*/
** End creating main stat db;

* This is pretty fast - just compute som summary stats;
data test_morn_stats;
	set ms_work.morn_port_stats;
	** all of these should be zero;
	mkt_val_diff = sum_mkt_val - tot_investment;
	weight_diff = sum_port_weight - 100;
	num_hold_diff = num_holdings_calc - num_holdings;
	
	pct_long_diff = pct_long_bond+ pct_long_cash+ pct_long_convertible+ pct_long_other+ pct_long_preferred+ pct_long_stock - 100;
	pct_net_diff = pct_net_bond+ pct_net_cash+ pct_net_convertible+ pct_net_other+ pct_net_preferred+ pct_net_stock - 100;
	
	if -25 <= weight_diff <= 25 then weight_problem = 0;
	else weight_problem = 1;
run;

title 'Before Truncation';
proc univariate data = test_morn_stats;
var mkt_val_diff weight_diff num_hold_diff pct_net_diff;
run;


* This truncates at 1 and 99 based on weight difference from 100 - assume data errors;
%include '/netscr/jabloche/util/winsorize_truncate.sas';
%WT(data=test_morn_stats, out=mkn_work.trunc_final_fund_data, byvar=none, vars=weight_diff, type = T, pctl = 1 99, drop= Y);

title 'After Truncation';
proc univariate data = mkn_work.trunc_final_fund_data;
var mkt_val_diff weight_diff num_hold_diff pct_net_diff;
run;

** Final output dataset **;
proc sql;
	create table mktnet.mastmornhold_equities as
	select a.*
	from mkn_work.mornholdings_pared as a, mkn_work.trunc_final_fund_data as b
	where a.fundid = b.fundid and a.port_date=b.port_date;
quit;

*NOTE: Table MKTNET.MASTMORNHOLD_EQUITIES created, with 60030476 rows and 32 columns;

*test - should equal nobs of trunc_final_fund_data;
proc sort data = mktnet.mastmornhold_equities out = tester nodupkey;
by fundid port_date;
run;
*NOTE: The data set WORK.TESTER has 392044 observations and 32 variables;
