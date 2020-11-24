SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [CancerTransactions].[tvfEstimatedBreachMonths]()
RETURNS TABLE 
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

Original Work Created Date:	04/11/2019
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				This tvf returns the valid range of dates for the Estimated Breach Date
							javascript popup in the SSRS PTL, along with the HTML formatted code
							required for the popup to present a drop down list of estimated breach
							months
**************************************************************************************************************************************************/


RETURN 
(
		WITH CTE AS
		(
			SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) -2, 0) AS cte_start_date
			UNION ALL
			SELECT DATEADD(MONTH, 1, cte_start_date)
			FROM CTE
			WHERE DATEADD(MONTH, 1, cte_start_date) <= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) +8, 0)   
		)
		SELECT	cte_start_date
				,FORMAT(cte_start_date, 'MMM-yyyy') AS MonthText
				,REPLACE(FORMAT(cte_start_date, '01-MM-yyyy'),'-','%2F') AS MonthValue
		FROM	CTE
)



GO
