USE [CancerReporting]
GO
/****** Object:  UserDefinedFunction LocalConfig.fnSSRS_HyperlinkVariables    Script Date: 15/09/2020 11:26:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION LocalConfig.fnSSRS_HyperlinkVariables (
		@Anonymised int = 0
		,@ReportServerUrl varchar(max) = ''
		,@ReportFolder varchar(max) = ''
		,@ReportName varchar(max) = ''
) RETURNS TABLE AS
RETURN (

/**************************************************************************************************************************************************
Original Work Created Date:	15/09/2020
Original Work Created By:	Matthew Bishop
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				A function that can be configured individually for each organisation locally to instruct the SSRS reports about where
							hyperlinks should redirect to
							You will need to be able to instruct your SSRS reprts what the following locations are:
							1. Your local URL for SCR
							2. Which CARE_ID do you want to display when the report is anonymised (so you can point to a valid CARE_ID on your
							SCR test system
							3. What is the URL for you SSRS report viewer service (not the report server service) - this is needed as the
							report server service doesn't accept parameters being passed via the URL
							4. What is the root PTL folder - the reporting folder structure for SSRS assumes that you put all of your Cancer 
							reporting in a single folder with the PTL / patient-level reports sitting in the root folder and the option to have 
							subfolders to partition other reports into. You could always use linked reports if you need to present some of these
							reports in another structure in SSRS
**************************************************************************************************************************************************/

-- SELECT * FROM LocalConfig.fnSSRS_HyperlinkVariables (DEFAULT, 'http://bsuhreporting.bsuh.nhs.uk/ReportServer', '/Cancer/Test', 'Report2') -- Run Me

/**************************************************************************************************************************************************
-- Return a table with all the variable vlaues that SSRS will need to run the SSRS reports
**************************************************************************************************************************************************/

		SELECT		SCR_Url					=	'https://scr.bsuh.nhs.uk/CancerRegister' + 
												CASE	WHEN @Anonymised != 0 THEN 'Test' ELSE '' END					-- use the test system for anonymised retrieval
					,AnonymisedScrRecordId	=	CASE	WHEN @Anonymised != 0 THEN '16848' END							-- Return null if not needed - SSRS function will handle using IsNothing
					,ReportViewerUrl		=	CASE	WHEN @ReportServerUrl = 'http://svvssrs01.bsuh.nhs.uk/ReportServer'	-- Repoint the local server to the spn for the report viewer (so offsite staff can still access it)
														THEN 'http://bsuhreporting.bsuh.nhs.uk/ReportServer'
														WHEN @ReportServerUrl = 'https://bireports.bsuh.nhs.uk/HDMSQL'	-- Repoint the backup server to live for the report viewer (the backup server doesn't have one)
														THEN 'http://bsuhreporting.bsuh.nhs.uk/ReportServer'
														ELSE ISNULL(@ReportServerUrl, '')
														END
												+ '/Pages/ReportViewer.aspx?'
					,RootPtlFolder			=	CASE	WHEN @ReportFolder LIKE '%/PTL Summaries%' -- is in the PTL summaries folder, or any subfolders
														THEN LEFT(@ReportFolder, CHARINDEX('/PTL Summaries', @ReportFolder)-1)
														ELSE @ReportFolder
														END
					

)
