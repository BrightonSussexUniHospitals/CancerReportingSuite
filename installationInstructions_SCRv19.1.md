# Installation


## Installation Pre-Requisites
The installation scripts assume you have:
* created a database called CancerReporting. The "Create CancerReporting Database" script will do this, but you will need to set the path for the mdf and ldf files to the appropriate location for your environment. If you want to use a database with a different name, you'll need to change the USE statement at the beginning of each script to point at your database
* a replica of your CancerRegister database in the same instance where the CancerReporting database is being installed

## SQL Database Installation instructions
1. Install the schemas (in the security folder)
1. Install the tables
1. Run the data scripts to populate the reference data (in the Data folder)
1. Enter the ODS code for your organisation into the LocalConfig.fnOdsCode script (in the functions folder)
1. Install the functions
1. Install the views
1. Alter the final dynamic SQL section of the LocalConfig.uspCreateReplicaViews script to point at your replica server (in the Stored Procedures folder)
1. Install the stored procedures in the following order:
	1. CancerTransactions.uspCaptureEstimatedBreach
	1. LocalConfig.uspCreateReplicaViews
	1. SCR_Reporting.UspSSRS_2wwPTLSummary
	1. SCR_Reporting.UspSSRS_2wwPTL_FirstSeen
	1. SCR_Reporting.uspSSRS_cwtStatus
	1. SCR_Reporting.uspSSRS_IPTsAndComments
	1. SCR_Reporting.uspSSRS_NextActions_History
	1. SCR_Reporting.uspSSRS_PatientDetails
	1. SCR_Reporting.uspSSRS_PTL
	1. SCR_Warehouse.uspUpdateProcessAudit
	1. SCR_Warehouse.uspUpdateProcessAuditHistory
	1. SCR_Reporting_History.uspCreateSCR_PTL_LT_Census
	1. SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory
	1. SCR_Reporting_History.uspCreateSCR_PTL_Statistics
	1. SCR_Reporting_History.uspCreateSomersetReportingHistory
	1. SCR_Reporting_History.uspTrimSCR_PTL_History
	1. SCR_Reporting_History.uspUpdateLastPTL_Record
	1. SCR_Warehouse.uspCaptureNextActionChanges
	1. SCR_Warehouse.uspCreateSomersetReportingData
	1. SCR_Warehouse.uspScheduleSomersetReportingData
1. EXEC LocalConfig.uspCreateReplicaViews to create the LocalConfig views of your replicated data
1. Install the jobs

Once the jobs have been installed and start running, the SQL database should populate with your data and automatically refresh after the initial bulk load of data has happened

## SQL Reporting Services Installation instructions
1. Create a shared data source to connect to *your Cancer Reporting database*
	1. Set the connection string as: Data Source=*<your sql server>*;Initial Catalog=*<your cancer reporting database>*
1. Create an SSRS folder where you want your live PTL reporting and set up the appropriate security. This will be your "root" cancer PTL folder
1. Alter the LocalConfig.fnSSRS_HyperlinkVariables so that the fields have the correct values
1. Install the Cancer_SSRS_PTL_2016.rdl file in root cancer PTL folder with the name *Cancer_SSRS_PTL_Complete*
1. In the management page for the *Cancer_SSRS_PTL_Complete* report, set the data source to use the shared data source that you previously created
1. Create a linked report to the Cancer_SSRS_PTL_Complete report with:
	1. the name Cancer_SSRS_PTL_2016
	1. the cwtPathwayType parameter set as hidden
1. Install the following rdl files in the root folder with the same name as their file name
	1. Cancer_SSRS_CommentHistory.rdl
	1. Cancer_SSRS_NextActionHistory.rdl
	1. Run uspCaptureEstimatedBreach.rdl
1. In the management pages for the reports you just uploaded, set the data source to use the shared data source that you previously created
1. In the SSRS folder where your live PTL reporting is, create a subfolder for the PTL summaries
1. Install the following rdl files in the PTL summaries subfolder
	1. Cancer_SSRS_2ww_Summary.rdl
	1. Cancer_SSRS_LivePTL_Summary.rdl
1. In the management pages for the reports you just uploaded, set the data source to use the shared data source that you previously created