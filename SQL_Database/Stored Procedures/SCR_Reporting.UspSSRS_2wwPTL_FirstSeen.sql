USE [CancerReporting]
GO
/****** Object:  StoredProcedure [SCR_Reporting].[UspSSRS_2wwPTL_FirstSeen]    Script Date: 03/09/2020 23:43:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [SCR_Reporting].[UspSSRS_2wwPTL_FirstSeen]
	
AS


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
Description:				this  provides the First Seen Date as MM YY dataset for cancer_SSRS_Usp_2wwPTL_Summary
							last updated 11/08/2020
**************************************************************************************************************************************************/


SELECT		DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) AS 'FirstSeenMMYY'
			,FORMAT(REF.DateFirstSeen, 'MMM yyyy') AS 'SeenMMMYY'

FROM		SCR_Warehouse.SCR_Referrals REF
INNER JOIN	SCR_Warehouse.SCR_CWT CWT 
				ON REF.CARE_ID = CWT.CARE_ID
WHERE		cwtFlag2WW IN (0,1,2)
			AND CWTStatusCode2WW IN (14,15,44)
			AND DateReceipt>='2016-01-01'
			AND REF.DateFirstSeen IS NOT NULL

		
			--
GROUP BY	DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) 
			,FORMAT(REF.DateFirstSeen, 'MMM yyyy')

ORDER BY DATEADD(MONTH, DATEDIFF(MONTH, 0, REF.DateFirstSeen), 0) desc
		



GO
