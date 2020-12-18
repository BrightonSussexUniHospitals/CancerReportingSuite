SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [SCR_Reporting].[uspSSRS_PTL]
	(@DataSource int
	,@cwtStatus varchar(max) = ''
	,@CancerSite varchar(max) = ''
	,@NextAction varchar(max) = ''
	,@NextActionOwner varchar (max) = '' 
	,@NextActionSpecific varchar (max) = ''
	,@HospID varchar (max) = ''
	,@Escalation varchar (max) = ''
	,@Workflow int = 0
	,@EstimatedBreach varchar (max) = ''
	,@Anonymised int = 0
	,@cwtStandardId int
	,@ReportingcwtTypeID varchar (max) = ''
	,@PathwayLengthFilterId int = null
	
	)
AS

/******************************************************** © Copyright & Licensing ****************************************************************
© 2020 Perspicacity Ltd & Brighton & Sussex University Hospitals

This code / file is part of Perspicacity & BSUH's Cancer Data Warehouse & Reporting suite.

This Cancer Data Warehouse & Reporting suite is free software: you can 
redistribute it and/or modify it under the terms of the GNU Affero 
General Public License as published by the Free Software Foundation, 
either version 3 of the License, or (at your option) any later version.

This Cancer Data Warehouse & Reporting suite is distributed in the hope 
that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

A full copy of this code can be found at https://github.com/BrightonSussexUniHospitals/CancerReportingSuite

You may also be interested in the other repositories at https://github.com/perspicacity-ltd or
https://github.com/BrightonSussexUniHospitals

Original Work Created Date:	01/10/2019
Original Work Created By:	Perspicacity Ltd (Matthew Bishop) & BSUH (Lawrence Simpson)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk / lawrencesimpson@nhs.net
Description:				This procedure returns the datasets for reporting the PTL in a reporting tool
**************************************************************************************************************************************************/

/*

EXEC SCR_Reporting.uspSSRS_PTL @DataSource = 1, @cwtStandardId = 4, @cwtStatus = '14¿2', @CancerSite = NULL , @PathwayLengthFilterId = 3 -- test me
*/


/************************************************************************************************************************************************************************************************************
-- Understanding the parameters for this stored procedure
	-- @DataSource
	This parameter determines whether the stored procedure will return the most recently persisted snapshot 
	of the PTL dataset, or a daily snapshot that is taken to preserve the PTL at a particular point in time
	It has 4 possible values:
		1	Return the most recently persisted (live) snapshot of the PTL
		2	Return the daily PTL snapshot
		3	Return the Selective Update PTL snapshot - updates but with no new additions showing
		4	Return a weekly snapshot PTL

************************************************************************************************************************************************************************************************************/

		-- Don't return any rowcounts unless explicitly printed
		SET NOCOUNT ON
		
		-- Declare procedure variables
		DECLARE @xml xml

/************************************************************************************************************************************************************************************************************
-- Convert the SSRS multi-value parameters into meaningful datasets for a SQL query
************************************************************************************************************************************************************************************************************/

		-- for every new parameter add statement below and add #table to join in Data Output to where clause in SELECT statment below
		
		-- Convert the @cwtStatus parameter into an XML string
		SET @xml = CAST('<SubValue>' + REPLACE(@cwtStatus, ',', '</SubValue><SubValue>') + '</SubValue>' AS XML)

		-- Convert the @cwtStatus xml string into a cwt status dataset
		SELECT N.value('.', 'varchar(255)') AS cwtStatusIdText, CAST(NULL AS int) AS cwtStatusId INTO #cwtStatus FROM @xml.nodes('SubValue') as T(N)

		-- Determine the cwtStatusId from cwtStatusIdText
		IF @cwtStatus != '' 
		BEGIN
		UPDATE #cwtStatus SET cwtStatusId = CAST(LEFT(cwtStatusIdText, CHARINDEX('¿', cwtStatusIdText)-1) AS int)
		END

		-- Convert the @CancerSite parameter into an XML string
		SET @xml = CAST('<SubValue>' + REPLACE(@CancerSite, ',', '</SubValue><SubValue>') + '</SubValue>' AS XML)

		-- Convert the @CancerSite xml string into a cwt site dataset
		SELECT N.value('.', 'varchar(255)') AS CancerSiteBS INTO #CancerSiteBS FROM @xml.nodes('SubValue') as T(N)

		
		-- Convert the @NextAction parameter into an XML string
		SET @xml = CAST('<SubValue>' + REPLACE(@NextAction, ',', '</SubValue><SubValue>') + '</SubValue>' AS XML)
		
		-- Convert the @NextAction xml string into a next action dataset
		SELECT N.value('.', 'varchar(255)') AS NextAction INTO #NextAction FROM @xml.nodes('SubValue') as T(N)

			-- Convert the @NextActionOwner parameter into an XML string
		SET @xml = CAST('<SubValue>' + REPLACE(@NextActionOwner, ',', '</SubValue><SubValue>') + '</SubValue>' AS XML)
		
		-- Convert the @NextActionOwner xml string into a next action owner dataset
		SELECT N.value('.', 'varchar(255)') AS NextActionOwner INTO #NextActionOwner FROM @xml.nodes('SubValue') as T(N)


			-- Convert the @NextActionSpecific parameter into an XML string
		SET @xml = CAST('<SubValue>' + REPLACE(@NextActionSpecific, ',', '</SubValue><SubValue>') + '</SubValue>' AS XML)
		
		-- Convert the @NextActionSpecific xml string into a next action owner dataset
		SELECT N.value('.', 'varchar(255)') AS NextActionSpecific INTO #NextActionSpecific FROM @xml.nodes('SubValue') as T(N)


				-- Convert the @Escalation parameter into an XML string
		SET @xml = CAST('<SubValue>' + REPLACE(@Escalation, ',', '</SubValue><SubValue>') + '</SubValue>' AS XML)
		
		-- Convert the @Escalation xml string into an escalation dataset
		SELECT N.value('.', 'varchar(255)') AS Escalation INTO #Escalation FROM @xml.nodes('SubValue') as T(N)


				-- Convert the @EstimatedBreach parameter into an XML string
		SET @xml = CAST('<SubValue>' + REPLACE(@EstimatedBreach, ',', '</SubValue><SubValue>') + '</SubValue>' AS XML)
		
		-- Convert the @EstimatedBreach xml string into an escalation dataset
		SELECT N.value('.', 'varchar(255)') AS EstimatedBreach INTO #EstimatedBreach FROM @xml.nodes('SubValue') as T(N)


				-- Convert the @ReportingcwtTypeID parameter into an XML string
		SET @xml = CAST('<SubValue>' + REPLACE(@ReportingcwtTypeID, ',', '</SubValue><SubValue>') + '</SubValue>' AS XML)
		
		-- Convert the @ReportingcwtTypeID xml string into an escalation dataset
		SELECT N.value('.', 'varchar(255)') AS ReportingcwtTypeID INTO #ReportingcwtTypeID FROM @xml.nodes('SubValue') as T(N)




/************************************************************************************************************************************************************************************************************
-- Data Output
************************************************************************************************************************************************************************************************************/

		DECLARE @SnapshotTime datetime
		SET @SnapshotTime = GETDATE()
		
		-- Create the temp #PTL table for inserting records into
		-- using a temp table so that the CancerReporting tables aren't locked whilst streaming the dataset to the remote destination		
		SELECT		TOP 0
					PTL.CARE_ID
					,PTL.CWT_ID
					,PTL.Pathway
					,PTL.CancerSiteBS
					,PTL.Forename
					,PTL.Surname
					,PTL.HospitalNumber
					,PTL.NHSNumber
					,PTL.ReportingPathwayLength
					,PTL.OrgCodeFirstSeen
					,PTL.OrgDescFirstSeen
					,PTL.TrackingNotes
					,PTL.DateLastTracked
					,PTL.CommentUser
					,PTL.DaysSinceLastTracked
					,PTL.Weighting
					,PTL.DominantCWTStatusDesc
					,PTL.DaysToNextBreach
					,PTL.DominantColourValue
					,PTL.DominantPriority
					,PTL.NextActionDesc
					,PTL.NextActionSpecificDesc
					,PTL.NextActionTargetDate
					,PTL.DaysToNextAction
					,PTL.OwnerDesc
					,PTL.Escalated
					,PTL.NextActionColourValue
					,PTL.EstimatedBreachMonth
					,PTL.EstimatedWeight
					,PTL.EBMonthValue
		INTO		#PTL
		FROM		SCR_Reporting.PTL_Live PTL
		

		
		IF @DataSource = 1
		BEGIN
		
				-- Return the PTL data
				INSERT INTO	#PTL	
				SELECT		PTL.CARE_ID
							,PTL.CWT_ID
							,PTL.Pathway
							,PTL.CancerSiteBS
							,PTL.Forename
							,PTL.Surname
							,PTL.HospitalNumber
							,PTL.NHSNumber
							,CASE	WHEN @cwtStandardId = 1
									THEN ISNULL(PTL.WillBeWaitingtime2WW, PTL.Waitingtime2WW)
									WHEN @cwtStandardId = 2
									THEN PTL.Waitingtime28
									WHEN @cwtStandardId = 3
									THEN PTL.Waitingtime31
									WHEN @cwtStandardId = 4
									THEN PTL.Waitingtime62
									END
							,PTL.OrgCodeFirstSeen
							,PTL.OrgDescFirstSeen
							,PTL.TrackingNotes
							,PTL.DateLastTracked
							,PTL.CommentUser
							,PTL.DaysSinceLastTracked
							,PTL.Weighting
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.CWTStatusDesc2WW
									WHEN @cwtStandardId = 2
									THEN PTL.CWTStatusDesc28
									WHEN @cwtStandardId = 3
									THEN PTL.CWTStatusDesc31
									WHEN @cwtStandardId = 4
									THEN PTL.CWTStatusDesc62
									END
							,PTL.DaysToNextBreach
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.ColourValue2WW
									WHEN @cwtStandardId = 2
									THEN PTL.ColourValue28Day
									WHEN @cwtStandardId = 3
									THEN PTL.ColourValue31Day
									WHEN @cwtStandardId = 4
									THEN PTL.ColourValue62Day
									END
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.Priority2WW
									WHEN @cwtStandardId = 2
									THEN PTL.Priority28
									WHEN @cwtStandardId = 3
									THEN PTL.Priority31
									WHEN @cwtStandardId = 4
									THEN PTL.Priority62
									END
							,PTL.NextActionDesc
							,PTL.NextActionSpecificDesc
							,PTL.NextActionTargetDate
							,PTL.DaysToNextAction
							,PTL.OwnerDesc
							,PTL.Escalated
							,PTL.NextActionColourValue
							,PTL.EstimatedBreachMonth
							,PTL.EstimatedWeight
							,PTL.EBMonthValue
				FROM		SCR_Reporting.PTL_Live PTL WITH (NOLOCK)
				
				LEFT JOIN	SCR_Warehouse.Workflow wf WITH (NOLOCK)
								ON	PTL.CWT_ID = wf.IdentityTypeRecordId
								AND	wf.WorkflowID = @Workflow
								AND	wf.IdentityTypeId = 2
			
				LEFT JOIN	#cwtStatus cwtStatus
								ON	CASE	WHEN @cwtStandardId = 1
											THEN PTL.CwtStatusCode2WW
											WHEN @cwtStandardId = 2
											THEN PTL.CwtStatusCode28
											WHEN @cwtStandardId = 3
											THEN PTL.CwtStatusCode31
											WHEN @cwtStandardId = 4
											THEN PTL.CwtStatusCode62
											END = cwtStatus.cwtStatusId
				LEFT JOIN	#CancerSiteBS cs
								ON	PTL.CancerSiteBS = cs.CancerSiteBS
				LEFT JOIN	#NextAction na
								ON isnull(PTL.NextActionId,0) = na.NextAction
				LEFT JOIN	#NextActionOwner nao
								ON isnull(PTL.OwnerId,0) = nao.NextActionOwner
				LEFT JOIN	#NextActionSpecific nas
								ON isnull(PTL.NextActionSpecificId,0) = nas.NextActionSpecific
				LEFT JOIN	#Escalation esc
								ON isnull(PTL.Escalated,2) = esc.Escalation										--changes NULL values to a 2 - No escalation
				LEFT JOIN	#EstimatedBreach EB_filter
								ON PTL.EBMonthValue = EB_filter.EstimatedBreach
				LEFT JOIN	#ReportingcwtTypeID RCTI
								ON	PTL.ReportingcwtTypeID = RCTI.ReportingcwtTypeID
				LEFT JOIN	LocalConfig.PathwayLengthFilter plf ON plf.PathwayLengthFilterId = @PathwayLengthFilterId  -- catches hidden SSRS parameter of pathway length
				WHERE		/*CASE	WHEN @cwtStandardId = 1
									THEN PTL.cwtFlag2WW
									WHEN @cwtStandardId = 2
									THEN PTL.cwtFlag28
									WHEN @cwtStandardId = 3
									THEN PTL.cwtFlag31
									WHEN @cwtStandardId = 4
									THEN PTL.cwtFlag62
									END = 1
				AND			*/([HospitalNumber]= @HospID															--allows Hospital Number to be entered as a parameter
				OR			(ISNULL(@HospID,'') = ''															--or if the Hospital Number is null
								AND		((cwtStatus.cwtStatusId IS NOT NULL												--and the CWT Status parameter is entered
											OR		ISNULL(@cwtStatus, '') = '')										
											AND		(cs.CancerSiteBS IS NOT NULL										--or the Cancer Site parameter is complete
											OR		ISNULL(@CancerSite, '') = '')
											AND		(na.NextAction IS NOT NULL											--or the Next Action parameter is complete
											OR		ISNULL(@NextAction, '') = '')
											AND		(nao.NextActionOwner IS NOT NULL									--or the Next Action Owner parameter is complete
											OR		ISNULL(@NextActionOwner, '') = '')
											AND		(nas.NextActionSpecific IS NOT NULL									--or the Next Action Specific parameter is complete
											OR		ISNULL(@NextActionSpecific, '') = '')											
											AND		(esc.Escalation IS NOT NULL											--or the Escalation parameter is complete
											OR		ISNULL(@Escalation, '') = '')
											AND		(EB_filter.EstimatedBreach IS NOT NULL
											OR		ISNULL(@EstimatedBreach,'') = '') 
										)
								AND		(	wf.WorkflowID IS NOT NULL
										OR	@Workflow = 0
										)
								AND (PTL.ReportingPathwayLength >= plf.LowerBound OR plf.LowerBound IS NULL)
								AND (PTL.ReportingPathwayLength <= plf.UpperBound OR plf.UpperBound IS NULL)	
								AND (RCTI.ReportingcwtTypeID IS NOT NULL OR ISNULL(@ReportingcwtTypeID, '') = '')
							))


				PRINT CAST(@@ROWCOUNT AS varchar(255)) + ' rows inserted for @DataSource ' + CAST(@DataSource AS varchar(255))
			
		END

		IF @DataSource = 2
		BEGIN
		
				-- Return the PTL data
				INSERT INTO	#PTL	
				SELECT		PTL.CARE_ID
							,PTL.CWT_ID
							,PTL.Pathway
							,PTL.CancerSiteBS
							,PTL.Forename
							,PTL.Surname
							,PTL.HospitalNumber
							,PTL.NHSNumber
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.Waitingtime2WW
									WHEN @cwtStandardId = 2
									THEN PTL.Waitingtime28
									WHEN @cwtStandardId = 3
									THEN PTL.Waitingtime31
									WHEN @cwtStandardId = 4
									THEN PTL.Waitingtime62
									END
							,PTL.OrgCodeFirstSeen
							,PTL.OrgDescFirstSeen
							,PTL.TrackingNotes
							,PTL.DateLastTracked
							,PTL.CommentUser
							,PTL.DaysSinceLastTracked
							,PTL.Weighting
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.CWTStatusDesc2WW
									WHEN @cwtStandardId = 2
									THEN PTL.CWTStatusDesc28
									WHEN @cwtStandardId = 3
									THEN PTL.CWTStatusDesc31
									WHEN @cwtStandardId = 4
									THEN PTL.CWTStatusDesc62
									END
							,PTL.DaysToNextBreach
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.ColourValue2WW
									WHEN @cwtStandardId = 2
									THEN PTL.ColourValue28Day
									WHEN @cwtStandardId = 3
									THEN PTL.ColourValue31Day
									WHEN @cwtStandardId = 4
									THEN PTL.ColourValue62Day
									END
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.Priority2WW
									WHEN @cwtStandardId = 2
									THEN PTL.Priority28
									WHEN @cwtStandardId = 3
									THEN PTL.Priority31
									WHEN @cwtStandardId = 4
									THEN PTL.Priority62
									END
							,PTL.NextActionDesc
							,PTL.NextActionSpecificDesc
							,PTL.NextActionTargetDate
							,PTL.DaysToNextAction
							,PTL.OwnerDesc
							,PTL.Escalated
							,PTL.NextActionColourValue
							,PTL.EstimatedBreachMonth
							,PTL.EstimatedWeight
							,PTL.EBMonthValue	
				FROM		SCR_Reporting.PTL_Daily PTL WITH (NOLOCK)
				
				LEFT JOIN	SCR_Warehouse.Workflow wf WITH (NOLOCK)
								ON	PTL.CWT_ID = wf.IdentityTypeRecordId
								AND	wf.WorkflowID = @Workflow
								AND	wf.IdentityTypeId = 2
			
				LEFT JOIN	#cwtStatus cwtStatus
								ON	PTL.DominantCWTStatusCode = cwtStatus.cwtStatusId
				LEFT JOIN	#CancerSiteBS cs
								ON	PTL.CancerSiteBS = cs.CancerSiteBS
				LEFT JOIN	#NextAction na
								ON isnull(PTL.NextActionId,0) = na.NextAction
				LEFT JOIN	#NextActionOwner nao
								ON isnull(PTL.OwnerId,0) = nao.NextActionOwner
				LEFT JOIN	#NextActionSpecific nas
								ON isnull(PTL.NextActionSpecificId,0) = nas.NextActionSpecific
				LEFT JOIN	#Escalation esc
								ON isnull(PTL.Escalated,2) = esc.Escalation										--changes NULL values to a 2 - No escalation
				LEFT JOIN	#EstimatedBreach EB_filter
								ON PTL.EBMonthValue = EB_filter.EstimatedBreach
				LEFT JOIN	#ReportingcwtTypeID RCTI
								ON	PTL.ReportingcwtTypeID = RCTI.ReportingcwtTypeID
				LEFT JOIN	LocalConfig.PathwayLengthFilter plf ON plf.PathwayLengthFilterId = @PathwayLengthFilterId  -- catches hidden SSRS parameter of pathway length
				WHERE		CASE	WHEN @cwtStandardId = 1
									THEN PTL.cwtFlag2WW
									WHEN @cwtStandardId = 2
									THEN PTL.cwtFlag28
									WHEN @cwtStandardId = 3
									THEN PTL.cwtFlag31
									WHEN @cwtStandardId = 4
									THEN PTL.cwtFlag62
									END = 1
				AND			([HospitalNumber]= @HospID															--allows Hospital Number to be entered as a parameter
				OR			(ISNULL(@HospID,'') = ''															--or if the Hospital Number is null
								AND		((cwtStatus.cwtStatusId IS NOT NULL												--and the CWT Status parameter is entered
											OR		ISNULL(@cwtStatus, '') = '')										
											AND		(cs.CancerSiteBS IS NOT NULL										--or the Cancer Site parameter is complete
											OR		ISNULL(@CancerSite, '') = '')
											AND		(na.NextAction IS NOT NULL											--or the Next Action parameter is complete
											OR		ISNULL(@NextAction, '') = '')
											AND		(nao.NextActionOwner IS NOT NULL									--or the Next Action Owner parameter is complete
											OR		ISNULL(@NextActionOwner, '') = '')
											AND		(nas.NextActionSpecific IS NOT NULL									--or the Next Action Specific parameter is complete
											OR		ISNULL(@NextActionSpecific, '') = '')											
											AND		(esc.Escalation IS NOT NULL											--or the Escalation parameter is complete
											OR		ISNULL(@Escalation, '') = '')
											AND		(EB_filter.EstimatedBreach IS NOT NULL
											OR		ISNULL(@EstimatedBreach,'') = '') 
										)
								AND		(	wf.WorkflowID IS NOT NULL
										OR	@Workflow = 0
										)
								AND (PTL.ReportingPathwayLength >= plf.LowerBound OR plf.LowerBound IS NULL)
								AND (PTL.ReportingPathwayLength <= plf.UpperBound OR plf.UpperBound IS NULL)	
								AND (RCTI.ReportingcwtTypeID IS NOT NULL OR ISNULL(@ReportingcwtTypeID, '') = '')
							))

				PRINT CAST(@@ROWCOUNT AS varchar(255)) + ' rows inserted for @DataSource ' + CAST(@DataSource AS varchar(255))
			
		END

		IF @DataSource = 3
		BEGIN
		
				-- Return the PTL data
				INSERT INTO	#PTL	
				SELECT		PTL.CARE_ID
							,PTL.CWT_ID
							,PTL.Pathway
							,PTL.CancerSiteBS
							,PTL.Forename
							,PTL.Surname
							,PTL.HospitalNumber
							,PTL.NHSNumber
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.Waitingtime2WW
									WHEN @cwtStandardId = 2
									THEN PTL.Waitingtime28
									WHEN @cwtStandardId = 3
									THEN PTL.Waitingtime31
									WHEN @cwtStandardId = 4
									THEN PTL.Waitingtime62
									END
							,PTL.OrgCodeFirstSeen
							,PTL.OrgDescFirstSeen
							,PTL.TrackingNotes
							,PTL.DateLastTracked
							,PTL.CommentUser
							,PTL.DaysSinceLastTracked
							,PTL.Weighting
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.CWTStatusDesc2WW
									WHEN @cwtStandardId = 2
									THEN PTL.CWTStatusDesc28
									WHEN @cwtStandardId = 3
									THEN PTL.CWTStatusDesc31
									WHEN @cwtStandardId = 4
									THEN PTL.CWTStatusDesc62
									END
							,PTL.DaysToNextBreach
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.ColourValue2WW
									WHEN @cwtStandardId = 2
									THEN PTL.ColourValue28Day
									WHEN @cwtStandardId = 3
									THEN PTL.ColourValue31Day
									WHEN @cwtStandardId = 4
									THEN PTL.ColourValue62Day
									END
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.Priority2WW
									WHEN @cwtStandardId = 2
									THEN PTL.Priority28
									WHEN @cwtStandardId = 3
									THEN PTL.Priority31
									WHEN @cwtStandardId = 4
									THEN PTL.Priority62
									END
							,PTL.NextActionDesc
							,PTL.NextActionSpecificDesc
							,PTL.NextActionTargetDate
							,PTL.DaysToNextAction
							,PTL.OwnerDesc
							,PTL.Escalated
							,PTL.NextActionColourValue
							,PTL.EstimatedBreachMonth
							,PTL.EstimatedWeight
							,PTL.EBMonthValue
				FROM		SCR_Reporting.PTL_Daily PTL WITH (NOLOCK)
				
				LEFT JOIN	SCR_Warehouse.Workflow wf WITH (NOLOCK)
								ON	PTL.CWT_ID = wf.IdentityTypeRecordId
								AND	wf.WorkflowID = @Workflow
								AND	wf.IdentityTypeId = 2
			
				LEFT JOIN	#cwtStatus cwtStatus
								ON	PTL.DominantCWTStatusCode = cwtStatus.cwtStatusId
				LEFT JOIN	#CancerSiteBS cs
								ON	PTL.CancerSiteBS = cs.CancerSiteBS
				LEFT JOIN	#NextAction na
								ON isnull(PTL.NextActionId,0) = na.NextAction
				LEFT JOIN	#NextActionOwner nao
								ON isnull(PTL.OwnerId,0) = nao.NextActionOwner
				LEFT JOIN	#NextActionSpecific nas
								ON isnull(PTL.NextActionSpecificId,0) = nas.NextActionSpecific
				LEFT JOIN	#Escalation esc
								ON isnull(PTL.Escalated,2) = esc.Escalation										--changes NULL values to a 2 - No escalation
				LEFT JOIN	#EstimatedBreach EB_filter
								ON PTL.EBMonthValue = EB_filter.EstimatedBreach
				LEFT JOIN	#ReportingcwtTypeID RCTI
								ON	PTL.ReportingcwtTypeID = RCTI.ReportingcwtTypeID
				LEFT JOIN	LocalConfig.PathwayLengthFilter plf ON plf.PathwayLengthFilterId = @PathwayLengthFilterId  -- catches hidden SSRS parameter of pathway length
				WHERE		CASE	WHEN @cwtStandardId = 1
									THEN PTL.cwtFlag2WW
									WHEN @cwtStandardId = 2
									THEN PTL.cwtFlag28
									WHEN @cwtStandardId = 3
									THEN PTL.cwtFlag31
									WHEN @cwtStandardId = 4
									THEN PTL.cwtFlag62
									END = 1
				AND			([HospitalNumber]= @HospID															--allows Hospital Number to be entered as a parameter
				OR			(ISNULL(@HospID,'') = ''															--or if the Hospital Number is null
								AND		((cwtStatus.cwtStatusId IS NOT NULL												--and the CWT Status parameter is entered
											OR		ISNULL(@cwtStatus, '') = '')										
											AND		(cs.CancerSiteBS IS NOT NULL										--or the Cancer Site parameter is complete
											OR		ISNULL(@CancerSite, '') = '')
											AND		(na.NextAction IS NOT NULL											--or the Next Action parameter is complete
											OR		ISNULL(@NextAction, '') = '')
											AND		(nao.NextActionOwner IS NOT NULL									--or the Next Action Owner parameter is complete
											OR		ISNULL(@NextActionOwner, '') = '')
											AND		(nas.NextActionSpecific IS NOT NULL									--or the Next Action Specific parameter is complete
											OR		ISNULL(@NextActionSpecific, '') = '')											
											AND		(esc.Escalation IS NOT NULL											--or the Escalation parameter is complete
											OR		ISNULL(@Escalation, '') = '')
											AND		(EB_filter.EstimatedBreach IS NOT NULL
											OR		ISNULL(@EstimatedBreach,'') = '') 
										)
								AND		(	wf.WorkflowID IS NOT NULL
										OR	@Workflow = 0
										)
								AND (PTL.ReportingPathwayLength >= plf.LowerBound OR plf.LowerBound IS NULL)
								AND (PTL.ReportingPathwayLength <= plf.UpperBound OR plf.UpperBound IS NULL)	
								AND (RCTI.ReportingcwtTypeID IS NOT NULL OR ISNULL(@ReportingcwtTypeID, '') = '')
							))

				PRINT CAST(@@ROWCOUNT AS varchar(255)) + ' rows inserted for @DataSource ' + CAST(@DataSource AS varchar(255))
			
		END

		IF @DataSource = 4
		BEGIN
		
				-- Return the PTL data
				INSERT INTO	#PTL	
				SELECT		PTL.CARE_ID
							,PTL.CWT_ID
							,PTL.Pathway
							,PTL.CancerSiteBS
							,PTL.Forename
							,PTL.Surname
							,PTL.HospitalNumber
							,PTL.NHSNumber
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.Waitingtime2WW
									WHEN @cwtStandardId = 2
									THEN PTL.Waitingtime28
									WHEN @cwtStandardId = 3
									THEN PTL.Waitingtime31
									WHEN @cwtStandardId = 4
									THEN PTL.Waitingtime62
									END
							,PTL.OrgCodeFirstSeen
							,PTL.OrgDescFirstSeen
							,PTL.TrackingNotes
							,PTL.DateLastTracked
							,PTL.CommentUser
							,PTL.DaysSinceLastTracked
							,PTL.Weighting
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.CWTStatusDesc2WW
									WHEN @cwtStandardId = 2
									THEN PTL.CWTStatusDesc28
									WHEN @cwtStandardId = 3
									THEN PTL.CWTStatusDesc31
									WHEN @cwtStandardId = 4
									THEN PTL.CWTStatusDesc62
									END
							,PTL.DaysToNextBreach
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.ColourValue2WW
									WHEN @cwtStandardId = 2
									THEN PTL.ColourValue28Day
									WHEN @cwtStandardId = 3
									THEN PTL.ColourValue31Day
									WHEN @cwtStandardId = 4
									THEN PTL.ColourValue62Day
									END
							,CASE	WHEN @cwtStandardId = 1
									THEN PTL.Priority2WW
									WHEN @cwtStandardId = 2
									THEN PTL.Priority28
									WHEN @cwtStandardId = 3
									THEN PTL.Priority31
									WHEN @cwtStandardId = 4
									THEN PTL.Priority62
									END
							,PTL.NextActionDesc
							,PTL.NextActionSpecificDesc
							,PTL.NextActionTargetDate
							,PTL.DaysToNextAction
							,PTL.OwnerDesc
							,PTL.Escalated
							,PTL.NextActionColourValue
							,PTL.EstimatedBreachMonth
							,PTL.EstimatedWeight
							,PTL.EBMonthValue
				FROM		SCR_Reporting.PTL_Weekly PTL WITH (NOLOCK)
				
				LEFT JOIN	SCR_Warehouse.Workflow wf WITH (NOLOCK)
								ON	PTL.CWT_ID = wf.IdentityTypeRecordId
								AND	wf.WorkflowID = @Workflow
								AND	wf.IdentityTypeId = 2
			
				LEFT JOIN	#cwtStatus cwtStatus
								ON	PTL.DominantCWTStatusCode = cwtStatus.cwtStatusId
				LEFT JOIN	#CancerSiteBS cs
								ON	PTL.CancerSiteBS = cs.CancerSiteBS
				LEFT JOIN	#NextAction na
								ON isnull(PTL.NextActionId,0) = na.NextAction
				LEFT JOIN	#NextActionOwner nao
								ON isnull(PTL.OwnerId,0) = nao.NextActionOwner
				LEFT JOIN	#NextActionSpecific nas
								ON isnull(PTL.NextActionSpecificId,0) = nas.NextActionSpecific
				LEFT JOIN	#Escalation esc
								ON isnull(PTL.Escalated,2) = esc.Escalation										--changes NULL values to a 2 - No escalation
				LEFT JOIN	#EstimatedBreach EB_filter
								ON PTL.EBMonthValue = EB_filter.EstimatedBreach
				LEFT JOIN	#ReportingcwtTypeID RCTI
								ON	PTL.ReportingcwtTypeID = RCTI.ReportingcwtTypeID
				LEFT JOIN	LocalConfig.PathwayLengthFilter plf ON plf.PathwayLengthFilterId = @PathwayLengthFilterId  -- catches hidden SSRS parameter of pathway length
				WHERE		CASE	WHEN @cwtStandardId = 1
									THEN PTL.cwtFlag2WW
									WHEN @cwtStandardId = 2
									THEN PTL.cwtFlag28
									WHEN @cwtStandardId = 3
									THEN PTL.cwtFlag31
									WHEN @cwtStandardId = 4
									THEN PTL.cwtFlag62
									END = 1
				AND			([HospitalNumber]= @HospID															--allows Hospital Number to be entered as a parameter
				OR			(ISNULL(@HospID,'') = ''															--or if the Hospital Number is null
								AND		((cwtStatus.cwtStatusId IS NOT NULL												--and the CWT Status parameter is entered
											OR		ISNULL(@cwtStatus, '') = '')										
											AND		(cs.CancerSiteBS IS NOT NULL										--or the Cancer Site parameter is complete
											OR		ISNULL(@CancerSite, '') = '')
											AND		(na.NextAction IS NOT NULL											--or the Next Action parameter is complete
											OR		ISNULL(@NextAction, '') = '')
											AND		(nao.NextActionOwner IS NOT NULL									--or the Next Action Owner parameter is complete
											OR		ISNULL(@NextActionOwner, '') = '')
											AND		(nas.NextActionSpecific IS NOT NULL									--or the Next Action Specific parameter is complete
											OR		ISNULL(@NextActionSpecific, '') = '')											
											AND		(esc.Escalation IS NOT NULL											--or the Escalation parameter is complete
											OR		ISNULL(@Escalation, '') = '')
											AND		(EB_filter.EstimatedBreach IS NOT NULL
											OR		ISNULL(@EstimatedBreach,'') = '') 
										)
								AND		(	wf.WorkflowID IS NOT NULL
										OR	@Workflow = 0
										)
								AND (PTL.ReportingPathwayLength >= plf.LowerBound OR plf.LowerBound IS NULL)
								AND (PTL.ReportingPathwayLength <= plf.UpperBound OR plf.UpperBound IS NULL)	
								AND (RCTI.ReportingcwtTypeID IS NOT NULL OR ISNULL(@ReportingcwtTypeID, '') = '')
							))

				PRINT CAST(@@ROWCOUNT AS varchar(255)) + ' rows inserted for @DataSource ' + CAST(@DataSource AS varchar(255))
			
		END

		PRINT 'SELECT INTO took ' + CAST(DATEDIFF(millisecond, @SnapshotTime, GETDATE()) AS varchar(255)) + 'ms'
		SET @SnapshotTime = GETDATE()

		-- Prepare the Breach Dates output dataset
		SELECT		OTD.CWT_ID
					,ISNULL(
					STUFF((SELECT		CHAR(191) + TargetType + ': ' + CONVERT(varchar(255), OpenTargetXml.TargetDate, 103)
							FROM		SCR_Warehouse.OpenTargetDates OpenTargetXml
							WHERE		OpenTargetXml.CWT_ID = OTD.CWT_ID
							ORDER BY	CWT_ID ASC
										,OpenTargetXml.TargetDate
							FOR XML PATH('')
							), 1, 1, '')
							,'No Active CWT Waits') AS OpenTargetDates
					/*,ISNULL(
					STUFF((SELECT		CHAR(191) + TargetType + ': ' + CONVERT(varchar(255), OpenBreachXml.BreachDate, 103)
							FROM		SCR_Warehouse.OpenTargetDates OpenBreachXml
							WHERE		OpenBreachXml.CWT_ID = OTD.CWT_ID
							ORDER BY	CWT_ID ASC
										,OpenTargetXml.TargetDate
							FOR XML PATH('')
							), 1, 1, '')
							,'No Active CWT Waits') AS OpenBreachDates*/ -- Not Currently Used
		INTO		#OTD
		FROM		SCR_Warehouse.OpenTargetDates OTD
		INNER JOIN	#PTL PTL
						ON	OTD.CWT_ID = PTL.CWT_ID
		GROUP BY	OTD.CWT_ID

		PRINT 'Breach Dates processing took ' + CAST(DATEDIFF(millisecond, @SnapshotTime, GETDATE()) AS varchar(255)) + 'ms'
		SET @SnapshotTime = GETDATE()
				
		-- Return the results
		SELECT		PTL.CARE_ID
					,PTL.CWT_ID
					,PTL.Pathway
					,PTL.CancerSiteBS
					,CASE	WHEN	@Anonymised = 0
							THEN	PTL.Forename
							ELSE	CHAR(ASCII(LEFT(PTL.Forename, 1))+1) + 
									REPLICATE('*',LEN(PTL.Forename)-2) + 
									CHAR(ASCII(RIGHT(PTL.Forename, 1))-1)
							END AS Forename
					,CASE	WHEN	@Anonymised = 0
							THEN	PTL.Surname
							ELSE	CHAR(ASCII(LEFT(PTL.Surname, 1))+1) + 
									REPLICATE('*',LEN(PTL.Surname)-2) + 
									CHAR(ASCII(RIGHT(PTL.Surname, 1))-1)
							END AS Surname
					,CASE	WHEN	@Anonymised = 0
							THEN	PTL.HospitalNumber
							ELSE	CHAR(ASCII(LEFT(PTL.HospitalNumber, 1))+1) + 
									REPLICATE('*',LEN(PTL.HospitalNumber)-2) + 
									CHAR(ASCII(RIGHT(PTL.HospitalNumber, 1)))
							END AS HospitalNumber
					,CASE	WHEN	@Anonymised = 0
							THEN	PTL.NHSNumber
							ELSE	CHAR(ASCII(LEFT(PTL.NHSNumber, 1))+1) + 
									REPLICATE('*',LEN(PTL.NHSNumber)-2) + 
									CHAR(ASCII(RIGHT(PTL.NHSNumber, 1)))
							END AS NHSNumber
					,PTL.ReportingPathwayLength
					,PTL.OrgCodeFirstSeen
					,PTL.OrgDescFirstSeen
					,CASE	WHEN	@Anonymised = 0
							THEN	PTL.TrackingNotes
							ELSE	'Redacted for demo purposes'
							END AS TrackingNotes
					,PTL.DateLastTracked
					,CASE	WHEN	@Anonymised = 0
							THEN	PTL.CommentUser
							ELSE	CHAR(ASCII(LEFT(PTL.CommentUser, 1))+1) + 
									REPLICATE('*',LEN(PTL.CommentUser)-2) + 
									CHAR(ASCII(RIGHT(PTL.CommentUser, 1))-1)
							END AS CommentUser
					,PTL.DaysSinceLastTracked
					,PTL.Weighting
					,PTL.DominantCWTStatusDesc
					,PTL.DaysToNextBreach
					,PTL.DominantColourValue
					,PTL.DominantPriority
					,PTL.NextActionDesc
					,PTL.NextActionSpecificDesc
					,PTL.NextActionTargetDate
					,PTL.DaysToNextAction
					,PTL.OwnerDesc
					,PTL.Escalated
					,PTL.NextActionColourValue
					,PTL.EstimatedBreachMonth
					,PTL.EstimatedWeight
					,PTL.EBMonthValue
					,OTD.OpenTargetDates
					--,OTD.OpenBreachDates -- Not Currently Used
		FROM		#PTL PTL
		LEFT JOIN	#OTD OTD
						ON	PTL.CWT_ID = OTD.CWT_ID

		PRINT 'Data retrieval took ' + CAST(DATEDIFF(millisecond, @SnapshotTime, GETDATE()) AS varchar(255)) + 'ms'
		
GO
