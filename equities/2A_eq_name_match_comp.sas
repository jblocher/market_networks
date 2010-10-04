/* *************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    Sept 2010                                                                                                            
/* PROG NAME:       eq_name_match_comp.sas                                                              
/* Project:         Market Interconnectedness and Fires Sales, Momentum
/* This File:       Match the names with no cusips to names in Compustat 
/************************************************************************************/
 
%include 'marketnet_header.sas'; *header file with basic options and libraries;


/* Datasets required to run:
 * mktnet.equities_unmatched				: Equities with no cusips matched yet; security cusip port_date fundid rowid
 * mktnet.comp_raw_nodup					: Comp fundq data; fyearq fqtr datadate conm cusip
 */
 
/* Datasets Produced:
 * mkn_work.cumulative_comp					: output matched dataset
 */


%include '/netscr/jabloche/util/company_macro.sas';
%mfmatch(dataset1=mktnet.equities_unmatched,var1=security,dataset2=mktnet.comp_raw_nodup,var2=conm,out_ds=mkn_work.cumulative_comp);

proc print data = mkn_work.cumulative_comp (obs = 100);
var fundid port_date security conm compa compb totalscore cusip;
run;