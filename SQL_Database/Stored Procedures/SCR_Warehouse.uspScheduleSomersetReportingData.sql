SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [SCR_Warehouse].[uspScheduleSomersetReportingData] AS

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
Description:				This procedure contains the logic to decide which parameters should be used when
							in the creation of the warehouse datasets for all SCR / Somerset reporting.
							It allows for simple job execution to update the SCR reporting datasets by
							containing the complex logic here rather than trying to encapsulate it in a
							series of conditional job steps or jobs.
							It also facilitates all updates being processed from a single job, allowing
							us to ensure that there are no update processes running concurrently and 
							competing with one another for the same resource.
**************************************************************************************************************************************************/

-- EXEC SCR_Warehouse.uspScheduleSomersetReportingData -- Run me

		DECLARE @StepName varchar(255) = ''
		DECLARE @pahId int

/******************************************************************************************************************************************************************************/
-- Keep a record of which cluster node is active
/******************************************************************************************************************************************************************************/
		
		DECLARE @ActiveClusterNode varchar(255)
		SELECT @ActiveClusterNode = CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS varchar(255))

/******************************************************************************************************************************************************************************/
-- Run the 05:00 daily & weekly snapshot and PtlHistory if it hasn't already run
/******************************************************************************************************************************************************************************/

		IF	ISNULL((SELECT		LastSuccessfullyCompleted 
			FROM		SCR_Warehouse.ProcessAudit 
			WHERE		Process = 'SCR_Reporting_History.uspCreateSomersetReportingHistory' 
			AND			Step = 'Insert PTL History'), CAST('01 Jan 1900' AS datetime))					-- the most recent successful insertion into the history table
																										-- (Taken from the ProcessAudit table as the PtlHistory table takes a long time to query)
			< DATEADD(hh, 5, CAST(CAST(GETDATE() AS date) AS datetime))									-- earlier than 05:00 this morning
		AND	GETDATE() >= DATEADD(hh, 5, CAST(CAST(GETDATE() AS date) AS datetime))						-- It is now after 05:00 this morning
		AND (SELECT		COUNT(*) 
			FROM		SCR_Reporting.PTL_Weekly 
			WHERE		PtlSnapshotDate >= 
						DATEADD(wk, DATEDIFF(wk, 0, DATEADD(DAY,-1,GETDATE())), 0)
			) = 0																						-- There are no records in PTL_Weekly that have a snapshot date since this Monday
		BEGIN
			
			SET @StepName = '05:00 weekly snapshot and PtlHistory on ' + @ActiveClusterNode
			EXEC SCR_Warehouse.uspUpdateProcessAuditHistory @Process = 'uspScheduleSomersetReportingData', @Step = @StepName, @ProcessAuditHistoryIdCreated = @pahId OUTPUT
			PRINT 'Start ' + @StepName

			-- Update the Next Actions
			EXEC SCR_Warehouse.uspCaptureNextActionChanges 
				@IncrementalUpdate = 0			-- Bulk load
				,@CaptureNextActionChanges = 1	-- Keep a record of any changes to the next action table
			
			-- Update the warehouse cancer datasets
			EXEC SCR_Warehouse.uspCreateSomersetReportingData 
				@IncrementalUpdate = 0			-- Bulk load
				,@UpdatePtlSnapshots = 6		-- Reset the daily & weekly snapshot to match live

			-- Update the SCR_PTL_History table
			EXEC SCR_Reporting_History.uspCreateSomersetReportingHistory

			GOTO ProcedureClose
		END

/******************************************************************************************************************************************************************************/
-- Run the 05:00 daily snapshot and PtlHistory if it hasn't already run
/******************************************************************************************************************************************************************************/

		IF	(ISNULL((SELECT		MAX(PtlSnapshotDate)
			FROM		SCR_Reporting_History.SCR_PTL_SnapshotDates), CAST('01 Jan 1900' AS datetime))	-- the most recent successful insertion into the history table
			< DATEADD(hh, 5, CAST(CAST(GETDATE() AS date) AS datetime))									-- earlier than 05:00 this morning
		AND	GETDATE() >= DATEADD(hh, 5, CAST(CAST(GETDATE() AS date) AS datetime)))						-- It is now after 05:00 this morning
		BEGIN
			
			SET @StepName = '05:00 daily snapshot and PtlHistory on ' + @ActiveClusterNode
			EXEC SCR_Warehouse.uspUpdateProcessAuditHistory @Process = 'uspScheduleSomersetReportingData', @Step = @StepName, @ProcessAuditHistoryIdCreated = @pahId OUTPUT
			PRINT 'Start ' + @StepName

			-- Update the Next Actions
			EXEC SCR_Warehouse.uspCaptureNextActionChanges 
				@IncrementalUpdate = 0			-- Bulk load
				,@CaptureNextActionChanges = 1	-- Keep a record of any changes to the next action table
			
			-- Update the warehouse cancer datasets
			EXEC SCR_Warehouse.uspCreateSomersetReportingData 
				@IncrementalUpdate = 0			-- Bulk load
				,@UpdatePtlSnapshots = 2		-- Reset the daily snapshot to match live

			-- Update the SCR_PTL_History table
			EXEC SCR_Reporting_History.uspCreateSomersetReportingHistory

			GOTO ProcedureClose
		END

/******************************************************************************************************************************************************************************/
-- Run the 17:00 daily snapshot if it hasn't already run
/******************************************************************************************************************************************************************************/

		IF	ISNULL(
			(SELECT		MIN(ReportDate)
			FROM		SCR_Reporting.PTL_Daily)						-- the most recent successful bulk refresh of the PTL_Daily dataset
			,CAST (0 AS datetime))
			< DATEADD(hh, 17, CAST(CAST(GETDATE() AS date) AS datetime))				-- earlier than 17:00 this afternoon
		AND	GETDATE() >= DATEADD(hh, 17, CAST(CAST(GETDATE() AS date) AS datetime))		-- It is now after 17:00 this afternoon
		AND	CAST(GETDATE() AS time)														-- Current time
			<= CAST(DATEADD(hh,21,0) AS time)											-- On or before 9pm
		BEGIN
			
			SET @StepName = '17:00 daily snapshot on ' + @ActiveClusterNode
			EXEC SCR_Warehouse.uspUpdateProcessAuditHistory @Process = 'uspScheduleSomersetReportingData', @Step = @StepName, @ProcessAuditHistoryIdCreated = @pahId OUTPUT
			PRINT 'Start ' + @StepName

			-- Update the Next Actions
			EXEC SCR_Warehouse.uspCaptureNextActionChanges 
				@IncrementalUpdate = 0			-- Bulk load
				,@CaptureNextActionChanges = 1	-- Keep a record of any changes to the next action table
			
			-- Update the warehouse cancer datasets
			EXEC SCR_Warehouse.uspCreateSomersetReportingData 
				@IncrementalUpdate = 0			-- Bulk load
				,@UpdatePtlSnapshots = 2		-- Reset the daily snapshot to match live

			GOTO ProcedureClose
		END
		
/******************************************************************************************************************************************************************************/
		-- Run the incremental snapshot between 07:00 and 22:00
/******************************************************************************************************************************************************************************/

		IF	CAST(GETDATE() AS time)				-- Current time
			>= CAST(DATEADD(hh,7,0) AS time)	-- On or after 7am
		AND	CAST(GETDATE() AS time)				-- Current time
			<= CAST(DATEADD(hh,22,0) AS time)	-- On or before 9pm
		BEGIN
			
			SET @StepName = 'Incremental snapshot on ' + @ActiveClusterNode
			EXEC SCR_Warehouse.uspUpdateProcessAuditHistory @Process = 'uspScheduleSomersetReportingData', @Step = @StepName, @ProcessAuditHistoryIdCreated = @pahId OUTPUT
			PRINT 'Start ' + @StepName

			-- Update the Next Actions
			EXEC SCR_Warehouse.uspCaptureNextActionChanges 
				@IncrementalUpdate = 1			-- Incremental load
				,@CaptureNextActionChanges = 1	-- Keep a record of any changes to the next action table
			
			-- Update the warehouse cancer datasets
			EXEC SCR_Warehouse.uspCreateSomersetReportingData 
				@IncrementalUpdate = 1			-- Incremental load
				,@UpdatePtlSnapshots = 1		-- Only update the daily snapshot with selective changes

			GOTO ProcedureClose
		END
		
/******************************************************************************************************************************************************************************/
		-- Update the Next Actions
/******************************************************************************************************************************************************************************/

		BEGIN
			
			SET @StepName = 'Update the Next Actions on ' + @ActiveClusterNode
			EXEC SCR_Warehouse.uspUpdateProcessAuditHistory @Process = 'uspScheduleSomersetReportingData', @Step = @StepName, @ProcessAuditHistoryIdCreated = @pahId OUTPUT
			PRINT 'Start ' + @StepName

			-- Update the Next Actions
			EXEC SCR_Warehouse.uspCaptureNextActionChanges 
				@IncrementalUpdate = 1			-- Incremental load
				,@CaptureNextActionChanges = 1	-- Keep a record of any changes to the next action table

			GOTO ProcedureClose
		END

/******************************************************************************************************************************************************************************/
ProcedureClose:
/******************************************************************************************************************************************************************************/
		
		PRINT CASE	WHEN @StepName = ''
					THEN 'SCR_Warehouse.uspCreateSomersetReportingData was not executed'
					ELSE 'SCR_Warehouse.uspCreateSomersetReportingData was executed for the ' + @Stepname
					END

		EXEC SCR_Warehouse.uspUpdateProcessAuditHistory @ProcessAuditHistoryId = @pahId, @Process = 'uspScheduleSomersetReportingData', @Step = @StepName

GO
