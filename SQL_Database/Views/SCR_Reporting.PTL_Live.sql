USE [CancerReporting]
GO
/****** Object:  View [SCR_Reporting].[PTL_Live]    Script Date: 03/09/2020 23:46:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [SCR_Reporting].[PTL_Live]
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

Original Work Created Date:	01/01/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop) & BSUH (Lawrence Simpson)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk / lawrencesimpson@nhs.net
Description:				This view combines the various warehouse datasets to present a single
							view of the records in SCR, prepared for presentation in all the 
							reporting PTL versions
**************************************************************************************************************************************************/


SELECT	REF.CARE_ID
		,CWT.CWT_ID
		,CWT.Pathway
		,REF.CancerSiteBS
		,REF.Forename
		,REF.Surname
		,REF.HospitalNumber
		,REF.NHSNumber		
		,CWT.Waitingtime2WW
		,CWT.Waitingtime28
		,CWT.Waitingtime31
		,CWT.Waitingtime62
		,CWT.ReportingPathwayLength
		,REF.OrgCodeFirstSeen
		,REF.OrgDescFirstSeen
		,comm.Comment AS TrackingNotes	
		,REF.DateLastTracked
		,ISNULL(comm.CommentUser, 'Not yet tracked') AS CommentUser
		,REF.DaysSinceLastTracked
		,CWT.Weighting		
		,CWT.DominantCWTStatusCode
		,CWT.CWTStatusCode2WW
		,CWT.CWTStatusCode28
		,CWT.CWTStatusCode31
		,CWT.CWTStatusCode62
		,CWT.DominantCWTStatusDesc
		,CWT.CWTStatusDesc2WW	
		,CWT.CWTStatusDesc28
		,CWT.CWTStatusDesc31
		,CWT.CWTStatusDesc62
		,OTD.DaysToBreach AS DaysToNextBreach
		,ISNULL(OTD.TargetType, 'No open CWT waits') AS NextBreachTarget
		,OTD.BreachDate AS NextBreachDate
		,CWT.DominantColourValue
		,CWT.ColourValue2WW
		,CWT.ColourValue28Day
		,CWT.ColourValue31Day
		,CWT.ColourValue62Day
		,CWT.DominantColourDesc
		,CWT.ColourDesc2WW
		,CWT.ColourDesc28Day
		,CWT.ColourDesc31Day
		,CWT.ColourDesc62Day
		,CWT.DominantPriority
		,CWT.Priority2WW
		,CWT.Priority28
		,CWT.Priority31
		,CWT.Priority62
		,CWT.cwtFlag2WW
		,CWT.cwtFlag28
		,CWT.cwtFlag31
		,CWT.cwtFlag62
		,sna.PathwayUpdateEventID
		,sna.NextActionDesc
		,sna.NextActionSpecificDesc
		,sna.TargetDate AS NextActionTargetDate
		,DATEDIFF(DAY, CWT.ReportDate, sna.TargetDate) AS DaysToNextAction
		,sna.OwnerDesc
		,sna.AdditionalDetails
		,sna.Escalate AS Escalated
		,Ref.ReportDate
		,GETDATE() AS PtlSnapshotDate
		,sna.NextActionColourValue
		,eb.EstimatedBreachDate AS EstimatedBreachMonth
		,eb.EstimatedWeight
		,ISNULL(ebm.MonthValue, '-') AS EBMonthValue		
		, CASE WHEN CWT.cwtFlag2WW IN (1)       -- should be (0,1,2) so we can report all 2WW referrals from a "single version of the truth" but the query takes a little too long to run so will need optimisation first
		            OR	CWT.cwtFlag62 IN (1,2) 
					THEN 1 ELSE 0
					END			AS SSRS_PTLFlag62
		,sna.NextActionId
		,sna.NextActionSpecificId
		,sna.OwnerId
		-- Fields for UNIFY submission
		,CWT.cwtType62                        -- to identify type of 62day pt
		,CWT.DaysTo62DayBreach + 1 as DaysTo62DayBreach
		,CWT.DeftDateDecisionTreat
		,CAST(CASE WHEN CWT.DeftDateDecisionTreat IS NOT NULL	
					THEN 1 ELSE 0
					END AS Bit) AS SSRS_DTTFlag		
		,CWT.WillBeWaitingtime2WW
		,CWT.WillBeWaitingtime28
		,CWT.WillBeWaitingtime31
		,CWT.WillBeWaitingtime62
		,ISNULL(cwtType62, cwtType2WW) AS ReportingcwtTypeID


FROM		SCR_Warehouse.SCR_Referrals REF
INNER JOIN	SCR_Warehouse.SCR_CWT CWT 
				ON REF.CARE_ID = CWT.CARE_ID

LEFT JOIN	SCR_Warehouse.SCR_Comments comm
				ON	CWT.CARE_ID = comm.CARE_ID
				AND	comm.CommentType = 1			-- Tracking Notes
				AND	comm.CommentTypeCareIdRevIx = 1 -- the most recent tracking note

LEFT JOIN	SCR_Warehouse.OpenTargetDates OTD
				ON	CWT.CWT_ID = OTD.CWT_ID
				AND	OTD.IxFirstOpenTargetDate = 1

LEFT JOIN	SCR_Warehouse.SCR_NextActions sna
				ON	Ref.CARE_ID = sna.CareID
				AND	sna.CareIdIncompleteIx = 1

LEFT JOIN	CancerTransactions.EstimatedBreach eb
				ON	CWT.CWT_ID = eb.CWT_ID
				AND	eb.CurrentRecord = 1
LEFT JOIN	CancerTransactions.tvfEstimatedBreachMonths() ebm
				ON	DATEADD(MONTH, DATEDIFF(MONTH, 0, eb.EstimatedBreachDate), 0) = ebm.cte_start_date
GO
