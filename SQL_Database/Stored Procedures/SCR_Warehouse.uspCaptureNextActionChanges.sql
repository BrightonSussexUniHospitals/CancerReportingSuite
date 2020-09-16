USE [CancerReporting]
GO
/****** Object:  StoredProcedure [SCR_Warehouse].[uspCaptureNextActionChanges]    Script Date: 03/09/2020 23:43:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [SCR_Warehouse].[uspCaptureNextActionChanges]
		(@IncrementalUpdate bit = 1
		,@CaptureNextActionChanges bit = 1
		)
AS

-- EXEC SCR_Warehouse.uspCaptureNextActionChanges @IncrementalUpdate = 1, @CaptureNextActionChanges = 1 -- Run Me

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

Original Work Created Date:	01/03/2019
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Capture any changes to the next action datasets in an audit history
							Note that this will only capture the changes between the current status
							of the "Next Action" data and the previously captured status. If there
							has been more than one change to a next action since the previously 
							captured status, we will only get the most recent of those changes.
							In order to get as good a quality audit trail as is possible using
							this method, it is recommended that it is updated as frequently as possible.

UPDATED 04/02/2020			Added in NextActionColourValue to clear technical debt originaly calculated in uspSSRS_PTL SP
**************************************************************************************************************************************************/


/************************************************************************************************************************************************************************************************************
-- Create the table of Incremental Care ID's (if we are doing an incremental update)
************************************************************************************************************************************************************************************************************/

		-- DROP #IncrementalNextAction table if it exists
		if object_ID('tempdb.dbo.#IncrementalNextAction') is not null 
		   DROP TABLE #IncrementalNextAction
		 
		-- Create an #IncrementalNextAction table of CARE_IDs to be updated incrementally (so we have an 
		-- empty table that exists where we are not doing an incremental update and so we can 
		-- define CARE_ID as NOT NULL for the Primary Key)
		CREATE TABLE	#IncrementalNextAction
					(
					CARE_ID int NOT NULL
					)
				
		-- Declare the @ReportDate and @RefreshMaxActionDate variables
		DECLARE	@ReportDate datetime
		DECLARE	@RefreshMaxActionDate datetime
		 
		-- Capture the most recent tblAUDIT timestamp, at the start of the update process, to 
		-- control the record retrieval and to be recorded in the ReportDate Field
		SELECT		@ReportDate = GETDATE()
					,@RefreshMaxActionDate = MAX(ACTION_DATE)
		FROM		LocalConfig.tblAUDIT
		
		-- Insert the Incremental Care ID's (if we are doing an incremental update)
		IF @IncrementalUpdate = 1
		BEGIN
			
				-- Declare the @ReferralRefreshMaxActionDate variable
				DECLARE		@ReferralRefreshMaxActionDate datetime

				-- Assign the last RefreshMaxActionDate from SCR_Referrals to @ReferralRefreshMaxActionDate
				SELECT		@ReferralRefreshMaxActionDate = MAX(RefreshMaxActionDate)
				FROM		SCR_Warehouse.SCR_Referrals
			
				-- Insert CARE_IDs into the #IncrementalNextAction table from tblAUDIT where the ACTION_DATE is
				-- after the last RefreshMaxActionDate from the SCR_Referrals dataset
				INSERT INTO	#IncrementalNextAction
							(
							CARE_ID
							)
				SELECT		CARE_ID					=	a.CARE_ID
				FROM		LocalConfig.tblAUDIT a
				WHERE		a.CARE_ID IS NOT NULL
				AND			(a.ACTION_DATE >= @ReferralRefreshMaxActionDate	-- on or after the last action date used to process SCR_Referrals (note that the ACTION_DATE is only accurate to the minute, so we must take records with an equal value)
				OR			@ReferralRefreshMaxActionDate IS NULL			-- return all records if SCR_Referrals has no last action dates
							)
				GROUP BY	a.CARE_ID
				
				-- Insert CARE_IDs into the #IncrementalNextAction table from tblAUDIT_DELETIONS where the ACTION_DATE is
				-- after the last RefreshMaxActionDate from the SCR_Referrals dataset
				INSERT INTO	#IncrementalNextAction
							(
							CARE_ID
							)
				SELECT		CARE_ID					=	mainref.CARE_ID
				FROM		LocalConfig.tblAUDIT_DELETIONS ad
				INNER JOIN	LocalConfig.tblDEMOGRAPHICS dem
								ON	ad.HOSPITAL_NUMBER = dem.N1_2_HOSPITAL_NUMBER
								OR	ad.NHS_NUMBER = dem.NHS_NUMBER_STATUS
				INNER JOIN	LocalConfig.tblMAIN_REFERRALS mainref
								ON	dem.PATIENT_ID = mainref.PATIENT_ID
				LEFT JOIN	#IncrementalNextAction Inc
								ON	mainref.CARE_ID = Inc.CARE_ID
				WHERE		mainref.CARE_ID IS NOT NULL
				AND			Inc.CARE_ID IS NULL									-- not already in the #IncrementalNextAction table
				AND			(ad.DATE_DELETED >= @ReferralRefreshMaxActionDate	-- on or after the last action date used to process SCR_Referrals (note that the ACTION_DATE is only accurate to the minute, so we must take records with an equal value)
				OR			@ReferralRefreshMaxActionDate IS NULL			-- return all records if SCR_Referrals has no last action dates
							)
				GROUP BY	mainref.CARE_ID
				
				-- Create a Primary Key for the #IncrementalNextAction table
				ALTER TABLE #IncrementalNextAction 
				ADD CONSTRAINT PK_IncrementalNextActionCareId PRIMARY KEY (
						CARE_ID ASC 
						)
				
		END

/************************************************************************************************************************************************************************************************************
-- Create the "Next Actions" dataset
************************************************************************************************************************************************************************************************************/

		-- DROP table of "Next Actions" if it exists
		if object_ID('SCR_Warehouse.SCR_NextActions_work') is not null 
		   DROP TABLE SCR_Warehouse.SCR_NextActions_work
		 
		-- Creates the table of "Next Actions"
		CREATE TABLE SCR_Warehouse.SCR_NextActions_work (
					PathwayUpdateEventID int NOT NULL
					,CareID int NULL
					,NextActionID int NULL
					,NextActionDesc varchar (75) NULL
					,NextActionSpecificID int NULL
					,NextActionSpecificDesc varchar (50) NULL
					,AdditionalDetails varchar(55) NULL
					,OwnerID int NULL
					,OwnerDesc varchar (50) NULL
					,OwnerRole varchar(55) NULL
					,OwnerName varchar(55) NULL
					,TargetDate date NULL
					,Escalate int NULL
					,OrganisationID int NULL
					,OrganisationDesc varchar(250) NULL
					,ActionComplete bit NULL
					,Inserted datetime NULL
					,InsertedBy varchar(255) NULL
					,ACTION_ID int NULL
					,LastUpdated datetime NULL
					,LastUpdatedBy varchar(255) NULL
					,CareIdIx int NULL
					,CareIdRevIx int NULL
					,CareIdIncompleteIx int NULL
					,CareIdIncompleteRevIx int NULL
					-- Provenance
					,ReportDate datetime NULL								-- The runtime date when the last reporting data update was performed
					-- TECHNICAL DEBT --PTL
					,NextActionColourValue varchar (50) NULL				--returns colour value with Next Action Specific priority over no specific action
					)

		-- Create a clustered index on the SCR_NextActions_work table to optimise searching of records not already in the history table
		CREATE CLUSTERED INDEX CIX_NextAction_work ON SCR_Warehouse.SCR_NextActions_work (
				PathwayUpdateEventID DESC,
				ACTION_ID DESC
				)
		
		-- Create an Index for CARE_ID in SCR_NextActions_work
		CREATE NONCLUSTERED INDEX Ix_CARE_ID_Work ON SCR_Warehouse.SCR_NextActions_work (
				CareID ASC
				)


		-- Insert "Next Actions"
		INSERT INTO	SCR_Warehouse.SCR_NextActions_work (
					PathwayUpdateEventID
					,CareID
					,NextActionID
					,NextActionSpecificID
					,AdditionalDetails
					,OwnerID
					,OwnerRole
					,OwnerName
					,TargetDate
					,Escalate
					,OrganisationID
					,ActionComplete
					,ACTION_ID
					,ReportDate
					,NextActionColourValue
					)
		SELECT		
					PathwayUpdateEventID		=	pue.PathwayUpdateEventID
					,CareID						=	pue.CareID		
					,NextActionID				=	pue.NextActionID			
					,NextActionSpecificID		=	pue.NextActionSpecificID
					,AdditionalDetails			=	pue.AdditionalDetails
					,OwnerID					=	pue.OwnerID			 
					,OwnerRole					=	pue.OwnerRole 
					,OwnerName					=	pue.OwnerName 
					,TargetDate					=	pue.TargetDate
					,Escalate					=	pue.Escalate 
					,OrganisationID				=	pue.OrganisationID
					,ActionComplete				=	pue.ActionComplete
					,ACTION_ID					=	pue.ACTION_ID 
					,ReportDate					=	@ReportDate
					,NextActionColourValue		=	LocalConfig.fnNextActionColours (pue.OwnerID,pue.NextActionID,pue.NextActionSpecificID)

		FROM		LocalConfig.tblPathwayUpdateEvents pue
		LEFT JOIN	#IncrementalNextAction Inc
						ON	pue.CareID = Inc.CARE_ID
		WHERE		Inc.CARE_ID IS NOT NULL			-- The record is in the incremental dataset
		OR			pue.CareID IS NULL				-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0			-- We are doing a bulk load (in which case we should ignore the incremental dataset)


		-- Update the metadata lookups
		UPDATE naw
		SET			NextActionDesc				=	NA.Description
					,NextActionSpecificDesc		=	NAS.Description
					,OwnerDesc					=	OWN.Description
					,OrganisationDesc			=	orgsite.Description
					,Inserted					=	aud_i.ACTION_DATE
					,InsertedBy					=	aud_iup.FULL_NAME + ' {.' + aud_iu.LoweredUserName + '.}'
					,LastUpdated				=	aud.ACTION_DATE
					,LastUpdatedBy				=	audup.FULL_NAME + ' {.' + audu.LoweredUserName + '.}'
				

		FROM		SCR_Warehouse.SCR_NextActions_work [naw]
		LEFT JOIN	LocalConfig.ltblNextAction [NA]				ON	naw.NextActionID = NA.ID
		LEFT JOIN	LocalConfig.ltblNextActionSpecific [NAS]	ON	naw.NextActionSpecificID	= NAS.ID
		LEFT JOIN	LocalConfig.ltblOwner [OWN]					ON	naw.OwnerID = OWN.ID
		LEFT JOIN	LocalConfig.OrganisationSites [orgsite]		ON	naw.OrganisationID = orgsite.ID
		LEFT JOIN	LocalConfig.tblAUDIT [aud_i]				ON	naw.PathwayUpdateEventID = aud_i.RECORD_ID
																AND	naw.CareID = aud_i.CARE_ID
																AND	aud_i.TABLE_NAME = 'tblPathwayUpdateEvents'
																AND	aud_i.ACTION_TYPE = 'Insert'
		LEFT JOIN	LocalConfig.aspnet_Users [aud_iu]			ON	LOWER(aud_i.USER_ID) = aud_iu.LoweredUserName
		LEFT JOIN	LocalConfig.tblUSER_PROFILE [aud_iup]		ON	aud_iu.UserId = aud_iup.USER_ID
		LEFT JOIN	LocalConfig.tblAUDIT [aud]					ON	naw.ACTION_ID = aud.ACTION_ID
		LEFT JOIN	LocalConfig.aspnet_Users [audu]				ON	LOWER(aud.USER_ID) = audu.LoweredUserName
		LEFT JOIN	LocalConfig.tblUSER_PROFILE [audup]			ON	audu.UserId = audup.USER_ID


/************************************************************************************************************************************************************************************************************
-- Keep a snapshot of the incremental "Next Actions" dataset (if the @CaptureNextActionChanges parameter implicates this)
************************************************************************************************************************************************************************************************************/

		
		-- Create SCR_NextActions_History table if it doesn't exist
		if object_ID('SCR_Reporting_History.SCR_NextActions_History') is null AND @CaptureNextActionChanges = 1
		BEGIN 		
		
				-- Creates the history table of "Next Actions"
				CREATE TABLE SCR_Reporting_History.SCR_NextActions_History (
							PathwayUpdateEventID int NOT NULL
							,CareID int NULL
							,NextActionID int NULL
							,NextActionDesc varchar (75) NULL
							,NextActionSpecificID int NULL
							,NextActionSpecificDesc varchar (50) NULL
							,AdditionalDetails varchar(55) NULL
							,OwnerID int NULL
							,OwnerDesc varchar (50) NULL
							,OwnerRole varchar(55) NULL
							,OwnerName varchar(55) NULL
							,TargetDate date NULL
							,Escalate int NULL
							,OrganisationID int NULL
							,OrganisationDesc varchar(250) NULL
							,ActionComplete bit NULL
							,Inserted datetime NULL
							,InsertedBy varchar(255) NULL
							,ACTION_ID int NOT NULL
							,LastUpdated datetime NULL
							,LastUpdatedBy varchar(255) NULL
							,ReportDate datetime NULL								-- The runtime date when the last reporting data update was performed
							,NextActionColourValue varchar (50) NULL				-- TECHNICAL DEBT addition
							,UpdateIx int NULL
							,UpdateRevIx int NULL
							)

				-- Create a Primary Key on the SCR_NextActions_History table to optimise searching of records not already in the history table
				ALTER TABLE SCR_Reporting_History.SCR_NextActions_History 
				ADD CONSTRAINT PK_NextAction_History PRIMARY KEY (
						PathwayUpdateEventID DESC,
						ACTION_ID DESC
						)
		
				-- Create an Index for CARE_ID in SCR_NextActions_History
				CREATE NONCLUSTERED INDEX Ix_CARE_ID ON SCR_Reporting_History.SCR_NextActions_History (
						CareID ASC
						)
		
				-- Create an Index for CARE_ID in SCR_NextActions_History
				CREATE NONCLUSTERED INDEX Ix_LastUpdated ON SCR_Reporting_History.SCR_NextActions_History (
						LastUpdated ASC
						,UpdateIx ASC
						,UpdateRevIx DESC
						)

		END

		-- Insert changes to the "Next Actions" dataset (if the @CaptureNextActionChanges parameter implicates this)
		if @CaptureNextActionChanges = 1
		BEGIN 

				-- Insert changes to the "Next Actions" dataset
				INSERT INTO	SCR_Reporting_History.SCR_NextActions_History
							(PathwayUpdateEventID
							,CareID
							,NextActionID
							,NextActionDesc
							,NextActionSpecificID
							,NextActionSpecificDesc
							,AdditionalDetails
							,OwnerID
							,OwnerDesc
							,OwnerRole
							,OwnerName
							,TargetDate
							,Escalate
							,OrganisationID
							,OrganisationDesc
							,ActionComplete
							,Inserted
							,InsertedBy
							,ACTION_ID
							,LastUpdated
							,LastUpdatedBy
							,NextActionColourValue
							,ReportDate)
				SELECT		na.PathwayUpdateEventID
							,na.CareID
							,na.NextActionID
							,na.NextActionDesc
							,na.NextActionSpecificID
							,na.NextActionSpecificDesc
							,na.AdditionalDetails
							,na.OwnerID
							,na.OwnerDesc
							,na.OwnerRole
							,na.OwnerName
							,na.TargetDate
							,na.Escalate
							,na.OrganisationID
							,na.OrganisationDesc
							,na.ActionComplete
							,na.Inserted
							,na.InsertedBy
							,na.ACTION_ID
							,na.LastUpdated
							,na.LastUpdatedBy
							,na.NextActionColourValue
							,na.ReportDate
							
				FROM		SCR_Warehouse.SCR_NextActions_work na
				LEFT JOIN	SCR_Reporting_History.SCR_NextActions_History nah
								ON	na.PathwayUpdateEventID = nah.PathwayUpdateEventID
								AND	na.ACTION_ID = nah.ACTION_ID
				WHERE		nah.PathwayUpdateEventID IS NULL
				AND			na.PathwayUpdateEventID IS NOT NULL
				AND			na.ACTION_ID IS NOT NULL

				-- Update the UpdateIx and UpdateRevIx fields
				UPDATE		nah
				SET			UpdateIx		=	Ix.UpdateIx
							,UpdateRevIx	=	Ix.UpdateRevIx
				FROM		SCR_Reporting_History.SCR_NextActions_History nah
				INNER JOIN	(SELECT		PathwayUpdateEventID
										,ACTION_ID
										,ROW_NUMBER() OVER (PARTITION BY PathwayUpdateEventID ORDER BY LastUpdated ASC) AS UpdateIx
										,ROW_NUMBER() OVER (PARTITION BY PathwayUpdateEventID ORDER BY LastUpdated DESC) AS UpdateRevIx
							FROM		SCR_Reporting_History.SCR_NextActions_History) Ix
								ON	nah.PathwayUpdateEventID = Ix.PathwayUpdateEventID
								AND	nah.ACTION_ID = Ix.ACTION_ID


		END
		

/************************************************************************************************************************************************************************************************************
-- Create the "Final" warehouse datasets by inserting the records not updated by the incremental process (if doing an incremental update)
************************************************************************************************************************************************************************************************************/

		IF @IncrementalUpdate = 1
		BEGIN
				-- Insert "Next action" records not updated by the incremental process
				INSERT INTO SCR_Warehouse.SCR_NextActions_work
							(PathwayUpdateEventID
							,CareID
							,NextActionID
							,NextActionDesc
							,NextActionSpecificID
							,NextActionSpecificDesc
							,AdditionalDetails
							,OwnerID
							,OwnerDesc
							,OwnerRole
							,OwnerName
							,TargetDate
							,Escalate
							,OrganisationID
							,OrganisationDesc
							,ActionComplete
							,Inserted
							,InsertedBy
							,ACTION_ID
							,LastUpdated
							,LastUpdatedBy
							,CareIdIx
							,CareIdRevIx
							,CareIdIncompleteIx
							,CareIdIncompleteRevIx
							,ReportDate
							,NextActionColourValue)
				SELECT		na.PathwayUpdateEventID
							,na.CareID
							,na.NextActionID
							,na.NextActionDesc
							,na.NextActionSpecificID
							,na.NextActionSpecificDesc
							,na.AdditionalDetails
							,na.OwnerID
							,na.OwnerDesc
							,na.OwnerRole
							,na.OwnerName
							,na.TargetDate
							,na.Escalate
							,na.OrganisationID
							,na.OrganisationDesc
							,na.ActionComplete
							,na.Inserted
							,na.InsertedBy
							,na.ACTION_ID
							,na.LastUpdated
							,na.LastUpdatedBy
							,na.CareIdIx
							,na.CareIdRevIx
							,na.CareIdIncompleteIx
							,na.CareIdIncompleteRevIx
							,na.ReportDate
							,na.NextActionColourValue
				FROM		SCR_Warehouse.SCR_NextActions na
				LEFT JOIN	SCR_Warehouse.SCR_NextActions_work naw
								ON	na.PathwayUpdateEventID = naw.PathwayUpdateEventID
				LEFT JOIN	#IncrementalNextAction Inc
								ON	na.CareID = Inc.CARE_ID
				WHERE		naw.PathwayUpdateEventID IS NULL		-- The event hasn't already been processed in the nextactions_work table (not technically necessary as the exclusion of CARE_IDs that are in the #Incremental table will ensure no processed records are brought into the "Final" table, but this gives good assurance in case of future changes to this script)
				AND			(Inc.CARE_ID IS NULL					-- The CARE_ID hasn't been a part of the incremental update (to catch deletions that will no longer be in the nextactions_work table)
				OR			@IncrementalUpdate = 0)					-- not technically needed as this is inside the IF @IncrementalUpdate = 1, but just in case the query gets moved

		END
				
					
		-- Update Index Ordering for Care ID and Care ID for incomplete actions
		UPDATE		naw
		SET			CareIdIx				=	Ix.CareIdIx
					,CareIdRevIx 			=	Ix.CareIdRevIx 	
					,CareIdIncompleteIx		=	Ix.CareIdIncompleteIx
					,CareIdIncompleteRevIx	=	Ix.CareIdIncompleteRevIx
				
		FROM	    SCR_Warehouse.SCR_NextActions_work naw
		INNER JOIN
					(SELECT		PathwayUpdateEventID	
								,CareID
								,CareIdIx				=	ROW_NUMBER() OVER (PARTITION BY CareID ORDER BY TargetDate ASC, PathwayUpdateEventID ASC )
								,CareIdRevIx 			=	ROW_NUMBER() OVER (PARTITION BY CareID ORDER BY TargetDate DESC, PathwayUpdateEventID DESC )
								,CareIdIncompleteIx		=	(1 - ActionComplete) * ROW_NUMBER() OVER (PARTITION BY CareID, ActionComplete ORDER BY TargetDate ASC, PathwayUpdateEventID ASC )
								,CareIdIncompleteRevIx	=	(1 - ActionComplete) * ROW_NUMBER() OVER (PARTITION BY CareID, ActionComplete ORDER BY TargetDate DESC, PathwayUpdateEventID DESC )

					FROM		SCR_Warehouse.SCR_NextActions_work) Ix
						ON naw.PathwayUpdateEventID		=	IX.PathwayUpdateEventID
						AND naw.CareID					=	IX.CareID


/************************************************************************************************************************************************************************************************************
-- Switch out the working tables with the live warehouse tables
************************************************************************************************************************************************************************************************************/

		------------------------ SCR_NextActions ------------------------
		---------------------------------------------------------------
		-- DROP SCR_NextActions table if it exists
		if object_ID('SCR_Warehouse.SCR_NextActions') is not null 
		   DROP TABLE SCR_Warehouse.SCR_NextActions

		-- Rename the SCR_NextActions_Work table as SCR_NextActions
		EXEC sp_rename 'SCR_Warehouse.SCR_NextActions_Work', 'SCR_NextActions'

		-- Rename the CIX_NextAction_work index on SCR_NextActions
		EXEC sp_rename 'SCR_Warehouse.SCR_NextActions.CIX_NextAction_work', 'CIX_NextAction'

		-- Rename the Ix_CARE_ID index on SCR_NextActions
		EXEC sp_rename 'SCR_Warehouse.SCR_NextActions.Ix_CARE_ID_Work', 'Ix_CARE_ID'


GO
