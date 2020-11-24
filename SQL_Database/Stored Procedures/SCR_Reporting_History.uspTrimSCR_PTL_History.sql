SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [SCR_Reporting_History].[uspTrimSCR_PTL_History] (

					-- Set up external variables for use by the procedure
					@DaysToKeepDaily int = 45
					,@WeeksToKeepWeekly int = 53
					,@MonthsToKeepMonthly int = 120

) AS

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

Original Work Created Date:	19/05/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Delete snapshots from the SCR_PTL_History table that are
							no longer required for archive purposes (to reduce space
							taken up by the various archives)
**************************************************************************************************************************************************/

-- Test me
-- EXEC SCR_Reporting_History.uspTrimSCR_PTL_History

/************************************************************************************************************************************************************************************************************
-- Setup the parameters for this stored procedure
************************************************************************************************************************************************************************************************************/

-- Set up internal variables for use by the procedure
DECLARE @RollingHistWeeks real = 6
DECLARE @Yesterday datetime = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()) - 1, 0)
DECLARE @AvgWeeklyAdditions real
DECLARE @StDevWeeklyAdditions real
DECLARE @DeleteIteration int = 1
DECLARE @DeletePtlSnapshotId int
DECLARE @ProcessAuditHistoryStep varchar(255)

/************************************************************************************************************************************************************************************************************
-- Analyse which snapshots in the SCR_PTL_History dataset will be archived and / or deleted
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the archival analysis started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspTrimSCR_PTL_History', @Step = 'PTL History Snapshot Analysis'

		-- Clean up any temp tables if they exist
		IF OBJECT_ID('tempdb..#SnapshotAnalysis') IS NOT NULL
		BEGIN
			DROP TABLE #SnapshotAnalysis
		END

		IF OBJECT_ID('tempdb..#WeeklyChanges') IS NOT NULL
		BEGIN
			DROP TABLE #WeeklyChanges
		END

		IF OBJECT_ID('tempdb..#SnapshotsToDelete') IS NOT NULL
		BEGIN
			DROP TABLE #SnapshotsToDelete
		END

		-- Create a temp table to determine which snapshots are to be deleted
		SELECT		ROW_NUMBER() OVER (ORDER BY Snap.PtlSnapshotDate ASC) AS SnapshotIx
					,CAST(NULL AS int) AS LastInDayIx
					,CAST(NULL AS int) AS SnapshotsInDailyIx
					,CAST(NULL AS int) AS SnapshotsInWeeklyIx
					,CAST(NULL AS int) AS SnapshotsInMonthlyIx
					,Hist.PtlSnapshotId
					,Snap.PtlSnapshotDate
					,DATEADD(DAY,DATEDIFF(DAY,0,Snap.PtlSnapshotDate),0) AS PtlSnapshotDay
					,DATEADD(WEEK,DATEDIFF(WEEK,0,DATEADD(DAY,-1,CAST(Snap.PtlSnapshotDate AS date))),0) AS PtlSnapshotWeek
					,DATEADD(MONTH,DATEDIFF(MONTH,0,CAST(Snap.PtlSnapshotDate AS date)),0) AS PtlSnapshotMonth
					,CAST(NULL AS bit) AS LastInDay
					,COUNT(*) AS NumRows
					,CAST(NULL AS int) AS ChangeSinceLastSnapshot
					,CAST(NULL AS real) AS DaysSinceLastSnapshot
					,CAST(NULL AS int) AS RollingMedianNumRows
					,CAST(0 AS int) AS InvalidRecordReason
					,CAST(0 AS int) AS KeepSnapshotReason
					,Snap.LoadedIntoLTChangeHistory
					,Snap.LoadedIntoStatistics
					,Snap.LoadedIntoLastPtlRecord
		INTO		#SnapshotAnalysis
		FROM		SCR_Reporting_History.SCR_PTL_History Hist
		INNER JOIN	SCR_Reporting_History.SCR_PTL_SnapshotDates Snap
						ON	Hist.PtlSnapshotId = Snap.PtlSnapshotId
		GROUP BY	Hist.PtlSnapshotId
					,Snap.PtlSnapshotDate
					,Snap.LoadedIntoLTChangeHistory
					,Snap.LoadedIntoStatistics
					,Snap.LoadedIntoLastPtlRecord
		ORDER BY	Snap.PtlSnapshotDate

		-- Mark the last snapshot in each day
		UPDATE		Analysis
		SET			LastInDay	=	CASE WHEN	Analysis.PtlSnapshotDate =
												(SELECT MAX(Lst.PtlSnapshotDate)
												FROM	#SnapshotAnalysis Lst
												WHERE	Lst.PtlSnapshotDay = Analysis.PtlSnapshotDay)
										THEN	1
										ELSE	0 END
		FROM		#SnapshotAnalysis Analysis

		-- Calculate the LastInDayIx index numbers for only the last in day snapshots
		UPDATE		#SnapshotAnalysis
		SET			LastInDayIx = LastInDay.LastInDayIx
		FROM		#SnapshotAnalysis Analysis
		INNER JOIN	(SELECT		SnapshotIx
								,ROW_NUMBER() OVER (ORDER BY SnapshotIx) AS LastInDayIx
					FROM		#SnapshotAnalysis
					WHERE		LastInDay = 1) LastInDay
						ON	Analysis.SnapshotIx = LastInDay.SnapshotIx


		-- Calculate the change since the last snapshot (Excluding records that aren't the last snapshot)
		UPDATE		Curr
		SET			ChangeSinceLastSnapshot = Curr.NumRows - Prev.NumRows
					,DaysSinceLastSnapshot = DATEDIFF(DAY, Prev.PtlSnapshotDay, Curr.PtlSnapshotDay)
		FROM		#SnapshotAnalysis Curr
		LEFT JOIN	#SnapshotAnalysis Prev
						ON	Curr.LastInDayIx = Prev.LastInDayIx + 1


		-- Calculate the Average Daily change for the week
		SELECT		PtlSnapshotWeek
					,CAST(SUM(ChangeSinceLastSnapshot) AS real) / 
					CAST(SUM(DaysSinceLastSnapshot) AS real) AS AvgDailyChangeForWeek
		INTO		#WeeklyChanges
		FROM		#SnapshotAnalysis
		GROUP BY	PtlSnapshotWeek


		-- Calculate the Average and StDev change per week
		SELECT		@AvgWeeklyAdditions = AVG(AvgDailyChangeForWeek * 7)
					,@StDevWeeklyAdditions = STDEV(AvgDailyChangeForWeek * 7)
		FROM		#WeeklyChanges

		-- Update the rolling median number of rows (using median to avoid skewing caused by bad runs)
		UPDATE		Analysis
		SET			RollingMedianNumRows	=	(
													(SELECT MAX(NumRows)
													FROM	(SELECT TOP 50 PERCENT 
																		BottomRows.NumRows 
															FROM		#SnapshotAnalysis BottomRows
															WHERE		BottomRows.PtlSnapshotDate <= Analysis.PtlSnapshotDate
															AND			BottomRows.PtlSnapshotDate >= DATEADD(WEEK, -@RollingHistWeeks, Analysis.PtlSnapshotDate)
															AND			BottomRows.LastInDay = 1
															ORDER BY	NumRows) BottomHalf
													)
													+
													(SELECT MIN(NumRows) 
													FROM	(SELECT TOP 50 PERCENT 
																		TopRows.NumRows 
															FROM		#SnapshotAnalysis TopRows
															WHERE		TopRows.PtlSnapshotDate <= Analysis.PtlSnapshotDate
															AND			TopRows.PtlSnapshotDate >= DATEADD(WEEK, -@RollingHistWeeks, Analysis.PtlSnapshotDate)
															AND			TopRows.LastInDay = 1
															ORDER BY	NumRows DESC) TopHalf
													)
												) / 2
		FROM		#SnapshotAnalysis Analysis

		-- Look for row counts that have decreased more than 50 records per day since the last snapshot and mark them invalid
		UPDATE		Analysis
		SET			InvalidRecordReason = ISNULL(Analysis.InvalidRecordReason, 0) + 1
		FROM		#SnapshotAnalysis Analysis
		WHERE		Analysis.ChangeSinceLastSnapshot < (-50 * Analysis.DaysSinceLastSnapshot) -- allow for some deletions as this will be a normal part of DQ

		-- Look for row counts that seem to be out of process with the recent median PTL size and growth rate and mark them invalid
		UPDATE		Analysis
		SET			InvalidRecordReason = ISNULL(Analysis.InvalidRecordReason, 0) + 2
		FROM		#SnapshotAnalysis Analysis
		WHERE		Analysis.NumRows	>	Analysis.RollingMedianNumRows + 
										(@RollingHistWeeks / 2 * (@AvgWeeklyAdditions + (@StDevWeeklyAdditions*3)))

		-- Order the daily, weekly and monthly snapshots (as long as the record isn't invalid) within their respective time periods
		UPDATE		Analysis
		SET			SnapshotsInDailyIx		=	AnalysisIx.SnapshotsInDailyIx
					,SnapshotsInWeeklyIx	=	AnalysisIx.SnapshotsInWeeklyIx
					,SnapshotsInMonthlyIx	=	AnalysisIx.SnapshotsInMonthlyIx
		FROM		#SnapshotAnalysis Analysis
		INNER JOIN	(SELECT		SnapshotIx
								,SnapshotsInDailyIx		=	ROW_NUMBER() OVER (PARTITION BY AnalysisWindowed.PtlSnapshotDay ORDER BY AnalysisWindowed.PtlSnapshotDay, AnalysisWindowed.LastInDay DESC)
								,SnapshotsInWeeklyIx	=	ROW_NUMBER() OVER (PARTITION BY AnalysisWindowed.PtlSnapshotWeek ORDER BY AnalysisWindowed.PtlSnapshotDay, AnalysisWindowed.LastInDay DESC)
								,SnapshotsInMonthlyIx	=	ROW_NUMBER() OVER (PARTITION BY AnalysisWindowed.PtlSnapshotMonth ORDER BY AnalysisWindowed.PtlSnapshotDay, AnalysisWindowed.LastInDay DESC)
					FROM		#SnapshotAnalysis AnalysisWindowed
					WHERE		ISNULL(AnalysisWindowed.InvalidRecordReason, 0) = 0
					) AnalysisIx
						ON	Analysis.SnapshotIx = AnalysisIx.SnapshotIx

		-- Mark the records to keep (assigning values as a bitmap so that we can uniquely identify multiple concurrent reasons within a single int field)
		UPDATE		Analysis
		SET			KeepSnapshotReason	=	CASE WHEN PtlSnapshotDay >= DATEADD(DAY, DATEDIFF(DAY, 0, @Yesterday) - @DaysToKeepDaily, 0) AND SnapshotsInDailyIx = 1 THEN 1 ELSE 0 END +			-- 2^0 = 1
											CASE WHEN PtlSnapshotDay >= DATEADD(WEEK, DATEDIFF(WEEK, 0, @Yesterday) - @WeeksToKeepWeekly, 0) AND SnapshotsInWeeklyIx = 1 THEN 2 ELSE 0 END +	-- 2^1 = 2
											CASE WHEN PtlSnapshotDay >= DATEADD(MONTH, DATEDIFF(MONTH, 0, @Yesterday) - @MonthsToKeepMonthly, 0) AND SnapshotsInMonthlyIx = 1 THEN 4 ELSE 0 END	-- 2^2 = 4
		FROM		#SnapshotAnalysis Analysis

		-- Keep a record of when the archival analysis finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspTrimSCR_PTL_History', @Step = 'PTL History Snapshot Analysis'
				

		-- Keep a record of when the SCR_PTL_History trimming process started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspTrimSCR_PTL_History', @Step = 'Deleting unnecessary PTL History Snapshots'

		-- Create a temp table of the snapshots that need deleting
		SELECT		snap.PtlSnapshotId
					,ROW_NUMBER() OVER (ORDER BY snap.PtlSnapshotId ASC) AS SnapshotsToDeleteIx
		INTO		#SnapshotsToDelete
		FROM		#SnapshotAnalysis snap
		WHERE		snap.KeepSnapshotReason = 0
		AND			snap.LoadedIntoLTChangeHistory = 1
		AND			snap.LoadedIntoStatistics = 1
		AND			snap.LoadedIntoLastPtlRecord = 1
		
		-- Loop through each snapshot to delete and delete them one in turn
		WHILE @DeleteIteration <= (SELECT MAX(SnapshotsToDeleteIx) FROM #SnapshotsToDelete)
		BEGIN

			-- Find the next snapshot to be deleted
			SELECT		@DeletePtlSnapshotId = PtlSnapshotId
			FROM		#SnapshotsToDelete
			WHERE		SnapshotsToDeleteIx = @DeleteIteration
			
			-- Keep a record of when each snapshot deletion started
			SET @ProcessAuditHistoryStep = 'Deleting PTL History SnapshotID: ' + CAST(@DeletePtlSnapshotId AS varchar(255))
			EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspTrimSCR_PTL_History', @Step = @ProcessAuditHistoryStep
			
			-- Delete the snapshot
			DELETE
			FROM		Hist
			FROM		SCR_Reporting_History.SCR_PTL_History Hist
			WHERE		Hist.PtlSnapshotId = @DeletePtlSnapshotId
			
			-- Keep a record of when each snapshot deletion finished
			EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspTrimSCR_PTL_History', @Step = @ProcessAuditHistoryStep

			-- Move onto the next snapshot to be deleted
			SET @DeleteIteration = @DeleteIteration + 1

		END
				
		-- Keep a record of when the archival analysis finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspTrimSCR_PTL_History', @Step = 'Deleting unnecessary PTL History Snapshots'

GO
