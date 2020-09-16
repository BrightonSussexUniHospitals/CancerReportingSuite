USE [CancerReporting]
GO
/****** Object:  StoredProcedure [SCR_Reporting].[uspSSRS_PatientDetails]    Script Date: 03/09/2020 23:43:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [SCR_Reporting].[uspSSRS_PatientDetails]
	(@CareId int = 0
	,@Anonymised int = 0
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

Original Work Created Date:	28/04/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop) & BSUH (Lawrence Simpson)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk / lawrencesimpson@nhs.net
Description:				This procedure returns the datasets for reporting the PTL in a reporting tool
**************************************************************************************************************************************************/

/*
EXEC SCR_Reporting.uspSSRS_PatientDetails @CareId=1000, @Anonymised=0 -- test me
*/

/************************************************************************************************************************************************************************************************************
-- Return the data
************************************************************************************************************************************************************************************************************/

		-- Don't return any rowcounts unless explicitly printed
		SET NOCOUNT ON
		
		-- Return the data
		SELECT		CASE	WHEN	@Anonymised = 0
							THEN	Ref.Forename
							ELSE	CHAR(ASCII(LEFT(Ref.Forename, 1))+1) + 
									REPLICATE('*',LEN(Ref.Forename)-2) + 
									CHAR(ASCII(RIGHT(Ref.Forename, 1))-1)
							END AS Forename
					,CASE	WHEN	@Anonymised = 0
							THEN	Ref.Surname
							ELSE	CHAR(ASCII(LEFT(Ref.Surname, 1))+1) + 
									REPLICATE('*',LEN(Ref.Surname)-2) + 
									CHAR(ASCII(RIGHT(Ref.Surname, 1))-1)
							END AS Surname
					,CASE	WHEN	@Anonymised = 0
							THEN	Ref.HospitalNumber
							ELSE	CHAR(ASCII(LEFT(Ref.HospitalNumber, 1))+1) + 
									REPLICATE('*',LEN(Ref.HospitalNumber)-2) + 
									CHAR(ASCII(RIGHT(Ref.HospitalNumber, 1)))
							END AS HospitalNumber
					,CancerSiteBS
		FROM		SCR_Warehouse.SCR_Referrals Ref
		WHERE		CARE_ID = @CareId
GO
