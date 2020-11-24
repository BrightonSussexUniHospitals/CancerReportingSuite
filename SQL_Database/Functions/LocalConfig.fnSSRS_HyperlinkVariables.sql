SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [LocalConfig].[fnSSRS_HyperlinkVariables] (
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
							You will need the following information to be able to instruct your SSRS reports what the following locations are:
							1. Your local URL for SCR
							2. Which CARE_ID do you want to display when the report is anonymised (so you can point to a valid CARE_ID on your
							SCR test system
							3. The URL that your SSRS server(s) report when calling the Globals!ReportServerUrl variable. You can find this by
							uploading and opening the Determine_SSRS_Global_Env_Variables.rdl on your SSRS server
							4. The URL for you SSRS report viewer service (not the report server service) - this is needed as the
							report server service doesn't accept parameters being passed via the URL
							5. What is the root PTL folder - the reporting folder structure for SSRS assumes that you put all of your Cancer 
							reporting in a single folder with the PTL / patient-level reports sitting in the root folder and the option to have 
							subfolders to partition other reports into. You could always use linked reports if you need to present some of these
							reports in another structure in SSRS
**************************************************************************************************************************************************/

-- SELECT * FROM LocalConfig.fnSSRS_HyperlinkVariables (DEFAULT, 'http://bsuhreporting.bsuh.nhs.uk/ReportServer', '/Cancer/Test', 'Report2') -- Run Me

/**************************************************************************************************************************************************
-- Return a table with all the variable vlaues that SSRS will need to run the SSRS reports
**************************************************************************************************************************************************/

		SELECT		-- Tell the SSRS reports where to direct hyperlinks to the live SCR (Somerset Cancer Register) site
					SCR_Url					=	CASE	-- When the report isn't anonymised, point to the live SCR URL
														WHEN @Anonymised = 0
														THEN 'https://scr.bsuh.nhs.uk/CancerRegister'							-- Enter your local URL for the production SCR site
														-- When the report is anonymised, point to the test SCR URL
														WHEN @Anonymised != 0 
														THEN 'https://scr.bsuh.nhs.uk/CancerRegisterTest'						-- Enter your local URL for test SCR site
														ELSE '' 
														END
					
					-- Tell the SSRS reports which CARE_ID to use if you're hyperlinking to the test SCR site
					,AnonymisedScrRecordId	=	CASE	-- When the report is anonymised, provide a dummy record (CARE_ID) that will display on the test SCR site 
														WHEN @Anonymised != 0 
														THEN '16848' 
														END																		-- Return null if not needed - SSRS function will handle using IsNothing
					
					-- Tell the SSRS reports where to direct hyperlink to the SSRS report server (the URL in SSRS that can accept parameters in the URL)
					-- This allows you to publish reports in multiple places (i.e. production, test, failover, dev etc) and choose where hyperlinks to other SSRS reports direct towards
					-- This is useful where you may want to see how a change to one report relates to existing live reporting. In BSUH, we use this because in 2 ways:
							-- 1. the ReportServerUrl provided by SSRS points towards the specific machine where SSRS is installed, but we want users to access
							-- the SSRS report viewer using an associated SPN
							-- 2. our secondary SSRS server (used when demand on the main SSRS server is high) doesn't allow parameters in the URL's so all hyperlinks 
							-- need to point back towards the main SSRS server.
					-- It requires a case statement as the ReportServerUrl provided by SSRS will point towards the specific machine where SSRS is installed, but we
					-- want to direct hyperlinks to the report server a particular SPN
					,ReportViewerUrl		=	CASE	-- When the SSRS report is hosted on this particular machine, point hyperlinks towards the following report server URL
														WHEN @ReportServerUrl = 'http://svvssrs01.bsuh.nhs.uk/ReportServer'		-- When hosted on svvssrs01
														THEN 'http://bsuhreporting.bsuh.nhs.uk/ReportServer'					-- Repoint hyperlinks to the bsuhreporting spn for the report viewer (so offsite staff can still access it)
														
														-- When the SSRS report is hosted on this particular machine, point hyperlinks towards the following report server URL
														WHEN @ReportServerUrl = 'https://bireports.bsuh.nhs.uk/HDMSQL'			-- When hosted on bireports
														THEN 'http://bsuhreporting.bsuh.nhs.uk/ReportServer'					-- Repoint hyperlinks to the bsuhreporting spn for the report viewer (so offsite staff can still access it)
														
														-- If there are no specific redirects, point the hyperlinks back to the same URL as the report calling this function
														ELSE ISNULL(@ReportServerUrl, '')
														END
												+ '/Pages/ReportViewer.aspx?'
					
					-- Tell the SSRS reports where the root folder (which contains the main Cancer PTL) can be found. For every subfolder you create within the
					-- root folder, you should enter a WHEN clause case statement to identify the subfolder and a THEN clause to direct SSRS back to the root
					-- folder above
					,RootPtlFolder			=	CASE	WHEN @ReportFolder LIKE '%/PTL Summaries%' -- is in the PTL summaries folder, or any subfolders
														THEN LEFT(@ReportFolder, CHARINDEX('/PTL Summaries', @ReportFolder)-1)
														WHEN @ReportFolder LIKE '%/PTL Custom Versions%' -- is in the PTL summaries folder, or any subfolders
														THEN LEFT(@ReportFolder, CHARINDEX('/PTL Custom Versions', @ReportFolder)-1)
														ELSE @ReportFolder
														END
					

)
GO
