/* *************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    Aug 2010                                                                                                            
/* PROG NAME:       thomson.sas                                                              
/* Project:         Market Interconnectedness and Fires Sales, Momentum
/* This File:       Analyze the equity holdings we have - CUSIPs? Compare to Thomson s12.
/************************************************************************************/
 
%include 'marketnet_header.sas'; *header file with basic options and libraries;

/* Datasets required to run:
 * thomson.s12								: Data from WRDS
 * morn.portfolio_statistics_only			: Fund level stats, unique by fundid, portfolio date
 */
 
/* Datasets Produced:
 * 
 */

proc contents data = thomson.s12; run;

proc sql;
	/*
	** OK, this gets all share classes. Yuk;
	**Cusip does not help - it is at the holdings level;
	create table thom_funds as
	select month(fdate) as month, year(fdate) as year, count(unique fundno) as count_fundno, count(unique cusip) as count_cusip
	from thomson.s12
	group by fdate;
	*/
	
	create table thom_funds2 as
	select distinct fdate, fundno, assets
	from thomson.s12
	order by fdate;
	
	create table morn_funds as
	select month(port_date) as month, year(port_date) as year, count(unique fundid) as count_fundid
	from morn.portfolio_statistics_only
	group by port_date;
quit;
	 
proc sort data = thom_funds2 out = tester noduprec;
by fdate fundno assets;
run;
	 
proc sql;	
	create table thom_funds3 as
	select month(fdate) as month, year(fdate) as year, count(*) as count_fundno
	from thom_funds2
	group by fdate;
	
	create table fund_compare as
	select a.month,a.year, a.count_fundno, b.count_fundid
	from thom_funds3 as a, morn_funds as b
	where a.month = b.month and a.year = b.year
	order by a.year, a.month;
	
	
quit;

proc print data = fund_compare; run;