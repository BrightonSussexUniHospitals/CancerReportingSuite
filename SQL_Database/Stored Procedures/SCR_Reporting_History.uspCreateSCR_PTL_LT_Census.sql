USE [CancerReporting]
GO
/****** Object:  StoredProcedure [SCR_Reporting_History].[uspCreateSCR_PTL_LT_Census]    Script Date: 03/09/2020 23:43:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [SCR_Reporting_History].[uspCreateSCR_PTL_LT_Census] (

			-- Set up external variables for use by the procedure
			@CensusDate datetime
			,@OutputTableName varchar(255) = NULL
			,@ReadUncommitted bit = 0
			,@IncludeFieldsNotInChangeHistory bit = 0

) AS

/******************************************************** © Copyright & Licensing ****************************************************************
© 2020 Perspicacity Ltd & Brighton & Sussex University Hospitals NHS Trust

Original Work Created Date:	17/06/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Recreate a snapshot from the long term change history archive datasets of the SCR PTL reporting
**************************************************************************************************************************************************/

-- Test me
-- DROP TABLE SCR_Reporting_History.Census_195
-- EXEC SCR_Reporting_History.uspCreateSCR_PTL_LT_Census @CensusDate = '01 Jan 2020', @OutputTableName = 'SCR_Reporting_History.Census_195'
-- DROP TABLE SCR_Reporting_History.Census_301
-- EXEC SCR_Reporting_History.uspCreateSCR_PTL_LT_Census @CensusDate = '2020-04-15 05:00:06.523', @OutputTableName = 'SCR_Reporting_History.Census_301'


-- Set up internal variables for use by the procedure
DECLARE @PtlSnapshotDate datetime
DECLARE @PtlSnapshotId int
DECLARE @LoopIx int = 1
DECLARE @FieldNameId int
DECLARE @FieldName varchar(255)
DECLARE @InChangeHistory bit
DECLARE @SQL_AddColumn varchar(max)
DECLARE	@SQL_UpdateData varchar(max)
DECLARE @SQL_Output varchar(max)
DECLARE @IndexSQL nvarchar(max)
DECLARE @StepName varchar(255)

IF @ReadUncommitted = 1
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
END
ELSE
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
END

/************************************************************************************************************************************************************************************************************
-- Create census
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the inserts to the SR_PTL_LT_History process started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_Census', @Step = 'Recreate PTL snapshot'

		-- Drop the #CH_PTL_SnapshotDates table
		IF OBJECT_ID('tempdb..#CH_PTL_SnapshotDates') IS NOT NULL
		DROP TABLE #CH_PTL_SnapshotDates

		-- Create a temp table of the snapshot ID's found in the SCR_PTL_LT_ChangeHistory table
		SELECT		SD.PtlSnapshotDate
					,SD.PtlSnapshotId
					,SD.LoadedIntoLTChangeHistory
					,SD.LoadedIntoStatistics
					,SD.LoadedIntoLastPtlRecord
		INTO		#CH_PTL_SnapshotDates
		FROM		SCR_Reporting_History.SCR_PTL_LT_ChangeHistory CH
		INNER JOIN	SCR_Reporting_History.SCR_PTL_SnapshotDates SD
						ON	CH.PtlSnapshotId_Start = SD.PtlSnapshotId
		GROUP BY	CH.PtlSnapshotId_Start
					,SD.PtlSnapshotDate
					,SD.PtlSnapshotId
					,SD.LoadedIntoLTChangeHistory
					,SD.LoadedIntoStatistics
					,SD.LoadedIntoLastPtlRecord


		-- Find the most recent snapshot prior to the census date
		SELECT		TOP 1
					@PtlSnapshotDate = PtlSnapshotDate
					,@PtlSnapshotId = PtlSnapshotId
		FROM		#CH_PTL_SnapshotDates 
		WHERE		PtlSnapshotDate <= @CensusDate
		ORDER BY	PtlSnapshotDate DESC
					,PtlSnapshotId DESC

		PRINT 'Recreating PTL Snapshot Id ' + CAST(@PtlSnapshotId AS varchar(255)) + '...'

		-- Drop the temp table of all the snapshots prior to the census date
		IF OBJECT_ID('tempdb..#PotentialSnapshots') IS NOT NULL
		DROP TABLE #PotentialSnapshots

		-- Create a temp table of all the snapshots prior to the census date
		CREATE TABLE #PotentialSnapshots (
					PtlSnapshotId int NOT NULL
					,PtlSnapshotIx int NOT NULL
					)

		-- Create a temp table of all the snapshots prior to the census date -- 02:15
		INSERT INTO	#PotentialSnapshots (PtlSnapshotId, PtlSnapshotIx)
		SELECT		PtlSnapshotId
					,ROW_NUMBER() OVER (ORDER BY PtlSnapshotDate) AS PtlSnapshotIx
		FROM		#CH_PTL_SnapshotDates 
		WHERE		PtlSnapshotDate <= @PtlSnapshotDate

		-- Drop the output #PtlCensus table
		IF OBJECT_ID('tempdb..#PtlCensus') IS NOT NULL
		DROP TABLE #PtlCensus

		-- Create the temp table of the CWT_IDs present in the original snapshot
		CREATE TABLE #PtlCensus (
					PresenceId int IDENTITY(1,1) NOT NULL
					,CWT_ID varchar(255) NOT NULL
					)

		-- Index the #PtlCensus table for improved performance
		SELECT @IndexSQL =	'ALTER TABLE #PtlCensus ADD CONSTRAINT PK_PtlCensus_' + 
							REPLACE(REPLACE(REPLACE(CONVERT(varchar(255), GETDATE(), 126), '-',''), ':', ''), '.', '') + 
							' PRIMARY KEY CLUSTERED (CWT_ID)'

		EXEC (@IndexSQL)
		
		-- Insert the CWT_IDs present in the original snapshot into the #Presence table
		INSERT INTO	#PtlCensus (CWT_ID)
		SELECT		CWT_ID
		FROM		SCR_Reporting_History.SCR_PTL_LT_CwtPresence Presence
		WHERE		Presence.PtlSnapshotId = @PtlSnapshotId

		-- Drop the temp table of the most recent snapshot record for each field and CWT _ID
		IF OBJECT_ID('tempdb..#MostRecentSnapshotId') IS NOT NULL
		DROP TABLE #MostRecentSnapshotId

		-- Create a temp table of the most recent snapshot record for each field and CWT _ID
		SELECT		Hist.CWT_ID
					,Hist.FieldNameId
					,PS.PtlSnapshotId
		INTO		#MostRecentSnapshotId
		FROM		(SELECT		CH.CWT_ID
								,CH.FieldNameId
								,MAX(PSi.PtlSnapshotIx) AS MaxPtlSnapshotIx
					FROM		SCR_Reporting_History.SCR_PTL_LT_ChangeHistory CH
					INNER JOIN	#PotentialSnapshots PSi
									ON	CH.PtlSnapshotId_Start = PSi.PtlSnapshotId
					INNER JOIN	SCR_Reporting_History.SCR_PTL_LT_FieldNameIdPresence Fields
									ON	CH.FieldNameId = Fields.FieldNameId
									AND	Fields.PtlSnapshotId = @PtlSnapshotId
					WHERE		CH.FieldNameId != 0
					GROUP BY	CH.CWT_ID
								,CH.FieldNameId) Hist
		INNER JOIN	#PotentialSnapshots PS
						ON	Hist.MaxPtlSnapshotIx = PS.PtlSnapshotIx 

		-- Drop the temp table of the fields that we will recreate in the census
		IF OBJECT_ID('tempdb..#FieldIds') IS NOT NULL
		DROP TABLE #FieldIds

		-- Create a temp table of the fields that we will recreate in the census
		-- (with an order number so that we can process them one by one)
		CREATE TABLE #FieldIds (
						LoopIx int
						,FieldNameId int
						,InChangeHistory bit
						)

		INSERT INTO	#FieldIds (LoopIx, FieldNameId, InChangeHistory)
		SELECT		ROW_NUMBER() OVER (ORDER BY ISNULL(InChangeHistory.FieldNameId, Fields.FieldNameId)) AS LoopIx
					,ISNULL(InChangeHistory.FieldNameId, Fields.FieldNameId) AS FieldNameId
					,CASE WHEN InChangeHistory.FieldNameId IS NOT NULL THEN 1 ELSE 0 END AS InChangeHistory
		FROM		LocalConfig.SCR_PTL_LT_ChangeHistoryFields Fields
		FULL JOIN	SCR_Reporting_History.SCR_PTL_LT_FieldNameIdPresence InChangeHistory
						ON	Fields.FieldNameId = InChangeHistory.FieldNameId
						AND	InChangeHistory.PtlSnapshotId = @PtlSnapshotId
		WHERE		InChangeHistory.PtlSnapshotId = @PtlSnapshotId
		OR			(InChangeHistory.FieldNameId IS NULL
		AND			Fields.Inactive = 0)

		-- Create the temp #MostRecentSnapshotValues table finding most recent values for the snapshot -- no index on mrsi 04:54 (+01:57 to make table) / with index 02:52 (+07:04 to make table)
		SELECT		PtlCensus.PresenceId
					,Hist.FieldNameId
					,Hist.FieldValueInt
					,Hist.FieldValueString
					,Hist.FieldValueDatetime
		INTO		#MostRecentSnapshotValues
		FROM		SCR_Reporting_History.SCR_PTL_LT_ChangeHistory Hist
		INNER JOIN	#MostRecentSnapshotId mrsi
						ON	Hist.CWT_ID = mrsi.CWT_ID
						AND	Hist.FieldNameId = mrsi.FieldNameId
						AND	Hist.PtlSnapshotId_Start = mrsi.PtlSnapshotId
		INNER JOIN	#PtlCensus PtlCensus
						ON	Hist.CWT_ID = PtlCensus.CWT_ID

		-- Loop through each field one by one and add the data to the #PtlCensus output table
		WHILE @LoopIx <= (SELECT MAX(LoopIx) FROM #FieldIds)
		BEGIN

			-- Find the FieldNameId that we are currently processing
			SELECT		@FieldNameId = FieldNameId
						,@InChangeHistory = InChangeHistory
			FROM		#FieldIds
			WHERE		LoopIx = @LoopIx
	
			-- Create the SQL statements to add the field onto the #PtlCensus output table and
			-- then update the #PtlCensus output table with the data from the long term history
			SELECT		@FieldName			=	FieldName
						,@SQL_AddColumn		=	'ALTER TABLE #PtlCensus ADD ' + FieldName + ' ' +
												CASE	WHEN FieldType = 'String' 
														THEN 'varchar(max)' 
														WHEN FieldType = 'Int' 
														THEN 'real' 
														WHEN FieldType = 'Datetime' 
														THEN 'datetime2' 
														ELSE FieldType 
														END
						,@SQL_UpdateData	=	'UPDATE		PTL 
												SET			' + FieldName + ' = mrsv.FieldValue' + FieldType + '
												FROM		#PtlCensus PTL
												INNER JOIN	#MostRecentSnapshotValues mrsv
																ON	PTL.PresenceId = mrsv.PresenceId
																AND	mrsv.FieldNameId = ' + CAST(FieldNameId AS varchar(255))
			FROM		LocalConfig.SCR_PTL_LT_ChangeHistoryFields
			WHERE		FieldNameId = @FieldNameId

			-- Keep a record of when the addition of the next field to the census started
			SET @StepName = 'Recreate PTL snapshot for FieldNameId: ' + CAST(@FieldNameId AS varchar(255)) + ' FieldName: ' + CAST(@FieldName AS varchar(255))
			EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_Census', @Step = @StepName
				
			-- Execute the SQL to add the field to the #PtlCensus output table
			--PRINT @SQL_AddColumn
			IF  @InChangeHistory = 1 OR @IncludeFieldsNotInChangeHistory = 1
			BEGIN
				PRINT 'Adding column: ' + @FieldName + '(FieldNameId: ' + CAST(@FieldNameId AS varchar(255)) + ')'
				EXEC (@SQL_AddColumn)
			END

			-- Execute the SQL to update the #PtlCensus output table with the data from the long term history (but only if it's in there)
			--PRINT @SQL_UpdateData
			IF @InChangeHistory = 1
			BEGIN
				EXEC (@SQL_UpdateData)
			END

			-- Keep a record of when the addition of the next field to the census ended
			SET @StepName = 'Recreate PTL snapshot for FieldNameId: ' + CAST(@FieldNameId AS varchar(255)) + ' FieldName: ' + CAST(@FieldName AS varchar(255))
			EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_Census', @Step = @StepName
				
			SET @LoopIx = @LoopIx + 1

		END

		--Keep a record of when the inserts to the SR_PTL_LT_History process finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspCreateSCR_PTL_LT_Census', @Step = 'Recreate PTL snapshot'


/****************************************************************************************************************************************************************************/
-- Return the census snapshot
/****************************************************************************************************************************************************************************/

		-- Drop the PresenceId column 
		ALTER TABLE #PtlCensus DROP COLUMN PresenceId

		-- If an output table name has been provided
		IF ISNULL(@OutputTableName, '') != ''
		BEGIN
				-- Create the SQL to write the data 
				SET @SQL_Output	=	'SELECT		* 
									INTO		' + @OutputTableName + '
									FROM		#PtlCensus'
									
				EXEC (@SQL_Output)

				-- Write the data to the output table
		END
		ELSE
		BEGIN
				-- Return the data
				SELECT * FROM #PtlCensus
		END

GO
