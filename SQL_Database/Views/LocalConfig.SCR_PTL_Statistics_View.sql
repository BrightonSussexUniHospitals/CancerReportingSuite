SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [LocalConfig].[SCR_PTL_Statistics_View] 
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

Original Work Created Date:	30/07/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Create a view of the SCR_PTL_History, prepared for creating the SCR_PTL_Statistics dataset
**************************************************************************************************************************************************/


SELECT		PtlSnapshotId
			,DeathStatus
			,PctCode
			,CcgCode
			,CancerSite
			,CancerSiteBS
			,CancerSubSiteCode
			,ReferralCancerSiteCode
			,ReferralCancerSiteBS
			,CancerTypeCode
			,PriorityTypeCode
			,SourceReferralCode
			,ReferralMethodCode
			,TumourStatusCode
			,PatientStatusCode
			,PatientStatusCodeCwt
			,InappropriateRef
			,TransferReason
			,TransferTumourSiteCode
			,FastDiagCancerSiteID
			,FastDiagCancerSiteOverrideID
			,FastDiagCancerSiteCode
			,FastDiagEndReasonID
			,FastDiagDelayReasonID
			,FastDiagExclReasonID
			,FastDiagOrgID
			,FastDiagCommMethodID
			,FastDiagOtherCommMethod
			,FastDiagInformingCareProfID
			,FastDiagOtherCareProf
			,CASE	WHEN AgeAtDiagnosis < 0
					THEN '-ve'
					WHEN AgeAtDiagnosis >= 0 AND AgeAtDiagnosis < 10
					THEN '00-09'
					WHEN AgeAtDiagnosis >= 10 AND AgeAtDiagnosis < 20
					THEN '10-19'
					WHEN AgeAtDiagnosis >= 20 AND AgeAtDiagnosis < 30
					THEN '20-29'
					WHEN AgeAtDiagnosis >= 30 AND AgeAtDiagnosis < 40
					THEN '30-39'
					WHEN AgeAtDiagnosis >= 40 AND AgeAtDiagnosis < 50
					THEN '40-49'
					WHEN AgeAtDiagnosis >= 50 AND AgeAtDiagnosis < 60
					THEN '50-59'
					WHEN AgeAtDiagnosis >= 60 AND AgeAtDiagnosis < 70
					THEN '60-69'
					WHEN AgeAtDiagnosis >= 70 AND AgeAtDiagnosis < 80
					THEN '70-79'
					WHEN AgeAtDiagnosis >= 80 AND AgeAtDiagnosis < 90
					THEN '80-89'
					WHEN AgeAtDiagnosis >= 90 AND AgeAtDiagnosis < 100
					THEN '90-99'
					WHEN AgeAtDiagnosis >= 100
					THEN '100+'
					END AS AgeAtDiagnosis
			,ISNULL(DiagnosisSubCode, DiagnosisCode) AS DiagnosisSubCode
			,OrgIdDiagnosis
			,CASE	WHEN AgeAtReferral < 0
					THEN '-ve'
					WHEN AgeAtReferral >= 0 AND AgeAtReferral < 10
					THEN '00-09'
					WHEN AgeAtReferral >= 10 AND AgeAtReferral < 20
					THEN '10-19'
					WHEN AgeAtReferral >= 20 AND AgeAtReferral < 30
					THEN '20-29'
					WHEN AgeAtReferral >= 30 AND AgeAtReferral < 40
					THEN '30-39'
					WHEN AgeAtReferral >= 40 AND AgeAtReferral < 50
					THEN '40-49'
					WHEN AgeAtReferral >= 50 AND AgeAtReferral < 60
					THEN '50-59'
					WHEN AgeAtReferral >= 60 AND AgeAtReferral < 70
					THEN '60-69'
					WHEN AgeAtReferral >= 70 AND AgeAtReferral < 80
					THEN '70-79'
					WHEN AgeAtReferral >= 80 AND AgeAtReferral < 90
					THEN '80-89'
					WHEN AgeAtReferral >= 90 AND AgeAtReferral < 100
					THEN '90-99'
					WHEN AgeAtReferral >= 100
					THEN '100+'
					END AS AgeAtReferral
			,OrgIdUpgrade
			,OrgIdFirstSeen
			,FirstAppointmentTypeCode
			,FirstAppointmentOffered
			,ReasonNoAppointmentCode
			,FirstSeenAdjTime
			,FirstSeenAdjReasonCode
			,FirstSeenDelayReasonCode
			,DTTAdjTime
			,DTTAdjReasonCode
			,IsBCC
			,IsCwtCancerDiagnosis
			,UnderCancerCareFlag
			,DeftTreatmentEventCode
			,DeftTreatmentCode
			,DeftTreatmentSettingCode
			,DeftDTTAdjTime
			,DeftDTTAdjReasonCode
			,DeftOrgIdDecisionTreat
			,DeftOrgIdTreatment
			,DeftDefinitiveTreatment
			,DeftChemoRT
			,TxModModalitySubCode
			,TxModRadioSurgery
			,cwtFlag2WW
			,cwtFlag28
			,cwtFlag31
			,cwtFlag62
			,cwtType62
			,AdjTime2WW
			,AdjTime28
			,AdjTime31
			,AdjTime62
			,DaysTo62DayBreach
			,CASE	WHEN Waitingtime2WW <0
					THEN '-ve'
					WHEN Waitingtime2WW >= 365
					THEN '365+'
					ELSE FORMAT(Waitingtime2WW, '000')
					END AS Waitingtime2WW
			,CASE	WHEN Waitingtime28 <0
					THEN '-ve'
					WHEN Waitingtime28 >= 365
					THEN '365+'
					ELSE FORMAT(Waitingtime28, '000')
					END AS Waitingtime28
			,CASE	WHEN Waitingtime31 <0
					THEN '-ve'
					WHEN Waitingtime31 >= 365
					THEN '365+'
					ELSE FORMAT(Waitingtime31, '000')
					END AS Waitingtime31
			,CASE	WHEN Waitingtime62 <0
					THEN '-ve'
					WHEN Waitingtime62 >= 365
					THEN '365+'
					ELSE FORMAT(Waitingtime62, '000')
					END AS Waitingtime62
			,CASE	WHEN DaysSinceLastTracked <0
					THEN '-ve'
					WHEN DaysSinceLastTracked >= 365
					THEN '365+'
					ELSE FORMAT(DaysSinceLastTracked, '000')
					END AS DaysSinceLastTracked
			,Weighting
			,DaysToNextBreach
			,NextBreachTarget
			,Priority2WW
			,Priority28
			,Priority31
			,Priority62
			,NextActionDesc
			,NextActionSpecificDesc
			,DaysToNextAction
			,OwnerDesc
			,Escalated
			,CWTStatusCode2WW
			,CWTStatusCode28
			,CWTStatusCode31
			,ISNULL(CWTStatusCode62, DominantCWTStatusCode) AS CWTStatusCode62

FROM		SCR_Reporting_History.SCR_PTL_History
GO
