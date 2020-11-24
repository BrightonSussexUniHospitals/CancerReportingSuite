SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [SCR_Reporting].[uspSSRS_IPTsAndComments]
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
EXEC SCR_Reporting.uspSSRS_IPTsAndComments @CareId=490966, @Anonymised=0 -- test me
EXEC SCR_Reporting.uspSSRS_IPTsAndComments @CareId=490966, @Anonymised=1 -- test me
*/

/************************************************************************************************************************************************************************************************************
-- Return the data
************************************************************************************************************************************************************************************************************/

		-- Don't return any rowcounts unless explicitly printed
		SET NOCOUNT ON
		
		-- Return the data
		SELECT		*
		FROM		(
					SELECT		TransferOrCommentDateText	=	CONVERT(varchar(255), com.CommentDate, 103)
								,TransferOrCommentDate		=	com.CommentDate
								,TransferOrCommentText		=	CASE	WHEN	@Anonymised = 0
																		THEN	CAST(com.Comment AS varchar(max))
																		ELSE	'Redacted for display purposes'
																		END
								,[User]						=	CASE	WHEN	@Anonymised = 0
																		THEN	substring(com.CommentUser,1,charindex(' {',com.CommentUser)-1)
																		ELSE	CHAR(ASCII(LEFT(com.CommentUser, 1))+1) + 
																				REPLICATE('*',charindex(' {',com.CommentUser)-3) + 
																				CHAR(ASCII(substring(com.CommentUser,charindex(' {',com.CommentUser)-1,1))-1)
																END
								,[UserId]					=	CASE	WHEN	@Anonymised = 0
																		THEN	substring(com.CommentUser,charindex(' {',com.CommentUser) + 3, len(com.CommentUser) - charindex(' {',com.CommentUser) - 4)
																		ELSE	CHAR(ASCII(substring(com.CommentUser,charindex(' {',com.CommentUser) + 3,1))+1) + 
																				REPLICATE('*',len(com.CommentUser) - charindex(' {',com.CommentUser) - 6) + 
																				CHAR(ASCII(substring(com.CommentUser,LEN(com.CommentUser)-2,1))-1)
																END
																
								,IsIPT						=	CAST(0 AS bit)
								,IPTTypeCode				=	CAST(0 AS INT)
					FROM		SCR_Warehouse.SCR_Comments com
					WHERE		com.CARE_ID = @CareId
					AND			com.CommentType = 1 -- Tracking Notes Only

					UNION
 
					SELECT		TransferOrCommentDateText	=	CONVERT(varchar(255), ipt.IPTDate, 103)
								,TransferOrCommentDate		=	ipt.IPTDate
								,TransferOrCommentText		=	CASE	WHEN	@Anonymised = 0
																		THEN	'***Inter Provider Transfer*** '+ [IPTTypeDesc] + ' '+
																				ISNULL(
																						'(' + CAST(DATEDIFF(DAY, CWT.ClockStartDate62, ipt.IPTDate) - ISNULL(CWT.AdjTime2WW, 0) AS varchar(255)) + ' day' + 
																						CASE WHEN DATEDIFF(DAY, CWT.ClockStartDate62, ipt.IPTDate) - ISNULL(CWT.AdjTime2WW, 0) = 1 THEN '' ELSE 's' END + ' into pathway)'
																						, '') + 
																				CASE	WHEN [IPTTypeCode] = 1 THEN (' for '+ isnull([IPTReferralReasonDesc],'?')+' From: '+isnull([ReferringOrgName],'?')+CHAR(13)+ isnull(' Comments:' +	[TertiaryReferralInComments],''))										
																						WHEN [IPTTypeCode] = 2 THEN (' for '+ isnull([IPTReferralReasonDesc],'?')+' To: '+isnull([ReceivingOrgName],'?')+CHAR(13) +isnull(' Comments:' +	[TertiaryReferralOutComments],''))
																						ELSE ''
																				END
																		ELSE	'***Inter Provider Transfer*** Redacted for display purposes'
																		END
								,[User]						=	CASE	WHEN	@Anonymised = 0
																		THEN	substring(ipt.LastUpdatedBy,1,charindex(' {',ipt.LastUpdatedBy)-1)
																		ELSE	CHAR(ASCII(LEFT(ipt.LastUpdatedBy, 1))+1) + 
																				REPLICATE('*',charindex(' {',ipt.LastUpdatedBy)-3) + 
																				CHAR(ASCII(substring(ipt.LastUpdatedBy,charindex(' {',ipt.LastUpdatedBy)-1,1))-1)
																END
								,[UserId]					=	CASE	WHEN	@Anonymised = 0
																		THEN	substring(ipt.LastUpdatedBy,charindex(' {',ipt.LastUpdatedBy) + 3, len(ipt.LastUpdatedBy) - charindex(' {',ipt.LastUpdatedBy) - 4)
																		ELSE	CHAR(ASCII(substring(ipt.LastUpdatedBy,charindex(' {',ipt.LastUpdatedBy) + 3,1))+1) + 
																				REPLICATE('*',len(ipt.LastUpdatedBy) - charindex(' {',ipt.LastUpdatedBy) - 6) + 
																				CHAR(ASCII(substring(ipt.LastUpdatedBy,LEN(ipt.LastUpdatedBy)-2,1))-1)
																END
								,IsIPT						=	CAST(1 AS bit)
								,IPTTypeCode				=	ISNULL(IPT.IPTTypeCode,-1)
					FROM		SCR_Warehouse.SCR_InterProviderTransfers ipt
					LEFT JOIN	SCR_Warehouse.SCR_CWT CWT
									ON	ipt.CareID = CWT.CARE_ID
									AND	CWT.DeftDefinitiveTreatment = 1
					WHERE		ipt.CareID = @CareId
					) A

		ORDER BY	A.TransferOrCommentDate  
GO
