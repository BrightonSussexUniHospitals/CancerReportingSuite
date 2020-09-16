#Release Notes

##Reporting Caveats
* The 62 day & 2WW PTL has be extensively reconciled against the BSUH PTL, which highlighted a number of data quality errors within the BSUH data. You will need to check the reporting output from this Cancer Reporting suite before using it operationally
* The Faster Diagnosis PTL is still under evaluation at BSUH. We are reconciling the PTL against the output from SCR to ensure there are no discrepancies for the BSUH data. Updates will be uploaded to this repository once we have completed this
* Although the reporting has the elements in place to report CWT 31 day pathways, they are currently not functioning

##Technical Notes
* There is a LocalConfig schema, the content of which is designed to allow each organisation to have its own local configurations whilst operating with a shared codebase. We have provided the configuration data that BSUH has used to offer a starting configuration, but there will be items that you'll need to alter to your own local needs. Have a look at all the functions, stored procedures and data for tables in the LocalConfig schema before you install the code to see if you would like to make any changes
* The SQL environment where the Cancer Reporting suite is installed should be in the same SQL instance as a replicated copy of your SCR data. Although it is technically possible to use the SCR production database or to a replicated copy on another instance, this will have significant negative performance implications - we cannot underemphasise how strongly we recommend that you do not do this
* The version of SQL this has been developed with is SQL 2016. We've not tested it in other versions of SQL server, although we think there would be minimal work to implement the code on older or newer versions
* The version of SQL reporting services the reports have been developed with is SQL 2016. We have tested the reports with a 2008R2 report server - the rdl files need to be rebuilt in visual studio with the compatability set for 2008R2, but the reports work well
