USE [CancerReporting]
GO
/****** Object:  StoredProcedure [SCR_Reporting].[uspSSRS_NextActions_History]    Script Date: 03/09/2020 23:43:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [SCR_Reporting].[uspSSRS_NextActions_History]
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
EXEC SCR_Reporting.uspSSRS_NextActions_History @CareId=490966, @Anonymised=0 -- test me
EXEC SCR_Reporting.uspSSRS_NextActions_History @CareId=490966, @Anonymised=1 -- test me
*/

/************************************************************************************************************************************************************************************************************
-- Return the data
************************************************************************************************************************************************************************************************************/

		-- Don't return any rowcounts unless explicitly printed
		SET NOCOUNT ON
		
		-- Return the data
		SELECT		nah.CareID
					,nah.PathwayUpdateEventID
					,NextActionDesc_Current			=	ISNULL(na.NextActionDesc, 'Deleted')
					,NextActionSpecificDesc_Current	=	na.NextActionSpecificDesc
					,AdditionalDetails_Current		=	CASE	WHEN	@Anonymised = 0
																THEN	na.AdditionalDetails
																ELSE	'Redacted for display purposes'
																END
					,OwnerDesc_Current				=	na.OwnerDesc
					,OwnerRole_Current				=	na.OwnerRole
					,OwnerName_Current				=	na.OwnerName
					,TargetDate_Current				=	na.TargetDate
					,Escalated_Current				=	CASE WHEN na.Escalate = 2 THEN 'No' WHEN na.Escalate = 1 THEN 'Yes' END
					,OrganisationDesc_Current		=	na.OrganisationDesc
					,ActionComplete_Current			=	CASE WHEN na.ActionComplete = 0 THEN 'No' WHEN na.ActionComplete = 1 THEN 'Yes' END
					,LastUpdated_Current			=	na.LastUpdated
					,LastUpdatedBy_Current			=	CASE	WHEN	@Anonymised = 0
																THEN	LEFT(na.LastUpdatedBy, CHARINDEX('{', na.LastUpdatedBy) - 2)
																ELSE	CHAR(ASCII(LEFT(na.LastUpdatedBy, 1))+1) + 
																		REPLICATE('*',LEN(LEFT(na.LastUpdatedBy, CHARINDEX('{', na.LastUpdatedBy) - 2))-2) + 
																		CHAR(ASCII(RIGHT(LEFT(na.LastUpdatedBy, CHARINDEX('{', na.LastUpdatedBy) - 2), 1))-1)
																END
					,UpdateRevIx_Current			=	nah.UpdateRevIx
					,NextActionDesc_Audit			=	nah_aud.NextActionDesc
					,NextActionSpecificDesc_Audit	=	nah_aud.NextActionSpecificDesc
					,AdditionalDetails_Audit		=	CASE	WHEN	@Anonymised = 0
																THEN	nah_aud.AdditionalDetails
																ELSE	'Redacted for display purposes'
																END
					,OwnerDesc_Audit				=	nah_aud.OwnerDesc
					,OwnerRole_Audit				=	nah_aud.OwnerRole
					,OwnerName_Audit				=	nah_aud.OwnerName
					,TargetDate_Audit				=	nah_aud.TargetDate
					,Escalated_Audit				=	CASE WHEN nah_aud.Escalate = 2 THEN 'No' WHEN nah_aud.Escalate = 1 THEN 'Yes' END
					,OrganisationDesc_Audit			=	nah_aud.OrganisationDesc
					,ActionComplete_Audit			=	CASE WHEN nah_aud.ActionComplete = 0 THEN 'No' WHEN nah_aud.ActionComplete = 1 THEN 'Yes' END
					,LastUpdated_Audit				=	nah_aud.LastUpdated
					,LastUpdatedBy_Audit			=	CASE	WHEN	@Anonymised = 0
																THEN	LEFT(nah_aud.LastUpdatedBy, CHARINDEX('{', nah_aud.LastUpdatedBy) - 2)
																ELSE	CHAR(ASCII(LEFT(nah_aud.LastUpdatedBy, 1))+1) + 
																		REPLICATE('*',LEN(LEFT(nah_aud.LastUpdatedBy, CHARINDEX('{', nah_aud.LastUpdatedBy) - 2))-2) + 
																		CHAR(ASCII(RIGHT(LEFT(nah_aud.LastUpdatedBy, CHARINDEX('{', nah_aud.LastUpdatedBy) - 2), 1))-1)
																END
					,UpdateRevIx_Audit				=	nah_aud.UpdateRevIx
		FROM		SCR_Reporting_History.SCR_NextActions_History nah
		LEFT JOIN	SCR_Warehouse.SCR_NextActions na
						ON	nah.PathwayUpdateEventID = na.PathwayUpdateEventID
		LEFT JOIN	SCR_Reporting_History.SCR_NextActions_History nah_aud
						ON	nah.PathwayUpdateEventID = nah_aud.PathwayUpdateEventID
						AND	(nah_aud.UpdateRevIx > 1
						OR	na.CareID IS NULL)
		WHERE		nah.UpdateIx = 1
		AND			nah.CareId = @CareId
		ORDER BY	na.LastUpdated DESC
					,nah_aud.UpdateRevIx
GO
