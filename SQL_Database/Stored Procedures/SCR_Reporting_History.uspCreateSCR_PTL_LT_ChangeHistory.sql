USE [CancerReporting]
GO
/****** Object:  StoredProcedure [SCR_Reporting_History].[uspCreateSCR_PTL_LT_ChangeHistory]    Script Date: 03/09/2020 23:43:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 CREATE PROCEDURE [SCR_Reporting_History].[uspCreateSCR_PTL_LT_ChangeHistory] 
 AS

/******************************************************** © Copyright & Licensing ****************************************************************
© 2020 Perspicacity Ltd & Brighton & Sussex University Hospitals NHS Trust

Original Work Created Date:	17/06/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Create and update the archive datasets for all SCR / Somerset reporting
**************************************************************************************************************************************************/

-- Test me
-- EXEC SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory

/************************************************************************************************************************************************************************************************************
-- Create the SCR_Reporting_History tables (if they don't already exist)
************************************************************************************************************************************************************************************************************/

		-- Create SCR_PTL_LT_ChangeHistory (if it doesn't exist)
		IF OBJECT_ID('SCR_Reporting_History.SCR_PTL_LT_ChangeHistory') IS NULL
		BEGIN 
			
			-- Create SCR_PTL_LT_ChangeHistory table
			CREATE TABLE SCR_Reporting_History.SCR_PTL_LT_ChangeHistory(
						/*ChangeHistoryId int IDENTITY(1,1) NOT NULL
						,*/PtlSnapshotId_Start int NOT NULL
						,CWT_ID varchar(255) NOT NULL
						,FieldNameId int NOT NULL
						,FieldValueInt real
						,FieldValueString varchar(max)
						,FieldValueDatetime datetime2
						)

			---- Add a primary key to the SCR_PTL_LT_ChangeHistory table
			--ALTER TABLE SCR_Reporting_History.SCR_PTL_LT_ChangeHistory ADD CONSTRAINT PK_SCR_PTL_LT_ChangeHistory PRIMARY KEY CLUSTERED 
			--		(ChangeHistoryId)

			---- Create a unique index for the SCR_PTL_LT_ChangeHistory table
			--CREATE UNIQUE INDEX UK_SCR_PTL_LT_ChangeHistory ON SCR_Reporting_History.SCR_PTL_LT_ChangeHistory 
			--		(CWT_ID ASC
			--		,PtlSnapshotId_Start DESC
			--		,FieldNameId ASC)

			-- Create a unique index for the SCR_PTL_LT_ChangeHistory table
			CREATE UNIQUE INDEX UK_SCR_PTL_LT_ChangeHistory ON SCR_Reporting_History.SCR_PTL_LT_ChangeHistory 
					(FieldNameId DESC
					,PtlSnapshotId_Start DESC
					,CWT_ID ASC)

			---- Add an index key for the SCR_PTL_LT_ChangeHistory
			--CREATE NONCLUSTERED INDEX Ix_SCR_PTL_LT_ChangeHistory_PtlSnapshotId_Start ON SCR_Reporting_History.SCR_PTL_LT_ChangeHistory(
			--		PtlSnapshotId_Start DESC
			--		)
			--		INCLUDE(CWT_ID,FieldNameId)

			---- Add an index key for the SCR_PTL_LT_ChangeHistory
			--CREATE NONCLUSTERED INDEX Ix_SCR_PTL_LT_ChangeHistory_FieldNameId ON SCR_Reporting_History.SCR_PTL_LT_ChangeHistory(
			--		FieldNameId
			--		,PtlSnapshotId_Start
			--		)

			---- Add an index key for the SCR_PTL_LT_ChangeHistory
			--CREATE NONCLUSTERED INDEX Ix_SCR_PTL_LT_ChangeHistory_CensusRecreation ON SCR_Reporting_History.SCR_PTL_LT_ChangeHistory(
			--		PtlSnapshotId_Start
			--		,CWT_ID
			--		)

			END
			
		-- Create SCR_PTL_LT_CwtPresence if it doesn't exist
		IF OBJECT_ID ('SCR_Reporting_History.SCR_PTL_LT_CwtPresence') IS NULL
		BEGIN 

			-- CReate SCR_PTL_LT_CwtPresence table
			CREATE TABLE SCR_Reporting_History.SCR_PTL_LT_CwtPresence(
					PtlSnapshotId int NOT NULL
					,CWT_ID varchar(255) NOT NULL
					)

			-- Add a primary key to the SCR_PTL_LT_CwtPresence table
			ALTER TABLE SCR_Reporting_History.SCR_PTL_LT_CwtPresence ADD CONSTRAINT PK_SCR_PTL_LT_CwtPresence PRIMARY KEY CLUSTERED 
				(PtlSnapshotId ASC
				,CWT_ID ASC)

		END
			
		-- Create SCR_PTL_LT_FieldNameIdPresence if it doesn't exist
		IF OBJECT_ID ('SCR_Reporting_History.SCR_PTL_LT_FieldNameIdPresence') IS NULL
		BEGIN 

			-- CReate SCR_PTL_LT_FieldNameIdPresence table
			CREATE TABLE SCR_Reporting_History.SCR_PTL_LT_FieldNameIdPresence(
					PtlSnapshotId int NOT NULL
					,FieldNameId varchar(255) NOT NULL
					)

			-- Add a primary key to the SCR_PTL_LT_FieldNameIdPresence table
			ALTER TABLE SCR_Reporting_History.SCR_PTL_LT_FieldNameIdPresence ADD CONSTRAINT PK_SCR_PTL_LT_FieldNameIdPresence PRIMARY KEY CLUSTERED 
				(PtlSnapshotId ASC
				,FieldNameId ASC)

		END

		-- Create SCR_PTL_LT_ChangeHistoryFields (if it doesn't exist)
		IF OBJECT_ID('LocalConfig.SCR_PTL_LT_ChangeHistoryFields') IS NULL
		BEGIN

			CREATE TABLE LocalConfig.SCR_PTL_LT_ChangeHistoryFields (
					FieldNameId int NOT NULL IDENTITY(1,1)
					,FieldName varchar(255) NOT NULL
					,FieldType varchar(255) NOT NULL -- Int, String or DateTime
					,Inactive bit NOT NULL DEFAULT 0
					)

			-- Add a unique key for the Field Names
			CREATE UNIQUE NONCLUSTERED INDEX UK_SCR_PTL_LT_ChangeHistoryFields ON LocalConfig.SCR_PTL_LT_ChangeHistoryFields(
					FieldNameId ASC
					)

			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('PatientPathwayID', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DateBirth', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DeathStatus', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DateDeath', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('CancerSite', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('CancerSiteBS', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('CancerSubSiteCode', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('ReferralCancerSiteCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('ReferralCancerSiteBS', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('CancerTypeCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('PriorityTypeCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('SourceReferralCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('ReferralMethodCode', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DecisionToReferDate', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TumourStatusCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('PatientStatusCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('PatientStatusCodeCwt', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('ConsultantCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('InappropriateRef', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TransferReason', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TransferNewRefDate', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TransferTumourSiteCode', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FastDiagInformedDate', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FastDiagExclDate', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FastDiagCancerSiteID', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FastDiagCancerSiteOverrideID', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FastDiagEndReasonID', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FastDiagDelayReasonID', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FastDiagExclReasonID', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FastDiagOrgID', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FastDiagCommMethodID', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FastDiagOtherCommMethod', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FastDiagInformingCareProfID', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FastDiagOtherCareProf', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DateDiagnosis', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DiagnosisCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DiagnosisSubCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('OrgIdDiagnosis', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('SnomedCT_ID', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('Histology', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DateReceipt', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DateConsultantUpgrade', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DateFirstSeen', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('OrgIdUpgrade', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('OrgIdFirstSeen', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FirstAppointmentTypeCode', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FirstAppointmentOffered', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('ReasonNoAppointmentCode', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FirstSeenAdjTime', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FirstSeenAdjReasonCode', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('FirstSeenDelayReasonCode', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DTTAdjTime', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DTTAdjReasonCode', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('IsBCC', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('IsCwtCancerDiagnosis', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('UnderCancerCareFlag', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DeftTreatmentEventCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DeftTreatmentCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DeftTreatmentSettingCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DeftDateDecisionTreat', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DeftDateTreatment', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DeftDTTAdjTime', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DeftDTTAdjReasonCode', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DeftOrgIdDecisionTreat', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DeftOrgIdTreatment', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DeftDefinitiveTreatment', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DeftChemoRT', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TxModTreatmentEventCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TxModTreatmentCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TxModTreatmentSettingCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TxModDateDecisionTreat', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TxModDateTreatment', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TxModOrgIdDecisionTreat', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TxModOrgIdTreatment', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TxModDefinitiveTreatment', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TxModChemoRadio', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TxModChemoRT', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TxModModalitySubCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('TxModRadioSurgery', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('ChemRtLinkTreatmentCode', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('ChemRtLinkDateTreatment', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('cwtFlag2WW', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('cwtFlag28', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('cwtFlag31', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('cwtFlag62', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('cwtType2WW', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('cwtType28', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('cwtType31', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('cwtType62', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('cwtReason2WW', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('cwtReason28', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('cwtReason31', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('cwtReason62', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('HasTxMod', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('HasChemRtLink', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('AdjTime2WW', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('AdjTime28', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('AdjTime31', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('AdjTime62', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('Waitingtime2WW', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('Waitingtime28', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('Waitingtime31', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('Waitingtime62', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('LastCommentUser', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('LastCommentDate', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DateLastTracked', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DaysSinceLastTracked', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DaysToNextBreach', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('NextBreachTarget', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('NextBreachDate', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('NextActionDesc', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('NextActionSpecificDesc', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('NextActionTargetDate', 'Datetime')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('OwnerDesc', 'String')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('Escalated', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('DominantCWTStatusCode', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('CWTStatusCode2WW', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('CWTStatusCode28', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('CWTStatusCode31', 'Int')
			INSERT INTO LocalConfig.SCR_PTL_LT_ChangeHistoryFields (FieldName, FieldType) VALUES ('CWTStatusCode62', 'Int')


		END


/************************************************************************************************************************************************************************************************************
-- Temp tables and variables used by the procedure
************************************************************************************************************************************************************************************************************/

		DECLARE @ExistingHistorySnapshotId int
		DECLARE @PtlSnapshotId int
		DECLARE @PtlSnapshotDate datetime
		DECLARE @SnapshotIx int
		DECLARE @FirstLoaded_PtlSnapshotId int
		DECLARE @FirstLoaded_SnapshotIx int
		DECLARE @NextLoaded_PtlSnapshotId int
		DECLARE @NextLoaded_SnapshotIx int
		DECLARE @NextLoaded_PtlSnapshotDate datetime
		DECLARE @LastLoaded_PtlSnapshotId int
		DECLARE @LastLoaded_SnapshotIx int
		DECLARE @LastLoaded_PtlSnapshotDate datetime
		DECLARE @LastMatchErrorSQL nvarchar(max)
		DECLARE @CurrentMatchErrorSQL nvarchar(max)
		DECLARE @NextMatchErrorSQL nvarchar(max)
		DECLARE @SQL_LoopCounter int = 1
		DECLARE @LastVerifiedOnlyErrorCount int
		DECLARE @LastCheckSnapOnlyErrorCount int
		DECLARE @LastMatchErrorCount int
		DECLARE @CurrentVerifiedOnlyErrorCount int
		DECLARE @CurrentCheckSnapOnlyErrorCount int
		DECLARE @CurrentMatchErrorCount int
		DECLARE @NextVerifiedOnlyErrorCount int
		DECLARE @NextCheckSnapOnlyErrorCount int
		DECLARE @NextMatchErrorCount int
		DECLARE @SnapshotLoopId int = 1
		DECLARE @SQL nvarchar(max)
		DECLARE @IndexSQL nvarchar(max)
		DECLARE @FieldNameId int = 0 -- Start from the reference field (0 / PtlSnapshotId) that tells us whether a CWT_ID (CWT record) was present for that particular snapshot
		DECLARE @FieldName varchar(255)
		DECLARE @FieldType varchar(255)
		DECLARE @StepName varchar(1000)
		
		-- Drop the #SnapshotIx table
		IF OBJECT_ID('tempdb..#SnapshotIx') IS NOT NULL
		DROP TABLE #SnapshotIx

		-- Create a temp table of the snapshot ID's, ordered by snapshot date
		CREATE TABLE #SnapshotIx (
					PtlSnapshotId int NOT NULL
					,PtlSnapshotDate datetime NOT NULL
					,SnapshotIx int NOT NULL
					,LoadedIntoLTChangeHistory bit
					)

		-- Populate the temp table of the snapshot ID's, ordered by snapshot date
		INSERT INTO	#SnapshotIx (
					PtlSnapshotId
					,PtlSnapshotDate
					,SnapshotIx
					,LoadedIntoLTChangeHistory
					)
		SELECT		PtlSnapshotId
					,PtlSnapshotDate
					,ROW_NUMBER() OVER (ORDER BY PtlSnapshotDate) AS SnapshotIx
					,LoadedIntoLTChangeHistory
		FROM		SCR_Reporting_History.SCR_PTL_SnapshotDates

		-- Index the temporary snapshot table for improved performance
		ALTER TABLE #SnapshotIx ADD CONSTRAINT PK_SnapshotIx PRIMARY KEY CLUSTERED (SnapshotIx DESC)
		CREATE NONCLUSTERED INDEX Ix_SnapshotId ON #SnapshotIx (PtlSnapshotId DESC)
		
		-- Drop the #SnapshotLoopTable
		IF OBJECT_ID('tempdb..#SnapshotLoopTable') IS NOT NULL
		DROP TABLE #SnapshotLoopTable

		-- Create a snapshot loop table for looping through multiple unloaded snapshots
		CREATE TABLE #SnapshotLoopTable (SnapshotLoopId int, PtlSnapshotId int, PtlSnapshotDate datetime, SnapshotIx int)
					
		-- Insert the unloaded snapshots to the snapshot loop table
		INSERT INTO #SnapshotLoopTable (SnapshotLoopId, PtlSnapshotId, PtlSnapshotDate, SnapshotIx)
		SELECT		ROW_NUMBER() OVER (ORDER BY Ix.SnapshotIx ASC) AS SnapshotLoopId
					,Ix.PtlSnapshotId
					,Ix.PtlSnapshotDate
					,Ix.SnapshotIx
		FROM		#SnapshotIx Ix
		WHERE		Ix.LoadedIntoLTChangeHistory = 0


/************************************************************************************************************************************************************************************************************
-- Create the table of dynamic SQL that will be used to verify the snapshot loading and unloading processes
************************************************************************************************************************************************************************************************************/

		-- Drop the #MatchErrorSql table
		IF OBJECT_ID('tempdb..#MatchErrorSql') IS NOT NULL
		DROP TABLE #MatchErrorSql

		-- Create the #LastMatchErrorSql temp table that prepares the Change History Field Name list for a dynamic SQL statement
		SELECT		FieldNameIx	=	ROW_NUMBER() OVER (ORDER BY FieldNameId)
					,FieldNameId
					,Inactive
					,WhereClause	=	CASE	WHEN FieldType = 'Datetime' 
												THEN 'CAST(Verified.' + FieldName + ' AS datetime2) != CAST(CheckSnap.' + FieldName + ' AS datetime2)' 
												ELSE 'Verified.' + FieldName + ' != CheckSnap.' + FieldName END + CHAR(10) + 
										' OR (Verified.' + FieldName + ' IS NULL AND CheckSnap.' + FieldName + ' IS NOT NULL)' + CHAR(10) + 
										' OR (Verified.' + FieldName + ' IS NOT NULL AND CheckSnap.' + FieldName + ' IS NULL)' + CHAR(10)
		INTO		#MatchErrorSql
		FROM		LocalConfig.SCR_PTL_LT_ChangeHistoryFields

/************************************************************************************************************************************************************************************************************
-- Unload Change History records that aren't marked as LoadedIntoLTChangeHistory
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the inserts to the SR_PTL_LT_History process started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory', @Step = 'Unload Change History records'

		-- Drop the #CH_SnapshotsToBeUnloaded table
		IF OBJECT_ID('tempdb..#CH_SnapshotsToBeUnloaded') IS NOT NULL
		DROP TABLE #CH_SnapshotsToBeUnloaded

		-- Create a temp table of the snapshot ID's to be unloaded from the SCR_PTL_LT_ChangeHistory table
		SELECT		CH.PtlSnapshotId_Start
					,Ix.SnapshotIx
		INTO		#CH_SnapshotsToBeUnloaded
		FROM		SCR_Reporting_History.SCR_PTL_LT_ChangeHistory CH
		LEFT JOIN	#SnapshotIx Ix
						ON	CH.PtlSnapshotId_Start = Ix.PtlSnapshotId
		WHERE		Ix.LoadedIntoLTChangeHistory = 0		-- the snapshot requires reloading
		OR			Ix.LoadedIntoLTChangeHistory IS NULL	-- the snapshot has been removed from the SCR_PTL_SnapshotDates table
		GROUP BY	CH.PtlSnapshotId_Start
					,Ix.SnapshotIx

		-- Unload all snapshots in the SCR_PTL_LT_ChangeHistory that aren't marked as loaded (i.e. we need to unload a snapshot before reloading it)
		-- We can cause a snapshot to be unloaded by setting the LoadedIntoLTChangeHistory = 0 in SCR_PTL_SnapshotDates
		WHILE (SELECT COUNT(*) FROM #CH_SnapshotsToBeUnloaded) > 0
		BEGIN
			
				-- Retrieve the next snapshot ID to be processed
				SELECT		TOP 1
							@ExistingHistorySnapshotId = PtlSnapshotId_Start
				FROM		#CH_SnapshotsToBeUnloaded
				ORDER BY	SnapshotIx ASC -- unload the snapshots in ascending order, otherwise we will end up with data that existed in subsequent snapshots being lost because there isn't a change record to represent it in those subsequent snapshots
				
				-- Find the next loaded PtlSnapshotId's and SnapshotIx's for the snapshot being unloaded
				SELECT		@LastLoaded_PtlSnapshotId	=	(SELECT		TOP 1
																		LastLoadedInner.PtlSnapshotId
															FROM		#SnapshotIx LastLoadedInner
															WHERE		LastLoadedInner.LoadedIntoLTChangeHistory = 1
															AND			LastLoadedInner.SnapshotIx < Curr.SnapshotIx
															ORDER BY	SnapshotIx DESC)
							,@NextLoaded_PtlSnapshotId	=	(SELECT		TOP 1
																		NextLoadedInner.PtlSnapshotId
															FROM		#SnapshotIx NextLoadedInner
															WHERE		NextLoadedInner.LoadedIntoLTChangeHistory = 1
															AND			NextLoadedInner.SnapshotIx > Curr.SnapshotIx
															ORDER BY	SnapshotIx ASC)
							,@SnapshotIx				=	Curr.SnapshotIx
							,@NextLoaded_SnapshotIx		=	(SELECT		TOP 1
																		NextLoadedInner.SnapshotIx
															FROM		#SnapshotIx NextLoadedInner
															WHERE		NextLoadedInner.LoadedIntoLTChangeHistory = 1
															AND			NextLoadedInner.SnapshotIx > Curr.SnapshotIx
															ORDER BY	SnapshotIx ASC)
				FROM		#SnapshotIx Curr
				WHERE		PtlSnapshotId = @ExistingHistorySnapshotId
					
				-- Find the last loaded snapshot date
				SELECT		@LastLoaded_PtlSnapshotDate = SD.PtlSnapshotDate 
				FROM		SCR_Reporting_History.SCR_PTL_SnapshotDates SD
				WHERE		SD.PtlSnapshotId = @LastLoaded_PtlSnapshotId
					
				-- Find the next loaded snapshot date
				SELECT		@NextLoaded_PtlSnapshotDate = SD.PtlSnapshotDate 
				FROM		SCR_Reporting_History.SCR_PTL_SnapshotDates SD
				WHERE		SD.PtlSnapshotId = @NextLoaded_PtlSnapshotId
				
				-- Drop the #NextSnapshotIx table
				IF OBJECT_ID('tempdb..#NextSnapshotIx') IS NOT NULL
				DROP TABLE #NextSnapshotIx

				-- Find the next change history records after the current @ExistingHistorySnapshotId snapshot
				SELECT		CH.FieldNameId
							,CH.CWT_ID
							,MIN(Ix.SnapshotIx) AS NextSnapshotIx
				INTO		#NextSnapshotIx
				FROM		SCR_Reporting_History.SCR_PTL_LT_ChangeHistory CH
				INNER JOIN	#SnapshotIx Ix
								ON	CH.PtlSnapshotId_Start = Ix.PtlSnapshotId
								AND	Ix.SnapshotIx > @SnapshotIx				-- a change history record later than the snapshot being unloaded
				GROUP BY	CH.FieldNameId
							,CH.CWT_ID

				-----------------------------------------------------------------------------------------------------------------------------------------------
				-- Create the dynamic SQL that will be used to verify the snapshot unloading process
				-----------------------------------------------------------------------------------------------------------------------------------------------

				-- Start the dynamic SQL statement to look for Match errors between the verified last snapshot and the post-processing last snapshot
				SET @LastMatchErrorSQL		=	'SELECT		@LastMatchErrorCount = COUNT(*) ' + CHAR(10) +
												'FROM		SCR_Reporting_History.VerifiedLastLoadedSnapshot Verified' + CHAR(10) +
												'INNER JOIN	SCR_Reporting_History.CheckLastLoadedSnapshot CheckSnap' + CHAR(10) +
												'				ON Verified.CWT_ID = CheckSnap.CWT_ID' + CHAR(10)

				-- Start the dynamic SQL statement to look for Match errors between the verified next snapshot and the post-processing next snapshot
				SET @NextMatchErrorSQL		=	'SELECT		@NextMatchErrorCount = COUNT(*) ' + CHAR(10) +
												'FROM		SCR_Reporting_History.VerifiedNextLoadedSnapshot Verified' + CHAR(10) +
												'INNER JOIN	SCR_Reporting_History.CheckNextLoadedSnapshot CheckSnap' + CHAR(10) +
												'				ON Verified.CWT_ID = CheckSnap.CWT_ID' + CHAR(10)

				-- Loop through each field in the Change History Field Name list and add it to the where clause of the dynamic SQL statement
				SET @SQL_LoopCounter = 1
				
				WHILE @SQL_LoopCounter <= (SELECT MAX(FieldNameIx) FROM #MatchErrorSql)
				BEGIN

					-- Add the fields we will be checking to the where clause for the last match
					SELECT		@LastMatchErrorSQL		=	@LastMatchErrorSQL + 
															CASE WHEN mes.FieldNameIx = 1 THEN 'WHERE ' ELSE 'OR ' END + 
															mes.WhereClause
					FROM		#MatchErrorSql mes
					INNER JOIN	SCR_Reporting_History.SCR_PTL_LT_FieldNameIdPresence Fields
									ON	mes.FieldNameId = Fields.FieldNameId
									AND	Fields.PtlSnapshotId = @LastLoaded_PtlSnapshotId
					WHERE		mes.FieldNameIx = @SQL_LoopCounter

					-- Add the fields we will be checking to the where clause for the next match
					SELECT		@NextMatchErrorSQL		=	@NextMatchErrorSQL + 
															CASE WHEN mes.FieldNameIx = 1 THEN 'WHERE ' ELSE 'OR ' END + 
															mes.WhereClause
					FROM		#MatchErrorSql mes
					INNER JOIN	SCR_Reporting_History.SCR_PTL_LT_FieldNameIdPresence Fields
									ON	mes.FieldNameId = Fields.FieldNameId
									AND	Fields.PtlSnapshotId = @NextLoaded_PtlSnapshotId
					WHERE		mes.FieldNameIx = @SQL_LoopCounter

					-- Increment the SQL loop counter
					SET @SQL_LoopCounter = @SQL_LoopCounter + 1

				END

				-----------------------------------------------------------------------------------------------------------------------------------------------
				-- Take a census of the verified last and next snapshot for comparison later
				-----------------------------------------------------------------------------------------------------------------------------------------------

				-- Drop the census for the last loaded snapshot date (if it exists)
				IF OBJECT_ID('SCR_Reporting_History.VerifiedLastLoadedSnapshot') IS NOT NULL
				DROP TABLE SCR_Reporting_History.VerifiedLastLoadedSnapshot

				-- Drop the census for the next loaded snapshot date (if it exists)
				IF OBJECT_ID('SCR_Reporting_History.VerifiedNextLoadedSnapshot') IS NOT NULL
				DROP TABLE SCR_Reporting_History.VerifiedNextLoadedSnapshot
						
				-- Create a census of the last loaded snapshot (so we can make sure it is the same before and after the unloading
				-- of the current snapshot
				IF @LastLoaded_PtlSnapshotId IS NOT NULL
				BEGIN
					
					PRINT 'Creating verified last loaded snapshot for ' + CAST(@ExistingHistorySnapshotId AS varchar(255)) + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
					
					-- Create a census for the last loaded snapshot date
					EXEC SCR_Reporting_History.uspCreateSCR_PTL_LT_Census @CensusDate = @LastLoaded_PtlSnapshotDate, @OutputTableName = 'SCR_Reporting_History.VerifiedLastLoadedSnapshot'

				END

				-- Create a census of the next loaded snapshot (so we can make sure it is the same before and after the unloading
				-- of the current snapshot
				IF @NextLoaded_PtlSnapshotId IS NOT NULL
				BEGIN
					
					PRINT 'Creating verified next loaded snapshot for ' + CAST(@ExistingHistorySnapshotId AS varchar(255)) + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
					
					-- Create a census for the next loaded snapshot date
					EXEC SCR_Reporting_History.uspCreateSCR_PTL_LT_Census @CensusDate = @NextLoaded_PtlSnapshotDate, @OutputTableName = 'SCR_Reporting_History.VerifiedNextLoadedSnapshot'

				END
				
				-- Start a try-catch in case the transaction fails and needs rolling back
				BEGIN TRY
				
						BEGIN TRANSACTION
						
						-----------------------------------------------------------------------------------------------------------------------------------------------
						-- Unload the snapshot
						-----------------------------------------------------------------------------------------------------------------------------------------------
						
						PRINT 'Unloading snapshot ID ' + CAST(@ExistingHistorySnapshotId AS varchar(255)) + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
						
						-- Shift change history records forwards to the next loaded snapshot ID, if the next change history record is after
						-- the next loaded snapshot
						IF @NextLoaded_PtlSnapshotId IS NOT NULL
						BEGIN

								UPDATE		CH
								SET			CH.PtlSnapshotId_Start = @NextLoaded_PtlSnapshotId
								FROM		SCR_Reporting_History.SCR_PTL_LT_ChangeHistory CH
								INNER JOIN	SCR_Reporting_History.SCR_PTL_LT_FieldNameIdPresence Fields
												ON	CH.FieldNameId = Fields.FieldNameId
												AND	Fields.PtlSnapshotId = @NextLoaded_SnapshotIx
								LEFT JOIN	#NextSnapshotIx Ix
												ON	CH.FieldNameId = Ix.FieldNameId
												AND	CH.CWT_ID = Ix.CWT_ID
								WHERE		CH.PtlSnapshotId_Start = @ExistingHistorySnapshotId
								AND			(Ix.NextSnapshotIx > @NextLoaded_SnapshotIx	-- the next change history record is after the next loaded snapshot
								OR			Ix.CWT_ID IS NULL)

						END
				
						-- delete all remaining change history records in the snapshot being unloaded 
						DELETE FROM	CH
						FROM		SCR_Reporting_History.SCR_PTL_LT_ChangeHistory CH
						WHERE		CH.PtlSnapshotId_Start = @ExistingHistorySnapshotId

						-- delete the record of all the CWT_IDs that were present in the snapshot
						DELETE FROM	Presence
						FROM		SCR_Reporting_History.SCR_PTL_LT_CwtPresence Presence
						WHERE		Presence.PtlSnapshotId = @ExistingHistorySnapshotId

						-- delete the record of all the FieldNameIds that were present in the snapshot
						DELETE FROM	Presence
						FROM		SCR_Reporting_History.SCR_PTL_LT_FieldNameIdPresence Presence
						WHERE		Presence.PtlSnapshotId = @ExistingHistorySnapshotId

						-----------------------------------------------------------------------------------------------------------------------------------------------
						-- Take a census of the post processed last and next snapshot for comparison against the verified census
						-----------------------------------------------------------------------------------------------------------------------------------------------

						-- Drop the census for the last loaded snapshot date (if it exists)
						IF OBJECT_ID('SCR_Reporting_History.CheckLastLoadedSnapshot') IS NOT NULL
						DROP TABLE SCR_Reporting_History.CheckLastLoadedSnapshot

						-- Drop the census for the next loaded snapshot date (if it exists)
						IF OBJECT_ID('SCR_Reporting_History.CheckNextLoadedSnapshot') IS NOT NULL
						DROP TABLE SCR_Reporting_History.CheckNextLoadedSnapshot
						
						-- Create a census of the last loaded snapshot (so we can make sure it is the same before and after the unloading
						-- of the current snapshot
						IF @LastLoaded_PtlSnapshotId IS NOT NULL
						BEGIN
					
							PRINT 'Creating last loaded snapshot to check for ' + CAST(@ExistingHistorySnapshotId AS varchar(255)) + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
					
							-- Create a census for the last loaded snapshot date
							EXEC SCR_Reporting_History.uspCreateSCR_PTL_LT_Census
									@CensusDate = @LastLoaded_PtlSnapshotDate
									,@OutputTableName = 'SCR_Reporting_History.CheckLastLoadedSnapshot'
									,@ReadUncommitted = 1

						END

						-- Create a census of the next loaded snapshot (so we can make sure it is the same before and after the unloading
						-- of the current snapshot
						IF @NextLoaded_PtlSnapshotId IS NOT NULL
						BEGIN
					
							PRINT 'Creating next loaded snapshot to check for ' + CAST(@ExistingHistorySnapshotId AS varchar(255)) + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
					
							-- Create a census for the next loaded snapshot date
							EXEC SCR_Reporting_History.uspCreateSCR_PTL_LT_Census 
									@CensusDate = @NextLoaded_PtlSnapshotDate
									,@OutputTableName = 'SCR_Reporting_History.CheckNextLoadedSnapshot'
									,@ReadUncommitted = 1

						END

						-----------------------------------------------------------------------------------------------------------------------------------------------
						-- verify the remaining last and next snapshots
						-----------------------------------------------------------------------------------------------------------------------------------------------

						IF @LastLoaded_PtlSnapshotId IS NOT NULL
						BEGIN
					
							-- Check for records in the verified last snapshot and not in the post processing last snapshot
							SELECT		@LastVerifiedOnlyErrorCount = COUNT(*)
							FROM		SCR_Reporting_History.VerifiedLastLoadedSnapshot Verified
							LEFT JOIN	SCR_Reporting_History.CheckLastLoadedSnapshot CheckSnap
											ON	Verified.CWT_ID = CheckSnap.CWT_ID
							WHERE		CheckSnap.CWT_ID IS NULL

							-- Check for records in the post processing last snapshot and not in the verified last snapshot
							SELECT		@LastCheckSnapOnlyErrorCount = COUNT(*)
							FROM		SCR_Reporting_History.CheckLastLoadedSnapshot CheckSnap
							LEFT JOIN	SCR_Reporting_History.VerifiedLastLoadedSnapshot Verified
											ON	CheckSnap.CWT_ID = Verified.CWT_ID
							WHERE		Verified.CWT_ID IS NULL

							-- Run the dynamic SQL to look for Match errors between the verified last snapshot and the post-processing last snapshot
							EXEC sp_executesql @LastMatchErrorSQL,
							  N'@LastMatchErrorCount int OUTPUT',
							  @LastMatchErrorCount OUTPUT

						END

						ELSE

						BEGIN
							
							SELECT
							@LastVerifiedOnlyErrorCount = 0
							,@LastCheckSnapOnlyErrorCount = 0
							,@LastMatchErrorCount = 0

						END

						
						IF @NextLoaded_PtlSnapshotId IS NOT NULL
						BEGIN
					
							-- Check for records in the verified next snapshot and not in the post processing next snapshot
							SELECT		@NextVerifiedOnlyErrorCount = COUNT(*)
							FROM		SCR_Reporting_History.VerifiedNextLoadedSnapshot Verified
							LEFT JOIN	SCR_Reporting_History.CheckNextLoadedSnapshot CheckSnap
											ON	Verified.CWT_ID = CheckSnap.CWT_ID
							WHERE		CheckSnap.CWT_ID IS NULL

							-- Check for records in the post processing next snapshot and not in the verified next snapshot
							SELECT		@NextCheckSnapOnlyErrorCount = COUNT(*)
							FROM		SCR_Reporting_History.CheckNextLoadedSnapshot CheckSnap
							LEFT JOIN	SCR_Reporting_History.VerifiedNextLoadedSnapshot Verified
											ON	CheckSnap.CWT_ID = Verified.CWT_ID
							WHERE		Verified.CWT_ID IS NULL

							-- Run the dynamic SQL to look for Match errors between the verified next snapshot and the post-processing next snapshot
							EXEC sp_executesql @NextMatchErrorSQL,
							  N'@NextMatchErrorCount int OUTPUT',
							  @NextMatchErrorCount OUTPUT
						
						END

						ELSE
						BEGIN
						
							SELECT
							@NextVerifiedOnlyErrorCount = 0
							,@NextCheckSnapOnlyErrorCount = 0
							,@NextMatchErrorCount = 0

						END

						-- If there is an error in the previous or next snapshots left after the unloading of the current snapshot then roll back the transaction
						IF	@LastVerifiedOnlyErrorCount != 0
						OR	@LastCheckSnapOnlyErrorCount != 0
						OR	@LastMatchErrorCount != 0
						OR	@NextVerifiedOnlyErrorCount != 0
						OR	@NextCheckSnapOnlyErrorCount != 0
						OR	@NextMatchErrorCount != 0
						BEGIN
								PRINT 'Rolling back because of unverified difference after removing snapshot ID ' + CAST(@ExistingHistorySnapshotId AS varchar(255)) + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
								ROLLBACK TRANSACTION
						END

						ELSE
						BEGIN
								PRINT 'Committal of unloaded snapshot ID ' + CAST(@ExistingHistorySnapshotId AS varchar(255)) + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
								COMMIT TRANSACTION
						END
				-- End try block
				END TRY

				-- In case the transaction failed 
				BEGIN CATCH

					IF @@TRANCOUNT > 0 -- SELECT @@TRANCOUNT
					BEGIN
						PRINT 'Rolling back because of error in unloading snapshot ID ' + CAST(@ExistingHistorySnapshotId AS varchar(255)) + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
						ROLLBACK TRANSACTION
					END
 
					SELECT ERROR_NUMBER() AS ErrorNumber
					SELECT ERROR_MESSAGE() AS ErrorMessage
 
				END CATCH	
		
				-- remove the snapshot from the list of snapshots to be unloaded
				DELETE	
				FROM		#CH_SnapshotsToBeUnloaded
				WHERE		PtlSnapshotId_Start = @ExistingHistorySnapshotId


		END

		--Keep a record of when the inserts to the SR_PTL_LT_History process finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory', @Step = 'Unload Change History records'

		
/************************************************************************************************************************************************************************************************************
-- Load Change History records that aren't marked as LoadedIntoLTChangeHistory
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the inserts to the SR_PTL_LT_History process started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory', @Step = 'Load Change History records'

		-- Loop through each snapshot to process the old archive data
		WHILE @SnapshotLoopId <= (SELECT MAX(SnapshotLoopId) FROM #SnapshotLoopTable)
		BEGIN

			-- Retrieve the PtlSnapshotId
			SELECT		@PtlSnapshotId = PtlSnapshotId
						,@PtlSnapshotDate = PtlSnapshotDate
						,@SnapshotIx = SnapshotIx
			FROM		#SnapshotLoopTable
			WHERE		SnapshotLoopId = @SnapshotLoopId

			-- Keep a record of when the snapshot load ended
			SET @StepName = 'Load Change History snapshot id: ' + CAST(@PtlSnapshotId AS varchar(255))
			EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory', @Step = @StepName

			-- Drop the temporary snapshot table if it exists
			IF OBJECT_ID('tempdb..#SCR_PTL_History') IS NOT NULL
			DROP TABLE #SCR_PTL_History

			-- Load the snapshot to be processed into a temporary table
			SELECT		*
			INTO		#SCR_PTL_History
			FROM		SCR_Reporting_History.SCR_PTL_History
			WHERE		PtlSnapshotId = @PtlSnapshotId

			-- Index the temporary snapshot table for improved performance
			SELECT @IndexSQL =	'ALTER TABLE #SCR_PTL_History ADD CONSTRAINT PK_SCR_PTL_History_SingleSnapshot_' + 
								REPLACE(REPLACE(REPLACE(CONVERT(varchar(255), GETDATE(), 126), '-',''), ':', ''), '.', '') + 
								' PRIMARY KEY CLUSTERED (PtlSnapshotId DESC, CWT_ID DESC)'
			EXEC (@IndexSQL)
			CREATE NONCLUSTERED INDEX Ix_CARE_ID ON #SCR_PTL_History (CARE_ID DESC)
			CREATE NONCLUSTERED INDEX Ix_PtlSnapshotDate ON #SCR_PTL_History (PtlSnapshotDate DESC)


			-- Find the next loaded PtlSnapshotId's for the snapshot being loaded
			SELECT		@NextLoaded_PtlSnapshotId	=	(SELECT		TOP 1
																	NextLoadedInner.PtlSnapshotId
														FROM		#SnapshotIx NextLoadedInner
														INNER JOIN	SCR_Reporting_History.SCR_PTL_SnapshotDates SD
																		ON	NextLoadedInner.PtlSnapshotId = SD.PtlSnapshotId
														WHERE		SD.LoadedIntoLTChangeHistory = 1
														AND			NextLoadedInner.SnapshotIx > Curr.SnapshotIx
														ORDER BY	SnapshotIx ASC)
			FROM		#SnapshotIx Curr
			WHERE		PtlSnapshotId = @PtlSnapshotId

			-- Find the first loaded SnapshotIx
			SELECT		@FirstLoaded_SnapshotIx = MIN(FirstLoaded.SnapshotIx)
			FROM		#SnapshotIx FirstLoaded
			INNER JOIN	SCR_Reporting_History.SCR_PTL_SnapshotDates SD
							ON	FirstLoaded.PtlSnapshotId = SD.PtlSnapshotId
			WHERE		SD.LoadedIntoLTChangeHistory = 1

			-- Find the first loaded PtlSnapshotId
			SELECT		@FirstLoaded_PtlSnapshotId = FirstLoaded.PtlSnapshotId
			FROM		#SnapshotIx FirstLoaded
			WHERE		FirstLoaded.SnapshotIx = @FirstLoaded_SnapshotIx

			-- Find the last loaded SnapshotIx
			SELECT		@LastLoaded_SnapshotIx = MAX(LastLoaded.SnapshotIx)
			FROM		#SnapshotIx LastLoaded
			INNER JOIN	SCR_Reporting_History.SCR_PTL_SnapshotDates SD
							ON	LastLoaded.PtlSnapshotId = SD.PtlSnapshotId
			WHERE		SD.LoadedIntoLTChangeHistory = 1

			
			-- Begin a try block so that we can roll back the transaction if there is an error
			BEGIN TRY
			
				-- Begin a transaction so that we can roll the changes from this snapshot back if there are any errors
				BEGIN TRANSACTION
			
					-- Loop through the fields that we process changes for
					WHILE	@FieldNameId <= (SELECT MAX(FieldNameId) FROM LocalConfig.SCR_PTL_LT_ChangeHistoryFields)
					BEGIN

						-- Drop the #NextCurrPrevIx table
						IF OBJECT_ID('tempdb..#NextCurrPrevIx') IS NOT NULL
						DROP TABLE #NextCurrPrevIx

						-- Create a copy of the change history with the previous, current and next snapshot change records for each CWT_ID and FieldNameId
						SELECT		CwtFieldIx.*
									,ISNULL(SnapshotsAfterCurrent.SnapshotsAfterCurrent, 0) + 1 - CwtFieldIx.CwtFieldIx AS NextCurrPrevIx
						INTO		#NextCurrPrevIx
						FROM		(SELECT		ROW_NUMBER() OVER (PARTITION BY CHi.CWT_ID, CHi.FieldNameId ORDER BY Ix.SnapshotIx DESC) AS CwtFieldIx
												,Ix.SnapshotIx
												,CHi.*
									FROM		SCR_Reporting_History.SCR_PTL_LT_ChangeHistory CHi
									INNER JOIN	#SnapshotIx Ix
													ON	CHi.PtlSnapshotId_Start = Ix.PtlSnapshotId
									WHERE		CHi.FieldNameId = @FieldNameId) CwtFieldIx
						LEFT JOIN	(SELECT		CHi.CWT_ID
												,COUNT(*) AS SnapshotsAfterCurrent
									FROM		SCR_Reporting_History.SCR_PTL_LT_ChangeHistory CHi
									INNER JOIN	#SnapshotIx Ix
													ON	CHi.PtlSnapshotId_Start = Ix.PtlSnapshotId
													AND	Ix.SnapshotIx > @SnapshotIx
									WHERE		CHi.FieldNameId = @FieldNameId
									GROUP BY	CHi.CWT_ID) SnapshotsAfterCurrent
										ON	CwtFieldIx.CWT_ID = SnapshotsAfterCurrent.CWT_ID
						WHERE		ISNULL(SnapshotsAfterCurrent.SnapshotsAfterCurrent, 0) + 1 - CwtFieldIx.CwtFieldIx BETWEEN -1 AND 1
					
						-- Drop the #ChangeHistory table
						IF OBJECT_ID('tempdb..#ChangeHistory') IS NOT NULL
						DROP TABLE #ChangeHistory

						-- (Re)create the #ChangeHistory table
						SELECT		CWT_ID							=	ISNULL(CurrCR.CWT_ID, NextCR.CWT_ID)
									,BeforeFirstChange				=	CASE WHEN CurrCR.CWT_ID IS NULL THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
									,OnExistingChange				=	CASE WHEN CurrCR.SnapshotIx = @SnapshotIx THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
									,BetweenExistingChange			=	CASE WHEN CurrCR.SnapshotIx != @SnapshotIx AND NextCR.CWT_ID IS NOT NULL THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
									,AfterMostRecentChange			=	CASE WHEN CurrCR.SnapshotIx != @SnapshotIx AND NextCR.CWT_ID IS NULL THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
									,AfterLastLoadedSnapshot		=	CASE WHEN @SnapshotIx > @LastLoaded_SnapshotIx THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
									--,BetweenExistingChange			=	CASE WHEN Ix.SnapshotIx != @SnapshotIx AND Ix.SnapshotIx < @LastLoaded_SnapshotIx THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
									--,AfterMostRecentChange			=	CASE WHEN Ix.SnapshotIx > @SnapshotIx THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
									,NextChangeIsNextLoadedSnapshot	=	CASE WHEN NextCR.PtlSnapshotId_Start = @NextLoaded_PtlSnapshotId THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
									,FieldValueInt_Curr				=	CurrCR.FieldValueInt
									,FieldValueString_Curr			=	CurrCR.FieldValueString
									,FieldValueDatetime_Curr		=	CurrCR.FieldValueDatetime
									,FieldValueInt_Prev				=	PrevCR.FieldValueInt
									,FieldValueString_Prev			=	PrevCR.FieldValueString
									,FieldValueDatetime_Prev		=	PrevCR.FieldValueDatetime
									,FieldValueInt_Next				=	NextCR.FieldValueInt
									,FieldValueString_Next			=	NextCR.FieldValueString
									,FieldValueDatetime_Next		=	NextCR.FieldValueDatetime
									,PtlSnapshotId_Start			=	CurrCR.PtlSnapshotId_Start
									,PtlSnapshotId_Start_Prev		=	PrevCR.PtlSnapshotId_Start
									,PtlSnapshotId_Start_Next		=	NextCR.PtlSnapshotId_Start
						INTO		#ChangeHistory
						FROM		(SELECT * FROM #NextCurrPrevIx WHERE NextCurrPrevIx = 0) CurrCR
						FULL JOIN	(SELECT * FROM #NextCurrPrevIx WHERE NextCurrPrevIx = 1) NextCR
										ON	CurrCR.CWT_ID = NextCR.CWT_ID
						LEFT JOIN	#NextCurrPrevIx PrevCR
										ON	CurrCR.CWT_ID = PrevCR.CWT_ID
										AND	PrevCR.NextCurrPrevIx = -1

						PRINT @FieldNameId
						-- Check the field ID exists
						IF (SELECT COUNT(*) FROM LocalConfig.SCR_PTL_LT_ChangeHistoryFields WHERE FieldNameId = @FieldNameId AND Inactive = 0) > 0 -- the current @FieldNameId has an active entry in the lookup table
						BEGIN
					
							PRINT 'SnapshotLoopId: ' + CAST(@SnapshotLoopId AS varchar(255)) + ' FieldNameId: ' + CAST(@FieldNameId AS varchar(255)) + ' at ' + CONVERT(varchar(255), GETDATE(), 126)

							-- Retrieve the field name and field type values into the variables
							SELECT		@FieldName	=	FieldName
										,@FieldType	=	FieldType
							FROM		LocalConfig.SCR_PTL_LT_ChangeHistoryFields
							WHERE		FieldNameId = @FieldNameId
				
							-- Keep a record of when the inserts to the SR_PTL_LT_History process started
							SET @StepName = 'Process Change History snapshot for FieldNameId: ' + CAST(@FieldNameId AS varchar(255)) + ' FieldName: ' + @FieldName + ' FieldType: ' + @FieldType
							EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory', @Step = @StepName

							-- Drop the #NewValues table
							IF OBJECT_ID('tempdb..#NewValues') IS NOT NULL
							DROP TABLE #NewValues

							-- (Re)create the #NewValues table
							CREATE TABLE #NewValues (
										CWT_ID varchar(255) NOT NULL
										,BeforeFirstChange bit
										,OnExistingChange bit
										,BetweenExistingChange bit
										,AfterMostRecentChange bit
										,AfterLastLoadedSnapshot bit
										,NextChangeIsNextLoadedSnapshot bit
										,InitialAppearance int
										,PrevValueIsChangeFromNewValue bit
										,ExistingValueIsChangeFromNewValue bit
										,NextValueIsChangeFromNewValue bit
										,ExistingId_Start int
										,NextId_Start int
										,ExistingValueInt real
										,ExistingValueString varchar(max)
										,ExistingValueDateTime datetime2
										,NewValueInt real
										,NewValueString varchar(max)
										,NewValueDateTime datetime2
										)

							-- Find the records with changes to the PatientStatusDesc from the known values in the change history
							-- or where this is the first appearance of this CWT_ID in the change history
							SET @SQL = '
							INSERT INTO	#NewValues (
										CWT_ID
										,BeforeFirstChange
										,OnExistingChange
										,BetweenExistingChange
										,AfterMostRecentChange
										,AfterLastLoadedSnapshot
										,NextChangeIsNextLoadedSnapshot
										,InitialAppearance
										,PrevValueIsChangeFromNewValue
										,ExistingValueIsChangeFromNewValue
										,NextValueIsChangeFromNewValue
										,ExistingId_Start
										,NextId_Start
										,ExistingValue' + @FieldType + '
										,NewValue' + @FieldType + '
										)
							SELECT		CWT_ID								=	ISNULL(Hist.CWT_ID, CH.CWT_ID)
										,BeforeFirstChange					=	CH.BeforeFirstChange		
										,OnExistingChange					=	CH.OnExistingChange		
										,BetweenExistingChange				=	CH.BetweenExistingChange
										,AfterMostRecentChange				=	CH.AfterMostRecentChange
										,AfterLastLoadedSnapshot			=	CH.AfterLastLoadedSnapshot
										,NextChangeIsNextLoadedSnapshot		=	CH.NextChangeIsNextLoadedSnapshot
										,InitialAppearance					=	CASE	WHEN	CH.CWT_ID IS NULL 
																						AND		Hist.' + @FieldName + ' IS NOT NULL
																						THEN	2
																						WHEN	CH.CWT_ID IS NULL 
																						THEN	1 
																						ELSE	0 
																						END
										,PrevValueIsChangeFromNewValue		=	CASE	WHEN	Hist.' + @FieldName + ' != CH.FieldValue' + @FieldType + '_Prev
																						OR		(Hist.' + @FieldName + ' IS NULL AND CH.FieldValue' + @FieldType + '_Prev IS NOT NULL)
																						OR		(Hist.' + @FieldName + ' IS NOT NULL AND CH.FieldValue' + @FieldType + '_Prev IS NULL AND CH.PtlSnapshotId_Start_Prev IS NOT NULL)
																						THEN	CAST(1 AS bit) 
																						ELSE	CAST(0 AS bit) 
																						END
										,ExistingValueIsChangeFromNewValue	=	CASE	WHEN	Hist.' + @FieldName + ' != CH.FieldValue' + @FieldType + '_Curr
																						OR		(Hist.' + @FieldName + ' IS NULL AND CH.FieldValue' + @FieldType + '_Curr IS NOT NULL)
																						OR		(Hist.' + @FieldName + ' IS NOT NULL AND CH.FieldValue' + @FieldType + '_Curr IS NULL AND CH.PtlSnapshotId_Start IS NOT NULL)
																						THEN	CAST(1 AS bit) 
																						ELSE	CAST(0 AS bit) 
																						END
										,NextValueIsChangeFromNewValue		=	CASE	WHEN	Hist.' + @FieldName + ' != CH.FieldValue' + @FieldType + '_Next
																						OR		(Hist.' + @FieldName + ' IS NULL AND CH.FieldValue' + @FieldType + '_Next IS NOT NULL)
																						OR		(Hist.' + @FieldName + ' IS NOT NULL AND CH.FieldValue' + @FieldType + '_Next IS NULL AND CH.PtlSnapshotId_Start_Next IS NOT NULL)
																						THEN	CAST(1 AS bit) 
																						ELSE	CAST(0 AS bit) 
																						END
										,ExistingId_Start					=	CH.PtlSnapshotId_Start
										,NextId_Start						=	CH.PtlSnapshotId_Start_Next
										,ExistingValue' + @FieldType + '	=	CH.FieldValue' + @FieldType + '_Curr
										,NewValue' + @FieldType + '			=	Hist.' + @FieldName + '
							FROM		#SCR_PTL_History Hist
							FULL JOIN	#ChangeHistory CH
											ON	Hist.CWT_ID = CH.CWT_ID
											AND	Hist.PtlSnapshotId = ' + CAST(@PtlSnapshotId AS varchar(255)) + '
							WHERE		Hist.PtlSnapshotId = ' + CAST(@PtlSnapshotId AS varchar(255)) + '
							OR			(CH.CWT_ID IS NOT NULL)
							'

							--PRINT @SQL
					
							PRINT 'Executing retrieval from History table.... FieldName: ' + @FieldName + ' FieldType: ' + @FieldType + ' SnapshotID: ' + CAST(@PtlSnapshotId AS varchar(255))
							EXEC (@SQL)

							-- Index the #NewValues table for improved performance
							SELECT @IndexSQL =	'ALTER TABLE #NewValues ADD CONSTRAINT PK_NewValues_' + 
												REPLACE(REPLACE(REPLACE(CONVERT(varchar(255), GETDATE(), 126), '-',''), ':', ''), '.', '') + 
												' PRIMARY KEY CLUSTERED (CWT_ID DESC)'
							EXEC (@IndexSQL)
							CREATE NONCLUSTERED INDEX Ix_ExistingId_Start ON #NewValues (ExistingId_Start DESC)
							CREATE NONCLUSTERED INDEX Ix_NextId_Start ON #NewValues (NextId_Start DESC)
							CREATE NONCLUSTERED INDEX Ix_BeforeFirstChange ON #NewValues (BeforeFirstChange)
							CREATE NONCLUSTERED INDEX Ix_OnExistingChange ON #NewValues (OnExistingChange)
							CREATE NONCLUSTERED INDEX Ix_BetweenExistingChange ON #NewValues (BetweenExistingChange)
							CREATE NONCLUSTERED INDEX Ix_AfterMostRecentChange ON #NewValues (AfterMostRecentChange)
							CREATE NONCLUSTERED INDEX Ix_AfterLastLoadedSnapshot ON #NewValues (AfterLastLoadedSnapshot)
							CREATE NONCLUSTERED INDEX Ix_NextChangeIsNextLoadedSnapshot ON #NewValues (NextChangeIsNextLoadedSnapshot)
							CREATE NONCLUSTERED INDEX Ix_InitialAppearance ON #NewValues (InitialAppearance)
							CREATE NONCLUSTERED INDEX Ix_PrevValueIsChangeFromNewValue ON #NewValues (PrevValueIsChangeFromNewValue)
							CREATE NONCLUSTERED INDEX Ix_ExistingValueIsChangeFromNewValue ON #NewValues (ExistingValueIsChangeFromNewValue)
							CREATE NONCLUSTERED INDEX Ix_NextValueIsChangeFromNewValue ON #NewValues (NextValueIsChangeFromNewValue)
					
							-- Insert any new changes (where there are any to be inserted)
							PRINT '1st Insert' + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
							INSERT INTO	SCR_Reporting_History.SCR_PTL_LT_ChangeHistory (
										PtlSnapshotId_Start
										,CWT_ID
										,FieldNameId
										,FieldValueInt
										,FieldValueString
										,FieldValueDateTime
										)
							SELECT		PtlSnapshotId_Start	=	@PtlSnapshotId
										,CWT_ID				=	NV.CWT_ID
										,FieldNameId		=	@FieldNameId
										,FieldValueInt		=	CASE WHEN @FieldType = 'Int' THEN NV.NewValueInt ELSE CAST(NULL AS int) END
										,FieldValueString	=	CASE WHEN @FieldType = 'String' THEN NV.NewValueString ELSE CAST(NULL AS varchar(max)) END
										,FieldValueDateTime	=	CASE WHEN @FieldType = 'DateTime' THEN NV.NewValueDateTime ELSE CAST(NULL AS datetime2) END
							FROM		#NewValues NV
							WHERE		NV.InitialAppearance = 2
							OR			(NV.BeforeFirstChange = 1 AND NV.NextValueIsChangeFromNewValue = 1)
							OR			(NV.BetweenExistingChange = 1 AND NV.ExistingValueIsChangeFromNewValue = 1 AND NV.NextValueIsChangeFromNewValue = 1)
							OR			(NV.BetweenExistingChange = 1 AND NV.ExistingValueIsChangeFromNewValue = 1 AND NV.NextValueIsChangeFromNewValue = 0 AND NV.NextChangeIsNextLoadedSnapshot = 0) -- added to account for records missing for the snapshots in the middle of a run of snapshopts (e.g. in snapshot 1,2,3,7,8,9)
							OR			(NV.AfterMostRecentChange = 1 AND NV.ExistingValueIsChangeFromNewValue = 1)
					
							-- Insert a null record at the first loaded snapshot ID, if it is prior to an initial appearance record that was just inserted with an initial value wasn't NULL
							PRINT '2nd Insert' + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
							INSERT INTO	SCR_Reporting_History.SCR_PTL_LT_ChangeHistory (
										PtlSnapshotId_Start
										,CWT_ID
										,FieldNameId
										)
							SELECT		PtlSnapshotId_Start	=	CASE	WHEN	@FirstLoaded_SnapshotIx < @SnapshotIx
																		THEN	@FirstLoaded_PtlSnapshotId
																		WHEN	NV.InitialAppearance = 1
																		THEN	@PtlSnapshotId
																		END 
										,CWT_ID				=	NV.CWT_ID
										,FieldNameId		=	@FieldNameId
							FROM		#NewValues NV
							WHERE		(NV.InitialAppearance = 2
							AND			@FirstLoaded_SnapshotIx < @SnapshotIx)
							OR			NV.InitialAppearance = 1
			
							-- Insert change values from loaded snapshots that weren't previously required as change records, as they had an associated change 
							-- record from a prior snapshot, but have now had the associated change record removed or changed
							-- (where there are any to be inserted)
							PRINT '3rd Insert' + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
							INSERT INTO	SCR_Reporting_History.SCR_PTL_LT_ChangeHistory (
										PtlSnapshotId_Start
										,CWT_ID
										,FieldNameId
										,FieldValueInt
										,FieldValueString
										,FieldValueDateTime
										)
							SELECT		PtlSnapshotId_Start	=	@NextLoaded_PtlSnapshotId
										,CWT_ID				=	NV.CWT_ID
										,FieldNameId		=	@FieldNameId
										,FieldValueInt		=	CASE WHEN @FieldType = 'Int' THEN NV.ExistingValueInt ELSE CAST(NULL AS int) END
										,FieldValueString	=	CASE WHEN @FieldType = 'String' THEN NV.ExistingValueString ELSE CAST(NULL AS varchar(max)) END
										,FieldValueDateTime	=	CASE WHEN @FieldType = 'DateTime' THEN NV.ExistingValueDateTime ELSE CAST(NULL AS datetime2) END
							FROM		#NewValues NV
							WHERE		(NV.InitialAppearance = 2 AND @NextLoaded_PtlSnapshotId IS NOT NULL)
							OR			(NV.OnExistingChange = 1 AND NV.ExistingValueIsChangeFromNewValue = 1 AND NV.NextChangeIsNextLoadedSnapshot = 0)
							OR			(NV.BetweenExistingChange = 1 AND NV.ExistingValueIsChangeFromNewValue = 1 AND NV.NextChangeIsNextLoadedSnapshot = 0) -- need to understand why snapshot id 312 didn't become the first of the "missing" values -- because 312 is the first record loaded!
							OR			(NV.AfterMostRecentChange = 1 AND NV.ExistingValueIsChangeFromNewValue = 1 AND NV.AfterLastLoadedSnapshot = 0)

							-- Update the existing change records (where they need to be altered)
							PRINT '1st Update' + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
							UPDATE		CH
							SET			FieldValueInt		=	NV.NewValueInt 
										,FieldValueString	=	NV.NewValueString
										,FieldValueDateTime	=	NV.NewValueDateTime 
							FROM		(SELECT * FROM SCR_Reporting_History.SCR_PTL_LT_ChangeHistory WHERE FieldNameId = @FieldNameId) CH
							INNER JOIN	#NewValues NV
											ON	CH.CWT_ID = NV.CWT_ID
											--AND	CH.FieldNameId = @FieldNameId
											AND	CH.PtlSnapshotId_Start = NV.ExistingId_Start
							WHERE		NV.OnExistingChange = 1 AND NV.ExistingValueIsChangeFromNewValue = 1 AND NV.PrevValueIsChangeFromNewValue = 1

							-- Update the next change records (where they need to be shifted)
							PRINT '2nd Update' + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
							UPDATE		CH
							SET			PtlSnapshotId_Start	= @PtlSnapshotId
							FROM		(SELECT * FROM SCR_Reporting_History.SCR_PTL_LT_ChangeHistory WHERE FieldNameId = @FieldNameId) CH
							INNER JOIN	#NewValues NV
											ON	CH.CWT_ID = NV.CWT_ID
											--AND	CH.FieldNameId = @FieldNameId
											AND	CH.PtlSnapshotId_Start = NV.NextId_Start
							WHERE		(NV.BeforeFirstChange = 1 AND NV.NextValueIsChangeFromNewValue = 0)
							OR			(NV.BetweenExistingChange = 1 AND NV.ExistingValueIsChangeFromNewValue = 1 AND NV.NextValueIsChangeFromNewValue = 0 AND NV.NextChangeIsNextLoadedSnapshot = 1)

							-- Delete the existing change records (where they need to be deleted)
							PRINT '1st Delete' + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
							DELETE
							FROM		CH
							FROM		(SELECT * FROM SCR_Reporting_History.SCR_PTL_LT_ChangeHistory WHERE FieldNameId = @FieldNameId) CH
							INNER JOIN	#NewValues NV
											ON	CH.CWT_ID = NV.CWT_ID
											--AND	CH.FieldNameId = @FieldNameId
											AND	CH.PtlSnapshotId_Start = NV.ExistingId_Start
							WHERE		NV.OnExistingChange = 1 AND NV.ExistingValueIsChangeFromNewValue = 1 AND NV.PrevValueIsChangeFromNewValue = 0

							-- Delete the next change records (where they need to be deleted)
							PRINT '2nd Delete' + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
							DELETE
							FROM		CH
							FROM		(SELECT * FROM SCR_Reporting_History.SCR_PTL_LT_ChangeHistory WHERE FieldNameId = @FieldNameId) CH
							INNER JOIN	#NewValues NV
											ON	CH.CWT_ID = NV.CWT_ID
											--AND	CH.FieldNameId = @FieldNameId
											AND	CH.PtlSnapshotId_Start = NV.NextId_Start
							WHERE		NV.OnExistingChange = 1 AND NV.ExistingValueIsChangeFromNewValue = 1 AND NV.NextValueIsChangeFromNewValue = 0 AND NV.NextChangeIsNextLoadedSnapshot = 1

							-- Add the processed field into the table
							INSERT INTO	SCR_Reporting_History.SCR_PTL_LT_FieldNameIdPresence (
										PtlSnapshotId
										,FieldNameId
										)
							SELECT		@PtlSnapshotId
										,@FieldNameId

							-- Keep a record of when the inserts to the SR_PTL_LT_History process ended
							SET @StepName = 'Process Change History snapshot for FieldNameId: ' + CAST(@FieldNameId AS varchar(255)) + ' FieldName: ' + @FieldName + ' FieldType: ' + @FieldType
							EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory', @Step = @StepName

						-- End check that there is a field in the lookup table
						END

						-- Iterate to the next field
						SET @FieldNameId = @FieldNameId + 1
				
					-- End looping through the fields that we process changes for
					END

					-- Keep a record of all the CWT_IDs that were present in the snapshot
					INSERT INTO	SCR_Reporting_History.SCR_PTL_LT_CwtPresence (PtlSnapshotId, CWT_ID)
					SELECT		PtlSnapshotId	=	@PtlSnapshotId
								,CWT_ID			=	CWT_ID
					FROM		#SCR_PTL_History

					-- Mark the snapshot as processed
					UPDATE		SCR_Reporting_History.SCR_PTL_SnapshotDates
					SET			LoadedIntoLTChangeHistory = 1
					WHERE		PtlSnapshotId = @PtlSnapshotId
						
					-----------------------------------------------------------------------------------------------------------------------------------------------
					-- Take a census of the post processed current snapshot for comparison against the source snapshot
					-----------------------------------------------------------------------------------------------------------------------------------------------

					-- Keep a record of when the check snapshot creation started
					EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory', @Step = 'Create Change History check snapshot'

					-- Drop the census for the current loaded snapshot date (if it exists)
					IF OBJECT_ID('SCR_Reporting_History.CheckCurrentLoadedSnapshot') IS NOT NULL
					DROP TABLE SCR_Reporting_History.CheckCurrentLoadedSnapshot
						
					-- Create a census of the snapshot that has just been loaded (so we can make sure the loaded data is the same as the original data)
					EXEC SCR_Reporting_History.uspCreateSCR_PTL_LT_Census
							@CensusDate = @PtlSnapshotDate
							,@OutputTableName = 'SCR_Reporting_History.CheckCurrentLoadedSnapshot'
							,@ReadUncommitted = 1

					-- Keep a record of when the check snapshot creation ended
					EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory', @Step = 'Create Change History check snapshot'

					-----------------------------------------------------------------------------------------------------------------------------------------------
					-- Create the dynamic SQL that will be used to verify the snapshot loading process
					-----------------------------------------------------------------------------------------------------------------------------------------------
					
					-- Keep a record of when the snapshot check process started
					EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory', @Step = 'Check Change History snapshot'

					-- Start the dynamic SQL statement to look for Match errors between the verified current snapshot and the post-processing current snapshot
					SET @CurrentMatchErrorSQL	=	'SELECT		@CurrentMatchErrorCount = COUNT(*) ' + CHAR(10) +
													'FROM		#SCR_PTL_History Verified' + CHAR(10) +
													'INNER JOIN	SCR_Reporting_History.CheckCurrentLoadedSnapshot CheckSnap' + CHAR(10) +
													'				ON Verified.CWT_ID = CheckSnap.CWT_ID' + CHAR(10)

					-- Loop through each field in the Change History Field Name list and add it to the where clause of the dynamic SQL statement
					SET @SQL_LoopCounter = 1
				
					WHILE @SQL_LoopCounter <= (SELECT MAX(FieldNameIx) FROM #MatchErrorSql)
					BEGIN

						-- Add the fields we will be checking to the where clause
						SELECT		@CurrentMatchErrorSQL	=	@CurrentMatchErrorSQL +  
																CASE WHEN mes.FieldNameIx = 1 THEN 'WHERE ' ELSE 'OR ' END + 
																mes.WhereClause
						FROM		#MatchErrorSql mes
						INNER JOIN	SCR_Reporting_History.SCR_PTL_LT_FieldNameIdPresence Fields
										ON	mes.FieldNameId = Fields.FieldNameId
										AND	Fields.PtlSnapshotId = @PtlSnapshotId
						WHERE		mes.FieldNameIx = @SQL_LoopCounter

						-- Increment the SQL loop counter
						SET @SQL_LoopCounter = @SQL_LoopCounter + 1

					END
					
					-----------------------------------------------------------------------------------------------------------------------------------------------
					-- verify the current snapshot
					-----------------------------------------------------------------------------------------------------------------------------------------------

					-- Check for records in the source snapshot and not in the post processed current snapshot
					SELECT		@CurrentVerifiedOnlyErrorCount = COUNT(*)
					FROM		#SCR_PTL_History Verified
					LEFT JOIN	SCR_Reporting_History.CheckCurrentLoadedSnapshot CheckSnap
									ON	Verified.CWT_ID = CheckSnap.CWT_ID
					WHERE		CheckSnap.CWT_ID IS NULL

					-- Check for records in the post processed current snapshot and not in the source snapshot
					SELECT		@CurrentCheckSnapOnlyErrorCount = COUNT(*)
					FROM		SCR_Reporting_History.CheckCurrentLoadedSnapshot CheckSnap
					LEFT JOIN	#SCR_PTL_History Verified
									ON	CheckSnap.CWT_ID = Verified.CWT_ID
					WHERE		Verified.CWT_ID IS NULL

					-- Run the dynamic SQL to look for Match errors between the source snapshot and the post processed current snapshot
					EXEC sp_executesql @CurrentMatchErrorSQL,
						N'@CurrentMatchErrorCount int OUTPUT',
						@CurrentMatchErrorCount OUTPUT

					-- If there is an error between the source snapshot and the post processed current snapshot then roll back the transaction
					IF	@CurrentVerifiedOnlyErrorCount != 0
					OR	@CurrentCheckSnapOnlyErrorCount != 0
					OR	@CurrentMatchErrorCount != 0
					BEGIN
							PRINT 'Rolling back because of unverified difference after loading snapshot ID ' + CAST(@PtlSnapshotId AS varchar(255)) + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
							PRINT 'Records missing from new snapshot: ' + CAST(@CurrentVerifiedOnlyErrorCount AS varchar(255))
							PRINT 'Records in new snapshot but not in the source snapshot: ' + CAST(@CurrentCheckSnapOnlyErrorCount AS varchar(255))
							PRINT 'Records in the new and source snapshot but with different values: ' + CAST(@CurrentMatchErrorCount AS varchar(255))
							PRINT @CurrentMatchErrorSQL
							ROLLBACK TRANSACTION
					END

					ELSE
					BEGIN
							PRINT 'Committal of loaded snapshot ID ' + CAST(@PtlSnapshotId AS varchar(255)) + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
							COMMIT TRANSACTION

					-- Keep a record of when the snapshot check process ended
					EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory', @Step = 'Check Change History snapshot'

					END

				-- End the try block
				END TRY

				-- In case the transaction failed 
				BEGIN CATCH

					IF @@TRANCOUNT > 0 -- SELECT @@TRANCOUNT
						PRINT 'Rolling back because of error in loading snapshot ID ' + CAST(@PtlSnapshotId AS varchar(255)) + ' at ' + CONVERT(varchar(255), GETDATE(), 126)
						ROLLBACK TRANSACTION
 
					SELECT ERROR_NUMBER() AS ErrorNumber
					SELECT ERROR_MESSAGE() AS ErrorMessage
					SELECT ERROR_LINE() AS ErrorLine
 
				END CATCH	

			-- Keep a record of when the snapshot load ended
			SET @StepName = 'Load Change History snapshot id: ' + CAST(@PtlSnapshotId AS varchar(255))
			EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory', @Step = @StepName

			-- Iterate to the next snapshot to process
			SET @SnapshotLoopId = @SnapshotLoopId + 1

			-- Reset the @FieldNameId
			SET @FieldNameId = 1
			
		-- End looping through each snapshot to process the old archive data
		END


		--Keep a record of when the inserts to the SR_PTL_LT_History process finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_ChangeHistory', @Step = 'Load Change History records'


GO
