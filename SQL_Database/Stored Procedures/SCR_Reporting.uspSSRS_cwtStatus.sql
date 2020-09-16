USE [CancerReporting]
GO
/****** Object:  StoredProcedure [SCR_Reporting].[uspSSRS_cwtStatus]    Script Date: 03/09/2020 23:43:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [SCR_Reporting].[uspSSRS_cwtStatus]
	(@cwtPathwayType varchar(255) = ''
	,@ReturnType int = 1 -- 1 = Available Values, 2 = Default Values
	,@cwtStandardId int
	)
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

Original Work Created Date:	01/10/2019
Original Work Created By:	Perspicacity Ltd (Matthew Bishop) & BSUH (Lawrence Simpson)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk / lawrencesimpson@nhs.net
Description:				Return the datasets for available and default cwtStatus Parameter 
							values (for use in reporting tools to filter results)
**************************************************************************************************************************************************/

-- EXEC SCR_Reporting.uspSSRS_cwtStatus @cwtPathwayType = '1', @ReturnType = 1, @cwtStandardId = 4 -- Test Me
-- EXEC SCR_Reporting.uspSSRS_cwtStatus @cwtPathwayType = '1', @ReturnType = 2, @cwtStandardId = 4 -- Test Me

SET NOCOUNT ON

		-- Declare procedure variables
		DECLARE @xml xml

/************************************************************************************************************************************************************************************************************
-- Convert the SSRS multi-value parameters into meaningful datasets for a SQL query
************************************************************************************************************************************************************************************************************/

		-- Convert the @cwtPathwayType parameter into an XML string
		SET @xml = CAST('<SubValue>' + REPLACE(@cwtPathwayType, ',', '</SubValue><SubValue>') + '</SubValue>' AS XML)

		-- Convert the @cwtPathwayType xml string into a cwt pathway type dataset
		SELECT N.value('.', 'int') AS cwtPathwayTypeId INTO #cwtPathwayType FROM @xml.nodes('SubValue') as T(N)


/************************************************************************************************************************************************************************************************************
-- Data Output
************************************************************************************************************************************************************************************************************/

		IF @ReturnType = 1 -- Available values
		BEGIN
			-- Return the cwt statuses relevant to the provided pathway types (this is to get around the issue of cascading parameters not resetting to default values when the PathwayType is changed)
			SELECT		CAST(cwts.cwtStatusId AS varchar(255)) + '¿' + (SELECT CAST(SUM(POWER(2, cwtPathwayTypeId)) AS varchar(255)) FROM #cwtPathwayType) AS cwtStatusId 
						,cwts.cwtStatus 
						,cwts.SortOrder 
			FROM		LocalConfig.ReportingCwtStatus  cwts
			INNER JOIN	#cwtPathwayType cwtp
							ON	cwts.CwtPathwayTypeId = cwtp.cwtPathwayTypeId
			WHERE		cwts.IsDeleted = 0
			AND			((@cwtStandardId = 1 AND cwts.applicable2WW = 1)
			OR			(@cwtStandardId = 2 AND cwts.applicable28 = 1)
			OR			(@cwtStandardId = 3 AND cwts.applicable31 = 1)
			OR			(@cwtStandardId = 4 AND cwts.applicable62 = 1))
			ORDER BY	cwts.SortOrder ASC
		END

		IF @ReturnType = 2 -- Default values
		BEGIN
			-- Return the default cwt statuses relevant to the provided pathway types
			SELECT		CAST(cwtStatusId AS varchar(255)) + '¿' + (SELECT CAST(SUM(POWER(2, cwtPathwayTypeId)) AS varchar(255)) FROM #cwtPathwayType) AS cwtStatusId 
						,cwts.cwtStatus 
						,cwts.SortOrder 
			FROM		LocalConfig.ReportingCwtStatus cwts
			INNER JOIN	#cwtPathwayType cwtp
							ON	cwts.CwtPathwayTypeId = cwtp.cwtPathwayTypeId
			WHERE		((
						(SELECT		SUM(CAST(cwtsi.DefaultShow2WW AS int) + CAST(cwtsi.DefaultShow28 AS int) + CAST(cwtsi.DefaultShow31 AS int) + CAST(cwtsi.DefaultShow62 AS int)) 
						FROM		LocalConfig.ReportingCwtStatus cwtsi
						INNER JOIN	#cwtPathwayType cwtp
										ON	cwtsi.CwtPathwayTypeId = cwtp.cwtPathwayTypeId
						WHERE		((@cwtStandardId = 1 AND cwtsi.applicable2WW = 1)
						OR			(@cwtStandardId = 2 AND cwtsi.applicable28 = 1)
						OR			(@cwtStandardId = 3 AND cwtsi.applicable31 = 1)
						OR			(@cwtStandardId = 4 AND cwtsi.applicable62 = 1))) > 0
						AND			((@cwtStandardId = 1 AND cwts.DefaultShow2WW = 1)
						OR			(@cwtStandardId = 2 AND cwts.DefaultShow28 = 1)
						OR			(@cwtStandardId = 3 AND cwts.DefaultShow31 = 1)
						OR			(@cwtStandardId = 4 AND cwts.DefaultShow62 = 1))
						)
			OR			(
						(SELECT		SUM(CAST(cwtsi.DefaultShow2WW AS int) + CAST(cwtsi.DefaultShow28 AS int) + CAST(cwtsi.DefaultShow31 AS int) + CAST(cwtsi.DefaultShow62 AS int))
						FROM		LocalConfig.ReportingCwtStatus cwtsi
						INNER JOIN	#cwtPathwayType cwtp
										ON	cwtsi.CwtPathwayTypeId = cwtp.cwtPathwayTypeId
						WHERE		((@cwtStandardId = 1 AND cwtsi.applicable2WW = 1)
						OR			(@cwtStandardId = 2 AND cwtsi.applicable28 = 1)
						OR			(@cwtStandardId = 3 AND cwtsi.applicable31 = 1)
						OR			(@cwtStandardId = 4 AND cwtsi.applicable62 = 1))) = 0
						))
			AND			((@cwtStandardId = 1 AND cwts.applicable2WW = 1)
			OR			(@cwtStandardId = 2 AND cwts.applicable28 = 1)
			OR			(@cwtStandardId = 3 AND cwts.applicable31 = 1)
			OR			(@cwtStandardId = 4 AND cwts.applicable62 = 1))
			AND cwts.IsDeleted = 0
		END
GO
