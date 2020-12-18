SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 CREATE PROCEDURE [SCR_Reporting_History].[uspCreateSomersetReportingHistory] 
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

Original Work Created Date:	19/05/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Create and update the archive datasets for all SCR / Somerset reporting
**************************************************************************************************************************************************/


		-- Set up internal variables for use by the procedure
		DECLARE @PtlSnapshotId TABLE (PtlSnapshotId int)


/************************************************************************************************************************************************************************************************************
-- Create / identify the snapshot ID
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when creating a SCR_PTL_History snapshot started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspCreateSomersetReportingHistory', @Step = 'Insert PTL History'
				
		-- Find the snapshot if from the SCR_PTL_SnapshotDates table, if one exists
		DECLARE @LastRefSnapshotDate datetime = (SELECT MAX(ReportDate) FROM SCR_Warehouse.SCR_Referrals)
		DECLARE @ExistingHistorySnapshotId int = (SELECT PtlSnapshotId FROM SCR_Reporting_History.SCR_PTL_SnapshotDates WHERE PtlSnapshotDate = @LastRefSnapshotDate)

		-- If the snapshote date in SCR_CWT already exists in SCR_PTL_SnapshotDates then set the
		-- PtlSnapshotId into the @PtlSnapshotId table ready for processing
		IF @ExistingHistorySnapshotId IS NOT NULL
		BEGIN
			-- Establish a new PtlSnapshotId before the earliest existing snapshot
			INSERT INTO	@PtlSnapshotId (PtlSnapshotId) VALUES (@ExistingHistorySnapshotId)
		END

		
		-- If the snapshot date in SCR_CWT doesn't exist in the SCR_PTL_SnapshotDates table, then
		-- insert the snapshot date into the SCR_PTL_SnapshotDates table and acquire the PtlSnapshotId
		IF @ExistingHistorySnapshotId IS NULL
		BEGIN
			INSERT INTO	SCR_Reporting_History.SCR_PTL_SnapshotDates (PtlSnapshotDate)
			OUTPUT		inserted.PtlSnapshotId INTO @PtlSnapshotId (PtlSnapshotId)
			VALUES		(@LastRefSnapshotDate)
		END
		
/************************************************************************************************************************************************************************************************************
-- Take the snapshot of the final PTL datasets
************************************************************************************************************************************************************************************************************/

		-- Begin a try-catch just to ensure that the transaction is rolled back in the case that the SCR_PTL_History transaction fails
		BEGIN TRY
			
			-- Begin a transaction to process the SCR_PTL_History table in case data needs to be initially deleted because the snapshot date in SCR_CWT already exists 
			-- (to ensure that the deleted data is replaced before the transaction is committed)
			BEGIN TRANSACTION
		
				-- If the snapshot date in SCR_CWT already exists then delete the existing snapshot data
				IF @ExistingHistorySnapshotId IS NOT NULL
				DELETE
				FROM		SCR_Reporting_History.SCR_PTL_History
				WHERE		PtlSnapshotId = @ExistingHistorySnapshotId

				-- Insert PTL History
				INSERT INTO	SCR_Reporting_History.SCR_PTL_History
							(CARE_ID
							,PatientPathwayID
							,PatientPathwayIdIssuer
							,PATIENT_ID
							,MainRefActionId
							,DiagnosisActionId
							,DemographicsActionId
							-- Demographics
							,Forename
							,Surname
							,DateBirth
							,HospitalNumber
							,NHSNumber
							,NHSNumberStatusCode
							,NstsStatus
							,IsTemporaryNHSNumber
							,DeathStatus
							,DateDeath
							,PctCode
							,PctDesc
							,CcgCode
							,CcgDesc
							-- Referral Pathway data
							,CancerSite
							,CancerSiteBS
							,CancerSubSiteCode
							,CancerSubSiteDesc
							,ReferralCancerSiteCode
							,ReferralCancerSiteDesc
							,ReferralCancerSiteBS
							,CancerTypeCode
							,CancerTypeDesc
							,PriorityTypeCode
							,PriorityTypeDesc
							,SourceReferralCode
							,SourceReferralDesc
							,ReferralMethodCode
							,DecisionToReferDate
							,TumourStatusCode
							,TumourStatusDesc
							,PatientStatusCode
							,PatientStatusDesc
							,PatientStatusCodeCwt
							,PatientStatusDescCwt
							,ConsultantCode
							,ConsultantName
							,InappropriateRef
							-- Referral Transfer data
							,TransferReason
							,TransferNewRefDate
							,TransferTumourSiteCode
							,TransferTumourSiteDesc
							,TransferActionedDate
							,TransferSourceCareId
							,TransferOrigSourceCareId
							-- Faster Diagnosis
							,FastDiagInformedDate
							,FastDiagExclDate
							,FastDiagCancerSiteID
							,FastDiagCancerSiteOverrideID
							,FastDiagCancerSiteCode
							,FastDiagCancerSiteDesc
							,FastDiagEndReasonID
							,FastDiagEndReasonCode
							,FastDiagEndReasonDesc
							,FastDiagDelayReasonID
							,FastDiagDelayReasonCode
							,FastDiagDelayReasonDesc
							,FastDiagDelayReasonComments
							,FastDiagExclReasonID
							,FastDiagExclReasonCode
							,FastDiagExclReasonDesc
							,FastDiagOrgID
							,FastDiagOrgCode
							,FastDiagOrgDesc
							,FastDiagCommMethodID
							,FastDiagCommMethodCode
							,FastDiagCommMethodDesc
							,FastDiagOtherCommMethod
							,FastDiagInformingCareProfID
							,FastDiagInformingCareProfCode
							,FastDiagInformingCareProfDesc
							,FastDiagOtherCareProf
							,FDPlannedInterval
							-- Referral Diagnoses
							,DateDiagnosis
							,AgeAtDiagnosis
							,DiagnosisCode
							,DiagnosisSubCode
							,DiagnosisDesc
							,DiagnosisSubDesc
							,OrgIdDiagnosis
							,OrgCodeDiagnosis
							,OrgDescDiagnosis
							,SnomedCT_ID
							,SnomedCT_MCode
							,SnomedCT_ConceptID
							,SnomedCT_Desc
							,Histology
							-- Referral Waits data
							,DateReceipt
							,AgeAtReferral
							,AppointmentCancelledDate
							,DateConsultantUpgrade
							,DateFirstSeen
							,OrgIdUpgrade
							,OrgCodeUpgrade
							,OrgDescUpgrade
							,OrgIdFirstSeen
							,OrgCodeFirstSeen
							,OrgDescFirstSeen
							,FirstAppointmentTypeCode
							,FirstAppointmentTypeDesc
							,FirstAppointmentOffered
							,ReasonNoAppointmentCode
							,ReasonNoAppointmentDesc
							,FirstSeenAdjTime
							,FirstSeenAdjReasonCode
							,FirstSeenAdjReasonDesc
							,FirstSeenDelayReasonCode
							,FirstSeenDelayReasonDesc
							,FirstSeenDelayReasonComment
							,DTTAdjTime
							,DTTAdjReasonCode
							,DTTAdjReasonDesc
							-- Referral data flags
							,IsBCC
							,IsCwtCancerDiagnosis
							,UnderCancerCareFlag
							-- Pathway Based Provenance
							,RefreshMaxActionDate
							,ReferralReportDate
							-- CWT Based ID's
							,CWTInsertIx
							,OriginalCWTInsertIx
							,CWT_ID
							,Tx_ID
							,TREATMENT_ID
							,TREAT_ID
							,CHEMO_ID
							,TELE_ID
							,PALL_ID
							,BRACHY_ID
							,OTHER_ID
							,SURGERY_ID
							,MONITOR_ID
							,ChemoActionId
							,TeleActionId
							,PallActionId
							,BrachyActionId
							,OtherActionId
							,SurgeryActionId
							,MonitorActionId
							-- CWT Based Definitive Treatments (Treatments, or potential to treat, with CWT flags)
							,DeftTreatmentEventCode
							,DeftTreatmentEventDesc
							,DeftTreatmentCode
							,DeftTreatmentDesc
							,DeftTreatmentSettingCode
							,DeftTreatmentSettingDesc
							,DeftDateDecisionTreat
							,DeftDateTreatment
							,DeftDTTAdjTime
							,DeftDTTAdjReasonCode
							,DeftDTTAdjReasonDesc
							,DeftOrgIdDecisionTreat
							,DeftOrgCodeDecisionTreat
							,DeftOrgDescDecisionTreat
							,DeftOrgIdTreatment
							,DeftOrgCodeTreatment
							,DeftOrgDescTreatment
							,DeftDefinitiveTreatment
							,DeftChemoRT
							-- CWT Based Treatment modality Treatments
							,TxModTreatmentEventCode
							,TxModTreatmentEventDesc
							,TxModTreatmentCode
							,TxModTreatmentDesc
							,TxModTreatmentSettingCode
							,TxModTreatmentSettingDesc
							,TxModDateDecisionTreat
							,TxModDateTreatment
							,TxModOrgIdDecisionTreat
							,TxModOrgCodeDecisionTreat
							,TxModOrgDescDecisionTreat
							,TxModOrgIdTreatment
							,TxModOrgCodeTreatment
							,TxModOrgDescTreatment
							,TxModDefinitiveTreatment
							,TxModChemoRadio
							,TxModChemoRT
							,TxModModalitySubCode
							,TxModRadioSurgery
							-- CWT Based ChemoRT Treatment modality Treatments
							,ChemRtLinkTreatmentEventCode
							,ChemRtLinkTreatmentEventDesc
							,ChemRtLinkTreatmentCode
							,ChemRtLinkTreatmentDesc
							,ChemRtLinkTreatmentSettingCode
							,ChemRtLinkTreatmentSettingDesc
							,ChemRtLinkDateDecisionTreat
							,ChemRtLinkDateTreatment
							,ChemRtLinkOrgIdDecisionTreat
							,ChemRtLinkOrgCodeDecisionTreat
							,ChemRtLinkOrgDescDecisionTreat
							,ChemRtLinkOrgIdTreatment
							,ChemRtLinkOrgCodeTreatment
							,ChemRtLinkOrgDescTreatment
							,ChemRtLinkDefinitiveTreatment
							,ChemRtLinkChemoRadio
							,ChemRtLinkModalitySubCode
							,ChemRtLinkRadioSurgery
							-- CWT Based data flags
							,cwtFlag2WW
							,cwtFlag28
							,cwtFlag31
							,cwtFlag62
							,cwtType2WW
							,cwtType28
							,cwtType31
							,cwtType62
							,cwtReason2WW
							,cwtReason28
							,cwtReason31
							,cwtReason62
							,HasTxMod
							,HasChemRtLink
							-- CWT Wait Calculations
							,ClockStartDate2WW
							,ClockStartDate28
							,ClockStartDate31
							,ClockStartDate62
							,AdjTime2WW
							,AdjTime28
							,AdjTime31
							,AdjTime62
							,TargetDate2WW
							,TargetDate28
							,TargetDate31
							,TargetDate62
							,DaysTo2WWBreach
							,DaysTo28DayBreach
							,DaysTo31DayBreach
							,DaysTo62DayBreach
							,ClockStopDate2WW
							,ClockStopDate28
							,ClockStopDate31
							,ClockStopDate62
							,Waitingtime2WW
							,Waitingtime28
							,Waitingtime31
							,Waitingtime62
							,Breach2WW
							,Breach28
							,Breach31
							,Breach62
							,DaysTo62DayBreachNoDTT
							,Treated7Days
							,Treated7Days62Days
							,FutureAchieve62Days
							,FutureFail62Days
							,ActualWaitDTTTreatment
							,DTTTreated7Days
							,Treated7Days31Days
							,Treated7DaysBreach31Days
							,FutureAchieve31Days
							,FutureFail31Days
							,FutureDTT
							,NoDTTDate
							-- CWT Based Provenance
							,LastCommentUser
							,LastCommentDate
							,CwtReportDate
							,PtlSnapshotId
							-- PTL_Live Snapshot data (that isn't already in CWT or Referrals)
							,Pathway
							,TrackingNotes
							,DateLastTracked
							,CommentUser
							,DaysSinceLastTracked
							,Weighting
							,DaysToNextBreach
							,NextBreachTarget
							,NextBreachDate
							,DominantColourValue
							,ColourValue2WW
							,ColourValue28Day
							,ColourValue31Day
							,ColourValue62Day
							,DominantColourDesc
							,ColourDesc2WW
							,ColourDesc28Day
							,ColourDesc31Day
							,ColourDesc62Day
							,DominantPriority
							,Priority2WW
							,Priority28
							,Priority31
							,Priority62
							,PathwayUpdateEventID
							,NextActionDesc
							,NextActionSpecificDesc
							,NextActionTargetDate
							,DaysToNextAction
							,OwnerDesc
							,AdditionalDetails
							,Escalated
							-- TECHNICAL DEBT -- PTL Status
							,ReportingPathwayLength
							-- TECHNICAL DEBT --CWT Status
							,DominantCWTStatusCode 
							,DominantCWTStatusDesc
							,CWTStatusCode2WW
							,CWTStatusDesc2WW
							,CWTStatusCode28 
							,CWTStatusDesc28 
							,CWTStatusCode31 
							,CWTStatusDesc31 
							,CWTStatusCode62 
							,CWTStatusDesc62
							,SSRS_PTLFlag62)

				SELECT		CARE_ID							=	Referrals.CARE_ID
							,PatientPathwayID				=	Referrals.PatientPathwayID
							,PatientPathwayIdIssuer			=	Referrals.PatientPathwayIdIssuer
							,PATIENT_ID						=	Referrals.PATIENT_ID
							,MainRefActionId				=	Referrals.MainRefActionId
							,DiagnosisActionId				=	Referrals.DiagnosisActionId
							,DemographicsActionId			=	Referrals.DemographicsActionId
							-- Demographics
							,Forename						=	Referrals.Forename
							,Surname						=	Referrals.Surname
							,DateBirth						=	Referrals.DateBirth
							,HospitalNumber					=	Referrals.HospitalNumber
							,NHSNumber						=	Referrals.NHSNumber
							,NHSNumberStatusCode			=	Referrals.NHSNumberStatusCode
							,NstsStatus						=	Referrals.NstsStatus
							,IsTemporaryNHSNumber			=	Referrals.IsTemporaryNHSNumber
							,DeathStatus					=	Referrals.DeathStatus
							,DateDeath						=	Referrals.DateDeath
							,PctCode						=	Referrals.PctCode
							,PctDesc						=	Referrals.PctDesc
							,CcgCode						=	Referrals.CcgCode
							,CcgDesc						=	Referrals.CcgDesc
							-- Referral Pathway data
							,CancerSite						=	Referrals.CancerSite
							,CancerSiteBS					=	Referrals.CancerSiteBS
							,CancerSubSiteCode				=	Referrals.CancerSubSiteCode
							,CancerSubSiteDesc				=	Referrals.CancerSubSiteDesc
							,ReferralCancerSiteCode			=	Referrals.ReferralCancerSiteCode
							,ReferralCancerSiteDesc			=	Referrals.ReferralCancerSiteDesc
							,ReferralCancerSiteBS			=	Referrals.ReferralCancerSiteBS
							,CancerTypeCode					=	Referrals.CancerTypeCode
							,CancerTypeDesc					=	Referrals.CancerTypeDesc
							,PriorityTypeCode				=	Referrals.PriorityTypeCode
							,PriorityTypeDesc				=	Referrals.PriorityTypeDesc
							,SourceReferralCode				=	Referrals.SourceReferralCode
							,SourceReferralDesc				=	Referrals.SourceReferralDesc
							,ReferralMethodCode				=	Referrals.ReferralMethodCode
							,DecisionToReferDate			=	Referrals.DecisionToReferDate
							,TumourStatusCode				=	Referrals.TumourStatusCode
							,TumourStatusDesc				=	Referrals.TumourStatusDesc
							,PatientStatusCode				=	Referrals.PatientStatusCode
							,PatientStatusDesc				=	Referrals.PatientStatusDesc
							,PatientStatusCodeCwt			=	Referrals.PatientStatusCodeCwt
							,PatientStatusDescCwt			=	Referrals.PatientStatusDescCwt
							,ConsultantCode					=	Referrals.ConsultantCode
							,ConsultantName					=	Referrals.ConsultantName
							,InappropriateRef				=	Referrals.InappropriateRef
							-- Referral Transfer data
							,TransferReason					=	Referrals.TransferReason
							,TransferNewRefDate				=	Referrals.TransferNewRefDate
							,TransferTumourSiteCode			=	Referrals.TransferTumourSiteCode
							,TransferTumourSiteDesc			=	Referrals.TransferTumourSiteDesc
							,TransferActionedDate			=	Referrals.TransferActionedDate
							,TransferSourceCareId			=	Referrals.TransferSourceCareId
							,TransferOrigSourceCareId		=	Referrals.TransferOrigSourceCareId
							-- Faster Diagnosis
							,FastDiagInformedDate			=	Referrals.FastDiagInformedDate
							,FastDiagExclDate				=	Referrals.FastDiagExclDate
							,FastDiagCancerSiteID			=	Referrals.FastDiagCancerSiteID
							,FastDiagCancerSiteOverrideID	=	Referrals.FastDiagCancerSiteOverrideID
							,FastDiagCancerSiteCode			=	Referrals.FastDiagCancerSiteCode
							,FastDiagCancerSiteDesc			=	Referrals.FastDiagCancerSiteDesc
							,FastDiagEndReasonID			=	Referrals.FastDiagEndReasonID
							,FastDiagEndReasonCode			=	Referrals.FastDiagEndReasonCode
							,FastDiagEndReasonDesc			=	Referrals.FastDiagEndReasonDesc
							,FastDiagDelayReasonID			=	Referrals.FastDiagDelayReasonID
							,FastDiagDelayReasonCode		=	Referrals.FastDiagDelayReasonCode
							,FastDiagDelayReasonDesc		=	Referrals.FastDiagDelayReasonDesc
							,FastDiagDelayReasonComments	=	Referrals.FastDiagDelayReasonComments
							,FastDiagExclReasonID			=	Referrals.FastDiagExclReasonID
							,FastDiagExclReasonCode			=	Referrals.FastDiagExclReasonCode
							,FastDiagExclReasonDesc			=	Referrals.FastDiagExclReasonDesc
							,FastDiagOrgID					=	Referrals.FastDiagOrgID
							,FastDiagOrgCode				=	Referrals.FastDiagOrgCode
							,FastDiagOrgDesc				=	Referrals.FastDiagOrgDesc
							,FastDiagCommMethodID			=	Referrals.FastDiagCommMethodID
							,FastDiagCommMethodCode			=	Referrals.FastDiagCommMethodCode
							,FastDiagCommMethodDesc			=	Referrals.FastDiagCommMethodDesc
							,FastDiagOtherCommMethod		=	Referrals.FastDiagOtherCommMethod
							,FastDiagInformingCareProfID	=	Referrals.FastDiagInformingCareProfID
							,FastDiagInformingCareProfCode	=	Referrals.FastDiagInformingCareProfCode
							,FastDiagInformingCareProfDesc	=	Referrals.FastDiagInformingCareProfDesc
							,FastDiagOtherCareProf			=	Referrals.FastDiagOtherCareProf
							,FDPlannedInterval				=	Referrals.FDPlannedInterval
							-- Referral Diagnoses
							,DateDiagnosis					=	Referrals.DateDiagnosis
							,AgeAtDiagnosis					=	Referrals.AgeAtDiagnosis
							,DiagnosisCode					=	Referrals.DiagnosisCode
							,DiagnosisSubCode				=	Referrals.DiagnosisSubCode
							,DiagnosisDesc					=	Referrals.DiagnosisDesc
							,DiagnosisSubDesc				=	Referrals.DiagnosisSubDesc
							,OrgIdDiagnosis					=	Referrals.OrgIdDiagnosis	
							,OrgCodeDiagnosis				=	Referrals.OrgCodeDiagnosis
							,OrgDescDiagnosis				=	Referrals.OrgDescDiagnosis
							,SnomedCT_ID					=	Referrals.SnomedCT_ID
							,SnomedCT_MCode					=	Referrals.SnomedCT_MCode
							,SnomedCT_ConceptID				=	Referrals.SnomedCT_ConceptID
							,SnomedCT_Desc					=	Referrals.SnomedCT_Desc
							,Histology						=	Referrals.Histology
							-- Referral Waits data
							,DateReceipt					=	Referrals.DateReceipt
							,AgeAtReferral					=	Referrals.AgeAtReferral
							,AppointmentCancelledDate		=	Referrals.AppointmentCancelledDate
							,DateConsultantUpgrade			=	Referrals.DateConsultantUpgrade
							,DateFirstSeen					=	Referrals.DateFirstSeen
							,OrgIdUpgrade					=	Referrals.OrgIdUpgrade
							,OrgCodeUpgrade					=	Referrals.OrgCodeUpgrade
							,OrgDescUpgrade					=	Referrals.OrgDescUpgrade
							,OrgIdFirstSeen					=	Referrals.OrgIdFirstSeen
							,OrgCodeFirstSeen				=	Referrals.OrgCodeFirstSeen
							,OrgDescFirstSeen				=	Referrals.OrgDescFirstSeen
							,FirstAppointmentTypeCode		=	Referrals.FirstAppointmentTypeCode
							,FirstAppointmentTypeDesc		=	Referrals.FirstAppointmentTypeDesc
							,FirstAppointmentOffered		=	Referrals.FirstAppointmentOffered
							,ReasonNoAppointmentCode		=	Referrals.ReasonNoAppointmentCode
							,ReasonNoAppointmentDesc		=	Referrals.ReasonNoAppointmentDesc
							,FirstSeenAdjTime				=	Referrals.FirstSeenAdjTime
							,FirstSeenAdjReasonCode			=	Referrals.FirstSeenAdjReasonCode
							,FirstSeenAdjReasonDesc			=	Referrals.FirstSeenAdjReasonDesc
							,FirstSeenDelayReasonCode		=	Referrals.FirstSeenDelayReasonCode
							,FirstSeenDelayReasonDesc		=	Referrals.FirstSeenDelayReasonDesc
							,FirstSeenDelayReasonComment	=	Referrals.FirstSeenDelayReasonComment
							,DTTAdjTime						=	Referrals.DTTAdjTime
							,DTTAdjReasonCode				=	Referrals.DTTAdjReasonCode
							,DTTAdjReasonDesc				=	Referrals.DTTAdjReasonDesc
							-- Referral data flags
							,IsBCC							=	Referrals.IsBCC
							,IsCwtCancerDiagnosis			=	Referrals.IsCwtCancerDiagnosis
							,UnderCancerCareFlag			=	Referrals.UnderCancerCareFlag
							-- Pathway Based Provenance
							,RefreshMaxActionDate			=	Referrals.RefreshMaxActionDate
							,ReferralReportDate				=	Referrals.ReportDate
							-- CWT Based ID's
							,CWTInsertIx					=	CWT.CWTInsertIx
							,OriginalCWTInsertIx			=	CWT.OriginalCWTInsertIx
							,CWT_ID							=	CWT.CWT_ID
							,Tx_ID							=	CWT.Tx_ID
							,TREATMENT_ID					=	CWT.TREATMENT_ID
							,TREAT_ID						=	CWT.TREAT_ID
							,CHEMO_ID						=	CWT.CHEMO_ID
							,TELE_ID						=	CWT.TELE_ID
							,PALL_ID						=	CWT.PALL_ID
							,BRACHY_ID						=	CWT.BRACHY_ID
							,OTHER_ID						=	CWT.OTHER_ID
							,SURGERY_ID						=	CWT.SURGERY_ID
							,MONITOR_ID						=	CWT.MONITOR_ID
							,ChemoActionId					=	CWT.ChemoActionId
							,TeleActionId					=	CWT.TeleActionId
							,PallActionId					=	CWT.PallActionId
							,BrachyActionId					=	CWT.BrachyActionId
							,OtherActionId					=	CWT.OtherActionId
							,SurgeryActionId				=	CWT.SurgeryActionId
							,MonitorActionId				=	CWT.MonitorActionId
							-- CWT Based Definitive Treatments (Treatments, or potential to treat, with CWT flags)
							,DeftTreatmentEventCode			=	CWT.DeftTreatmentEventCode
							,DeftTreatmentEventDesc			=	CWT.DeftTreatmentEventDesc
							,DeftTreatmentCode				=	CWT.DeftTreatmentCode
							,DeftTreatmentDesc				=	CWT.DeftTreatmentDesc
							,DeftTreatmentSettingCode		=	CWT.DeftTreatmentSettingCode
							,DeftTreatmentSettingDesc		=	CWT.DeftTreatmentSettingDesc
							,DeftDateDecisionTreat			=	CWT.DeftDateDecisionTreat
							,DeftDateTreatment				=	CWT.DeftDateTreatment
							,DeftDTTAdjTime					=	CWT.DeftDTTAdjTime
							,DeftDTTAdjReasonCode			=	CWT.DeftDTTAdjReasonCode
							,DeftDTTAdjReasonDesc			=	CWT.DeftDTTAdjReasonDesc
							,DeftOrgIdDecisionTreat			=	CWT.DeftOrgIdDecisionTreat
							,DeftOrgCodeDecisionTreat		=	CWT.DeftOrgCodeDecisionTreat
							,DeftOrgDescDecisionTreat		=	CWT.DeftOrgDescDecisionTreat
							,DeftOrgIdTreatment				=	CWT.DeftOrgIdTreatment
							,DeftOrgCodeTreatment			=	CWT.DeftOrgCodeTreatment
							,DeftOrgDescTreatment			=	CWT.DeftOrgDescTreatment
							,DeftDefinitiveTreatment		=	CWT.DeftDefinitiveTreatment
							,DeftChemoRT					=	CWT.DeftChemoRT
							-- CWT Based Treatment modality Treatments
							,TxModTreatmentEventCode		=	CWT.TxModTreatmentEventCode
							,TxModTreatmentEventDesc		=	CWT.TxModTreatmentEventDesc
							,TxModTreatmentCode				=	CWT.TxModTreatmentCode
							,TxModTreatmentDesc				=	CWT.TxModTreatmentDesc
							,TxModTreatmentSettingCode		=	CWT.TxModTreatmentSettingCode
							,TxModTreatmentSettingDesc		=	CWT.TxModTreatmentSettingDesc
							,TxModDateDecisionTreat			=	CWT.TxModDateDecisionTreat
							,TxModDateTreatment				=	CWT.TxModDateTreatment
							,TxModOrgIdDecisionTreat		=	CWT.TxModOrgIdDecisionTreat
							,TxModOrgCodeDecisionTreat		=	CWT.TxModOrgCodeDecisionTreat
							,TxModOrgDescDecisionTreat		=	CWT.TxModOrgDescDecisionTreat
							,TxModOrgIdTreatment			=	CWT.TxModOrgIdTreatment
							,TxModOrgCodeTreatment			=	CWT.TxModOrgCodeTreatment
							,TxModOrgDescTreatment			=	CWT.TxModOrgDescTreatment
							,TxModDefinitiveTreatment		=	CWT.TxModDefinitiveTreatment
							,TxModChemoRadio				=	CWT.TxModChemoRadio
							,TxModChemoRT					=	CWT.TxModChemoRT
							,TxModModalitySubCode			=	CWT.TxModModalitySubCode
							,TxModRadioSurgery				=	CWT.TxModRadioSurgery
							-- CWT Based ChemoRT Treatment modality Treatments
							,ChemRtLinkTreatmentEventCode	=	CWT.ChemRtLinkTreatmentEventCode
							,ChemRtLinkTreatmentEventDesc	=	CWT.ChemRtLinkTreatmentEventDesc
							,ChemRtLinkTreatmentCode		=	CWT.ChemRtLinkTreatmentCode
							,ChemRtLinkTreatmentDesc		=	CWT.ChemRtLinkTreatmentDesc
							,ChemRtLinkTreatmentSettingCode	=	CWT.ChemRtLinkTreatmentSettingCode
							,ChemRtLinkTreatmentSettingDesc	=	CWT.ChemRtLinkTreatmentSettingDesc
							,ChemRtLinkDateDecisionTreat	=	CWT.ChemRtLinkDateDecisionTreat
							,ChemRtLinkDateTreatment		=	CWT.ChemRtLinkDateTreatment
							,ChemRtLinkOrgIdDecisionTreat	=	CWT.ChemRtLinkOrgIdDecisionTreat
							,ChemRtLinkOrgCodeDecisionTreat	=	CWT.ChemRtLinkOrgCodeDecisionTreat
							,ChemRtLinkOrgDescDecisionTreat	=	CWT.ChemRtLinkOrgDescDecisionTreat
							,ChemRtLinkOrgIdTreatment		=	CWT.ChemRtLinkOrgIdTreatment
							,ChemRtLinkOrgCodeTreatment		=	CWT.ChemRtLinkOrgCodeTreatment
							,ChemRtLinkOrgDescTreatment		=	CWT.ChemRtLinkOrgDescTreatment
							,ChemRtLinkDefinitiveTreatment	=	CWT.ChemRtLinkDefinitiveTreatment
							,ChemRtLinkChemoRadio			=	CWT.ChemRtLinkChemoRadio
							,ChemRtLinkModalitySubCode		=	CWT.ChemRtLinkModalitySubCode
							,ChemRtLinkRadioSurgery			=	CWT.ChemRtLinkRadioSurgery
							-- CWT Based data flags
							,cwtFlag2WW						=	CWT.cwtFlag2WW
							,cwtFlag28						=	CWT.cwtFlag28
							,cwtFlag31						=	CWT.cwtFlag31
							,cwtFlag62						=	CWT.cwtFlag62
							,cwtType2WW						=	CWT.cwtType2WW
							,cwtType28						=	CWT.cwtType28
							,cwtType31						=	CWT.cwtType31
							,cwtType62						=	CWT.cwtType62
							,cwtReason2WW					=	CWT.cwtReason2WW
							,cwtReason28					=	CWT.cwtReason28
							,cwtReason31					=	CWT.cwtReason31
							,cwtReason62					=	CWT.cwtReason62
							,HasTxMod						=	CWT.HasTxMod
							,HasChemRtLink					=	CWT.HasChemRtLink
							-- CWT Wait Calculations
							,ClockStartDate2WW				=	CWT.ClockStartDate2WW
							,ClockStartDate28				=	CWT.ClockStartDate28
							,ClockStartDate31				=	CWT.ClockStartDate31
							,ClockStartDate62				=	CWT.ClockStartDate62
							,AdjTime2WW						=	CWT.AdjTime2WW
							,AdjTime28						=	CWT.AdjTime28
							,AdjTime31						=	CWT.AdjTime31
							,AdjTime62						=	CWT.AdjTime62
							,TargetDate2WW					=	CWT.TargetDate2WW
							,TargetDate28					=	CWT.TargetDate28
							,TargetDate31					=	CWT.TargetDate31
							,TargetDate62					=	CWT.TargetDate62
							,DaysTo2WWBreach				=	CWT.DaysTo2WWBreach
							,DaysTo28DayBreach				=	CWT.DaysTo28DayBreach
							,DaysTo31DayBreach				=	CWT.DaysTo31DayBreach
							,DaysTo62DayBreach				=	CWT.DaysTo62DayBreach
							,ClockStopDate2WW				=	CWT.ClockStopDate2WW
							,ClockStopDate28				=	CWT.ClockStopDate28
							,ClockStopDate31				=	CWT.ClockStopDate31
							,ClockStopDate62				=	CWT.ClockStopDate62
							,Waitingtime2WW					=	CWT.Waitingtime2WW
							,Waitingtime28					=	CWT.Waitingtime28
							,Waitingtime31					=	CWT.Waitingtime31
							,Waitingtime62					=	CWT.Waitingtime62
							,Breach2WW						=	CWT.Breach2WW
							,Breach28						=	CWT.Breach28
							,Breach31						=	CWT.Breach31
							,Breach62						=	CWT.Breach62
							,DaysTo62DayBreachNoDTT			=	CWT.DaysTo62DayBreachNoDTT
							,Treated7Days					=	CWT.Treated7Days
							,Treated7Days62Days				=	CWT.Treated7Days62Days
							,FutureAchieve62Days			=	CWT.FutureAchieve62Days
							,FutureFail62Days				=	CWT.FutureFail62Days
							,ActualWaitDTTTreatment			=	CWT.ActualWaitDTTTreatment
							,DTTTreated7Days				=	CWT.DTTTreated7Days
							,Treated7Days31Days				=	CWT.Treated7Days31Days
							,Treated7DaysBreach31Days		=	CWT.Treated7DaysBreach31Days
							,FutureAchieve31Days			=	CWT.FutureAchieve31Days
							,FutureFail31Days				=	CWT.FutureFail31Days
							,FutureDTT						=	CWT.FutureDTT
							,NoDTTDate						=	CWT.NoDTTDate
							-- CWT Based Provenance
							,LastCommentUser				=	CWT.LastCommentUser
							,LastCommentDate				=	CWT.LastCommentDate
							,CwtReportDate					=	CWT.ReportDate
							,PtlSnapshotId					=	PtlSnapshotId.PtlSnapshotId
							-- PTL_Live Snapshot data (that isn't already in CWT or Referrals)
							,Pathway						=	PTL_Live.Pathway
							,TrackingNotes					=	PTL_Live.TrackingNotes
							,DateLastTracked				=	PTL_Live.DateLastTracked
							,CommentUser					=	PTL_Live.CommentUser
							,DaysSinceLastTracked			=	PTL_Live.DaysSinceLastTracked
							,Weighting						=	PTL_Live.Weighting
							,DaysToNextBreach				=	PTL_Live.DaysToNextBreach
							,NextBreachTarget				=	PTL_Live.NextBreachTarget
							,NextBreachDate					=	PTL_Live.NextBreachDate
							,DominantColourValue			=	PTL_Live.DominantColourValue
							,ColourValue2WW					=	PTL_Live.ColourValue2WW
							,ColourValue28Day				=	PTL_Live.ColourValue28Day
							,ColourValue31Day				=	PTL_Live.ColourValue31Day
							,ColourValue62Day				=	PTL_Live.ColourValue62Day
							,DominantColourDesc				=	PTL_Live.DominantColourDesc
							,ColourDesc2WW					=	PTL_Live.ColourDesc2WW
							,ColourDesc28Day				=	PTL_Live.ColourDesc28Day
							,ColourDesc31Day				=	PTL_Live.ColourDesc31Day
							,ColourDesc62Day				=	PTL_Live.ColourDesc62Day
							,DominantPriority				=	PTL_Live.DominantPriority
							,Priority2WW					=	PTL_Live.Priority2WW
							,Priority28						=	PTL_Live.Priority28
							,Priority31						=	PTL_Live.Priority31
							,Priority62						=	PTL_Live.Priority62
							,PathwayUpdateEventID			=	PTL_Live.PathwayUpdateEventID
							,NextActionDesc					=	PTL_Live.NextActionDesc
							,NextActionSpecificDesc			=	PTL_Live.NextActionSpecificDesc
							,NextActionTargetDate			=	PTL_Live.NextActionTargetDate
							,DaysToNextAction				=	PTL_Live.DaysToNextAction
							,OwnerDesc						=	PTL_Live.OwnerDesc
							,AdditionalDetails				=	PTL_Live.AdditionalDetails
							,Escalated						=	PTL_Live.Escalated
							-- TECHNICAL DEBT -- PTL Status
							,ReportingPathwayLength			=	PTL_Live.ReportingPathwayLength
							-- TECHNICAL DEBT --CWT Status
							,DominantCWTStatusCode 			=	PTL_Live.DominantCWTStatusCode 
							,DominantCWTStatusDesc			=	PTL_Live.DominantCWTStatusDesc
							,CWTStatusCode2WW				=	PTL_Live.CWTStatusCode2WW
							,CWTStatusDesc2WWL				=	PTL_Live.CWTStatusDesc2WW
							,CWTStatusCode28 				=	PTL_Live.CWTStatusCode28 
							,CWTStatusDesc28 				=	PTL_Live.CWTStatusDesc28 
							,CWTStatusCode31 				=	PTL_Live.CWTStatusCode31 
							,CWTStatusDesc31 				=	PTL_Live.CWTStatusDesc31 
							,CWTStatusCode62 				=	PTL_Live.CWTStatusCode62 
							,CWTStatusDesc62 				=	PTL_Live.CWTStatusDesc62 
							,SSRS_PTLFlag62					=	PTL_Live.SSRS_PTLFlag62

				FROM		SCR_Warehouse.SCR_Referrals Referrals
				INNER JOIN	SCR_Warehouse.SCR_CWT CWT
								ON	Referrals.CARE_ID = CWT.CARE_ID
				LEFT JOIN	SCR_Reporting.PTL_Live PTL_Live
								ON	CWT.CWT_ID = PTL_Live.CWT_ID
				CROSS JOIN	@PtlSnapshotId PtlSnapshotId

			-- If there have been no errors up to this point then commit the transaction
			COMMIT TRANSACTION

		-- End the try
		END TRY
		
		-- Catch errors that may have occured during the attempted transaction to ensure that the transaction is rolled back
		BEGIN CATCH

			IF @@TRANCOUNT > 0
				PRINT 'Rolling back because of error in processing SCR_PTL_History'
				ROLLBACK TRANSACTION
 
			SELECT ERROR_NUMBER() AS ErrorNumber
			SELECT ERROR_MESSAGE() AS ErrorMessage
 
		END CATCH	
		
		-- Keep a record of when creating a SCR_PTL_History snapshot dataset finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspCreateSomersetReportingHistory', @Step = 'Insert PTL History'
		
GO
