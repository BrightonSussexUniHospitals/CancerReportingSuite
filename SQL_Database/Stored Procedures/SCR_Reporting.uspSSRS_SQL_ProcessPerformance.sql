SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [SCR_Reporting].[uspSSRS_SQL_ProcessPerformance]

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

Original Work Created Date:	01/12/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				This procedure returns the datasets for reporting the SQL server process performance
**************************************************************************************************************************************************/

/*

EXEC SCR_Reporting.uspSSRS_SQL_ProcessPerformance
*/


/************************************************************************************************************************************************************************************************************
-- Ensure the procedure works in the ssrs environment
************************************************************************************************************************************************************************************************************/

		-- Don't return any rowcounts unless explicitly printed
		SET NOCOUNT ON
		
/************************************************************************************************************************************************************************************************************
-- Produce an analytical dataset for the process history data
************************************************************************************************************************************************************************************************************/

		-- Drop the #ProcessAuditHistory table if it exists
		IF OBJECT_ID('tempdb..#ProcessAuditHistory') IS NOT NULL
		DROP TABLE #ProcessAuditHistory

		-- Index the entries so we can calculate the gap between runs
		SELECT		ROW_NUMBER() OVER(ORDER BY ProcessAuditHistoryId ASC) AS Ix 
					,*
		INTO		#ProcessAuditHistory 
		FROM		CancerReporting.SCR_Warehouse.ProcessAuditHistory 
		WHERE		DATEADD(DAY, DATEDIFF(DAY, 0, LastStarted), 0) >=
					DATEADD(MONTH, -6, DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0))
		AND			LEN(Step) >= 12
		--ORDER BY	ProcessAuditHistoryId DESC

		-- Return an analytical dataset to demonstrate SQL server process performance
		SELECT		
					pah.*
					,DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) AS ProcessTime 
					,DATEDIFF(MINUTE, ISNULL(pah_prev.LastStarted, pah_prev.LastSuccessfullyCompleted), pah.LastStarted) AS TimeSinceLastRun
					,CASE WHEN pah.LastStarted IS NOT NULL AND pah.LastSuccessfullyCompleted IS NULL AND pah_next.Ix IS NOT NULL THEN 'Failed' ELSE '' END AS Failed
					,CASE WHEN RIGHT(pah.step, 8) != RIGHT(pah_next.step, 8) THEN 'Switched node' ELSE '' END AS NodeSwitch
					,RIGHT(pah.step, 8) AS ActiveNode
					,LEFT(pah.step, LEN(pah.Step) - 12) AS NodelessStep
					,DATEADD(DAY, DATEDIFF(DAY, 0, pah.LastStarted), 0) AS DateLastStarted
					,CASE	WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <= 2
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Update the Next Actions'
							THEN	'Excellent (<=2s)'
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <= 4
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Update the Next Actions'
							THEN	'Good (2-4s)'
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <=6 
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Update the Next Actions'
							THEN	'Sub-optimal (4-6s)'
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <=10 
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Update the Next Actions'
							THEN	'Poor (6-10s)'
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) >10 
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Update the Next Actions'
							THEN	'Significant Issue (10s+)'
							END AS NextActionProcessTimeDesc
					,CASE	WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <= 2
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Update the Next Actions'
							THEN	1
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <= 4
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Update the Next Actions'
							THEN	2
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <=6 
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Update the Next Actions'
							THEN	3
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <=10
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Update the Next Actions'
							THEN	4
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) >10 
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Update the Next Actions'
							THEN	5
							END AS NextActionProcessTimeIx
					,CASE	WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <= 10
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Incremental snapshot'
							THEN	'Excellent (<=10s)'
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <= 15
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Incremental snapshot'
							THEN	'Good (10-15s)'
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <=20 
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Incremental snapshot'
							THEN	'Sub-optimal (15-20s)'
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <=30 
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Incremental snapshot'
							THEN	'Poor (20-30s)'
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) >30 
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Incremental snapshot'
							THEN	'Significant Issue (30s+)'
							END AS IncrementalProcessTimeDesc
					,CASE	WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <= 10
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Incremental snapshot'
							THEN	1
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <= 15
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Incremental snapshot'
							THEN	2
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <=20 
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Incremental snapshot'
							THEN	3
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) <=30
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Incremental snapshot'
							THEN	4
							WHEN	DATEDIFF(SECOND, pah.LastStarted, pah.LastSuccessfullyCompleted) >30
							AND		LEFT(pah.step, LEN(pah.Step) - 12) = 'Incremental snapshot'
							THEN	5
							END AS IncrementalProcessTimeIx

		FROM		#ProcessAuditHistory pah
		LEFT JOIN	#ProcessAuditHistory pah_prev
						ON	pah.Ix = pah_prev.Ix + 1
		LEFT JOIN	#ProcessAuditHistory pah_next
						ON	pah.Ix = pah_next.Ix - 1
		WHERE		1=1
		--AND			pah.Step LIKE '05:00 daily snapshot and PtlHistory%'
		ORDER BY	ProcessAuditHistoryId DESC

GO
