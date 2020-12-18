SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [SCR_Reporting].[UspSSRS_2wwPTLSummary]
		(@CancerSiteBS varchar(50) 
		,@SeenMMYY datetime 
		)
AS


--EXEC SCR_Reporting.UspSSRS_2wwPTLSummary @CancerSiteBS = 'All' , @SeenMMYY = '01/08/2020'

/******************************************************** © Copyright & Licensing ****************************************************************
© 2019 Perspicacity Ltd & Brighton & Sussex University Hospitals

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

Original Work Created Date:	11/08/2020
Original Work Created By:	BSUH (Lawrence Simpson)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk / lawrencesimpson@nhs.net
Description:				this view provides the dataset for cancer_SSRS_2wwPTL_Summary
							last updated 11/08/2020
**************************************************************************************************************************************************/


SELECT		CancerSiteBS
			,DATEADD(DAY, DATEDIFF(DAY, 0, REF.ReportDate), 0) AS ReportDate
			,FORMAT(REF.DateReceipt, 'MMM') AS 'RefMonth'
			,YEAR(REF.DateReceipt) AS 'RefYear'
			,DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateReceipt), 0) AS 'RefMMYY'
			,FORMAT(REF.DateFirstSeen, 'MMM') AS 'FirstSeenMonth'
			,YEAR(REF.DateFirstSeen) AS 'FirstSeenYear'
			,DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) AS 'FirstSeenMMYY'
			,cwtFlag2WW
			,CWTStatusCode2WW
			,ISNULL(WillBeWaitingtime2WW, WaitingTime2WW) as DaysOnPathway
			,CASE	WHEN CWTStatusCode2WW = 44 
							AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
							AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
							THEN ISNULL(WillBeWaitingtime2WW, WaitingTime2WW) 
							END								as SeenDaysOnPathway

			--Pending2ww			
			,SUM(CASE WHEN ISNULL(WillBeWaitingtime2WW, WaitingTime2WW) BETWEEN 0 AND 7 AND CWTStatusCode2WW = 14	THEN 1 ELSE 0 END) AS [Pending2ww_0TO7]   
			,SUM(CASE WHEN ISNULL(WillBeWaitingtime2WW, WaitingTime2WW) BETWEEN 8 AND 14 AND CWTStatusCode2WW = 14	THEN 1 ELSE 0 END) AS [Pending2ww_8TO14]	
			,SUM(CASE WHEN ISNULL(WillBeWaitingtime2WW, WaitingTime2WW) >14  AND CWTStatusCode2WW = 14	THEN 1 ELSE 0 END) AS [Pending2ww_15Plus]
			,SUM(CASE WHEN ISNULL(WillBeWaitingtime2WW, WaitingTime2WW) <0  AND CWTStatusCode2WW = 14	THEN 1 ELSE 0 END) AS [Pending2ww_lessthan0]    --DQ check
			,SUM(CASE WHEN ISNULL(WillBeWaitingtime2WW, WaitingTime2WW)  IS NULL  AND CWTStatusCode2WW = 14	THEN 1 ELSE 0 END) AS [Pending2ww_null]		--DQ check					   							  
			,SUM(CASE WHEN CWTStatusCode2WW = 14 THEN 1 ELSE 0 END) AS [Pending2ww]                                                                           
			,SUM(CASE WHEN CWTStatusCode2WW = 14 AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') THEN 1 ELSE 0 END) AS [Pending2ww_CancerSiteBS]
			 
			--Undated2ww
			,SUM(CASE WHEN Waitingtime2WW = 0 AND CWTStatusCode2WW = 15	THEN 1 ELSE 0 END) AS [Undated2ww_0] 
			,SUM(CASE WHEN Waitingtime2WW = 1 AND CWTStatusCode2WW = 15	THEN 1 ELSE 0 END) AS [Undated2ww_1] 
			,SUM(CASE WHEN Waitingtime2WW = 2 AND CWTStatusCode2WW = 15	THEN 1 ELSE 0 END) AS [Undated2ww_2] 
			,SUM(CASE WHEN Waitingtime2WW = 3 AND CWTStatusCode2WW = 15	THEN 1 ELSE 0 END) AS [Undated2ww_3] 
			,SUM(CASE WHEN Waitingtime2WW = 4 AND CWTStatusCode2WW = 15	THEN 1 ELSE 0 END) AS [Undated2ww_4] 
			,SUM(CASE WHEN Waitingtime2WW = 5 AND CWTStatusCode2WW = 15	THEN 1 ELSE 0 END) AS [Undated2ww_5] 
			,SUM(CASE WHEN Waitingtime2WW = 6 AND CWTStatusCode2WW = 15	THEN 1 ELSE 0 END) AS [Undated2ww_6] 
			,SUM(CASE WHEN Waitingtime2WW = 7 AND CWTStatusCode2WW = 15	THEN 1 ELSE 0 END) AS [Undated2ww_7] 
			,SUM(CASE WHEN Waitingtime2WW = 8 AND CWTStatusCode2WW = 15	THEN 1 ELSE 0 END) AS [Undated2ww_8] 
			,SUM(CASE WHEN Waitingtime2WW = 9 AND CWTStatusCode2WW = 15	THEN 1 ELSE 0 END) AS [Undated2ww_9] 
			,SUM(CASE WHEN Waitingtime2WW = 10 AND CWTStatusCode2WW = 15 THEN 1 ELSE 0 END) AS [Undated2ww_10] 
			,SUM(CASE WHEN Waitingtime2WW = 11 AND CWTStatusCode2WW = 15 THEN 1 ELSE 0 END) AS [Undated2ww_11] 
			,SUM(CASE WHEN Waitingtime2WW = 12 AND CWTStatusCode2WW = 15 THEN 1 ELSE 0 END) AS [Undated2ww_12] 
			,SUM(CASE WHEN Waitingtime2WW = 13 AND CWTStatusCode2WW = 15 THEN 1 ELSE 0 END) AS [Undated2ww_13] 
			,SUM(CASE WHEN Waitingtime2WW = 14 AND CWTStatusCode2WW = 15 THEN 1 ELSE 0 END) AS [Undated2ww_14] 
			,SUM(CASE WHEN Waitingtime2WW >= 15  AND CWTStatusCode2WW = 15 THEN 1 ELSE 0 END) AS [Undated2ww_15+] 
			,SUM(CASE WHEN CWTStatusCode2WW = 15 THEN 1 ELSE 0 END) AS [Undated2ww]
			,SUM(CASE WHEN CWTStatusCode2WW = 15 AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') THEN 1 ELSE 0 END) AS [undated2ww_CancerSiteBS]

			 --all seen OR pending (for the top right performance chart, which is filtered by cancer site only)                                                    
			,SUM(CASE	WHEN Waitingtime2WW BETWEEN 0 AND 7 
						AND CWTStatusCode2WW = 44  
						AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
						THEN 1 
						WHEN WillBeWaitingtime2WW BETWEEN 0 AND 7 
						AND CWTStatusCode2WW = 14  
						AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
						THEN 1
						ELSE 0 
						END) AS [Seen2ww_0TO7_CancerSiteBS] 
			,SUM(CASE	WHEN Waitingtime2WW BETWEEN 8 AND 14 
						AND CWTStatusCode2WW = 44 
						AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
						THEN 1 
						WHEN WillBeWaitingtime2WW BETWEEN 8 AND 14 
						AND CWTStatusCode2WW = 14  
						AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
						THEN 1
						ELSE 0 
						END) AS [Seen2ww_8TO14_CancerSiteBS]
			,SUM(CASE	WHEN Waitingtime2WW >= 15 
						AND CWTStatusCode2WW = 44
						AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
						THEN 1 
						WHEN WillBeWaitingtime2WW >=15
						AND CWTStatusCode2WW = 14  
						AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
						THEN 1
						ELSE 0 
						END) AS [Seen2ww_15Plus_CancerSiteBS] 
			
			-- all seen OR pending (for the top left performance chart, which is filtered by cancer site and month first seen)
			,SUM(CASE	WHEN Waitingtime2WW BETWEEN 0 AND 7 
						AND CWTStatusCode2WW = 44
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
						THEN 1 
						WHEN WillBeWaitingtime2WW BETWEEN 0 AND 7 
						AND CWTStatusCode2WW = 14
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
						THEN 1 
						ELSE 0 
						END) AS [Seen2ww_0TO7_CancerSiteBS_MMYY] 
			,SUM(CASE	WHEN Waitingtime2WW BETWEEN 8 AND 14 
						AND CWTStatusCode2WW = 44 
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
						THEN 1 
						WHEN WillBeWaitingtime2WW BETWEEN 8 AND 14 
						AND CWTStatusCode2WW = 14
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
						THEN 1 
						ELSE 0 
						END) AS [Seen2ww_8TO14_CancerSiteBS_MMYY]
			,SUM(CASE	WHEN Waitingtime2WW >= 15 
						AND CWTStatusCode2WW = 44
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
						THEN 1 
						WHEN WillBeWaitingtime2WW >= 15 
						AND CWTStatusCode2WW = 14
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
						THEN 1 
						ELSE 0 
						END) AS [Seen2ww_15Plus_CancerSiteBS_MMYY]                   
			
			-- all seen OR pending (for the performance table, which is filtered by month first seen)                                
			,SUM(CASE	WHEN Waitingtime2WW BETWEEN 0 AND 7 
						AND CWTStatusCode2WW = 44
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						THEN 1 
						WHEN WillBeWaitingtime2WW BETWEEN 0 AND 7 
						AND CWTStatusCode2WW = 14
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						THEN 1 
						ELSE 0 
						END) AS [Seen2ww_0TO7_MMYY] 
			,SUM(CASE	WHEN Waitingtime2WW BETWEEN 8 AND 14 
						AND CWTStatusCode2WW = 44
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						THEN 1 
						WHEN WillBeWaitingtime2WW BETWEEN 8 AND 14 
						AND CWTStatusCode2WW = 14
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						THEN 1 
						ELSE 0 
						END) AS [Seen2ww_8TO14_MMYY]
			,SUM(CASE	WHEN Waitingtime2WW >= 15 
						AND CWTStatusCode2WW = 44
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						THEN 1 
						WHEN WillBeWaitingtime2WW >= 15 
						AND CWTStatusCode2WW = 14
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						THEN 1 
						ELSE 0 
						END) AS [Seen2ww_15Plus_MMYY]
			,SUM(CASE	WHEN Waitingtime2WW BETWEEN 0 AND 14 
						AND CWTStatusCode2WW = 44
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						THEN 1 
						WHEN WillBeWaitingtime2WW BETWEEN 0 AND 14 
						AND CWTStatusCode2WW = 14
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						THEN 1 
						ELSE 0 
						END) AS [Seen2ww_InTarget_MMYY] 
			,SUM(CASE	WHEN CWTStatusCode2WW IN (14,44)
						AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
						THEN 1
						ELSE 0 
						END) AS [Seen2ww_TotalSeen_MMYY] 
			
			--all referrals
			--,count(*) AS AllReferrals
			,SUM(CASE WHEN (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') THEN 1 ELSE 0 END) AS AllReferrals_CancerSiteBS

FROM		SCR_Warehouse.SCR_Referrals REF
INNER JOIN	SCR_Warehouse.SCR_CWT CWT 
				ON REF.CARE_ID = CWT.CARE_ID
WHERE		cwtFlag2WW IN (0,1,2)
			AND CWTStatusCode2WW IN (14,15,44)
			AND DateReceipt >= '2016-01-01'
			--AND CancerSiteBS IN (@p_CancerSite) --exclude if running in SQL
			--
GROUP BY	CancerSiteBS
			,DATEADD(DAY, DATEDIFF(DAY, 0, ref.ReportDate), 0)
			,FORMAT(REF.DateReceipt, 'MMM')
			,YEAR(REF.DateReceipt)
			,DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateReceipt), 0)		
			,FORMAT(REF.DateFirstSeen, 'MMM') 
			,YEAR(REF.DateFirstSeen)
			,DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0)
			--,FORMAT(REF.DateFirstSeen, 'MMM yy')
			,cwtFlag2WW
			,CWTStatusCode2WW
			,ISNULL(WillBeWaitingtime2WW, WaitingTime2WW) 
			,CASE	WHEN CWTStatusCode2WW = 44 
							AND DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) = @SeenMMYY
							AND (CancerSiteBS = @CancerSiteBS OR @CancerSiteBS = 'All') 
							THEN ISNULL(WillBeWaitingtime2WW, WaitingTime2WW) 
							END	




GO
