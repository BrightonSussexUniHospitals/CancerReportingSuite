CREATE TABLE [SCR_Reporting_History].[SCR_PTL_History]
(
[CARE_ID] [int] NOT NULL,
[PatientPathwayID] [varchar] (20) COLLATE Latin1_General_CI_AS NULL,
[PatientPathwayIdIssuer] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[PATIENT_ID] [int] NULL CONSTRAINT [DF__SCR_PTL_H__PATIE__151B244E] DEFAULT ((0)),
[MainRefActionId] [int] NULL,
[DiagnosisActionId] [int] NULL,
[DemographicsActionId] [int] NULL,
[Forename] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Surname] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[DateBirth] [date] NULL,
[HospitalNumber] [varchar] (20) COLLATE Latin1_General_CI_AS NULL,
[NHSNumber] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[NHSNumberStatusCode] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[NstsStatus] [int] NULL,
[IsTemporaryNHSNumber] [int] NULL,
[DeathStatus] [int] NULL,
[DateDeath] [date] NULL,
[PctCode] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[PctDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[CcgCode] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[CcgDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[CancerSite] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[CancerSiteBS] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[CancerSubSiteCode] [int] NULL,
[CancerSubSiteDesc] [varchar] (25) COLLATE Latin1_General_CI_AS NULL,
[ReferralCancerSiteCode] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[ReferralCancerSiteDesc] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[ReferralCancerSiteBS] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[CancerTypeCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[CancerTypeDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[PriorityTypeCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[PriorityTypeDesc] [varchar] (13) COLLATE Latin1_General_CI_AS NULL,
[SourceReferralCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[SourceReferralDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[ReferralMethodCode] [int] NULL,
[DecisionToReferDate] [smalldatetime] NULL,
[TumourStatusCode] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[TumourStatusDesc] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[PatientStatusCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[PatientStatusDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[PatientStatusCodeCwt] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[PatientStatusDescCwt] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[ConsultantCode] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[ConsultantName] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[InappropriateRef] [int] NULL,
[TransferReason] [int] NULL,
[TransferNewRefDate] [smalldatetime] NULL,
[TransferTumourSiteCode] [int] NULL,
[TransferTumourSiteDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[TransferActionedDate] [smalldatetime] NULL,
[TransferSourceCareId] [int] NULL,
[TransferOrigSourceCareId] [int] NULL,
[FastDiagInformedDate] [smalldatetime] NULL,
[FastDiagExclDate] [datetime] NULL,
[FastDiagCancerSiteID] [int] NULL,
[FastDiagCancerSiteOverrideID] [int] NULL,
[FastDiagCancerSiteCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[FastDiagCancerSiteDesc] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[FastDiagEndReasonID] [int] NULL,
[FastDiagEndReasonCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[FastDiagEndReasonDesc] [varchar] (25) COLLATE Latin1_General_CI_AS NULL,
[FastDiagDelayReasonID] [int] NULL,
[FastDiagDelayReasonCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[FastDiagDelayReasonDesc] [varchar] (160) COLLATE Latin1_General_CI_AS NULL,
[FastDiagDelayReasonComments] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[FastDiagExclReasonID] [int] NULL,
[FastDiagExclReasonCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[FastDiagExclReasonDesc] [varchar] (80) COLLATE Latin1_General_CI_AS NULL,
[FastDiagOrgID] [int] NULL,
[FastDiagOrgCode] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[FastDiagOrgDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[FastDiagCommMethodID] [int] NULL,
[FastDiagCommMethodCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[FastDiagCommMethodDesc] [varchar] (30) COLLATE Latin1_General_CI_AS NULL,
[FastDiagOtherCommMethod] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[FastDiagInformingCareProfID] [int] NULL,
[FastDiagInformingCareProfCode] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[FastDiagInformingCareProfDesc] [varchar] (70) COLLATE Latin1_General_CI_AS NULL,
[FastDiagOtherCareProf] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[FDPlannedInterval] [bit] NULL,
[DateDiagnosis] [smalldatetime] NULL,
[AgeAtDiagnosis] [int] NULL,
[DiagnosisCode] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[DiagnosisSubCode] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[DiagnosisDesc] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[DiagnosisSubDesc] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[SnomedCT_ID] [int] NULL,
[SnomedCT_MCode] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[SnomedCT_ConceptID] [bigint] NULL,
[SnomedCT_Desc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[Histology] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[DateReceipt] [smalldatetime] NULL,
[AgeAtReferral] [int] NULL,
[AppointmentCancelledDate] [smalldatetime] NULL,
[DateConsultantUpgrade] [smalldatetime] NULL,
[DateFirstSeen] [smalldatetime] NULL,
[OrgIdUpgrade] [int] NULL,
[OrgCodeUpgrade] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[OrgDescUpgrade] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[OrgIdFirstSeen] [int] NULL,
[OrgCodeFirstSeen] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[OrgDescFirstSeen] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[FirstAppointmentTypeCode] [int] NULL,
[FirstAppointmentTypeDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FirstAppointmentOffered] [int] NULL,
[ReasonNoAppointmentCode] [int] NULL,
[ReasonNoAppointmentDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FirstSeenAdjTime] [int] NULL,
[FirstSeenAdjReasonCode] [int] NULL,
[FirstSeenAdjReasonDesc] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[FirstSeenDelayReasonCode] [int] NULL,
[FirstSeenDelayReasonDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FirstSeenDelayReasonComment] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[DTTAdjTime] [int] NULL,
[DTTAdjReasonCode] [int] NULL,
[DTTAdjReasonDesc] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[IsBCC] [int] NULL,
[IsCwtCancerDiagnosis] [int] NULL,
[UnderCancerCareFlag] [int] NULL,
[RefreshMaxActionDate] [datetime] NULL,
[ReferralReportDate] [datetime] NULL,
[CWTInsertIx] [int] NOT NULL,
[OriginalCWTInsertIx] [int] NULL,
[CWT_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL CONSTRAINT [DF__SCR_PTL_H__CWT_I__160F4887] DEFAULT (''),
[Tx_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL CONSTRAINT [DF__SCR_PTL_H__Tx_ID__17036CC0] DEFAULT (''),
[TREATMENT_ID] [int] NULL,
[TREAT_ID] [int] NULL,
[CHEMO_ID] [int] NULL,
[TELE_ID] [int] NULL,
[PALL_ID] [int] NULL,
[BRACHY_ID] [int] NULL,
[OTHER_ID] [int] NULL,
[SURGERY_ID] [int] NULL,
[MONITOR_ID] [int] NULL,
[ChemoActionId] [int] NULL,
[TeleActionId] [int] NULL,
[PallActionId] [int] NULL,
[BrachyActionId] [int] NULL,
[OtherActionId] [int] NULL,
[SurgeryActionId] [int] NULL,
[MonitorActionId] [int] NULL,
[DeftTreatmentEventCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[DeftTreatmentEventDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[DeftTreatmentCode] [char] (2) COLLATE Latin1_General_CI_AS NULL,
[DeftTreatmentDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[DeftTreatmentSettingCode] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[DeftTreatmentSettingDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[DeftDateDecisionTreat] [smalldatetime] NULL,
[DeftDateTreatment] [smalldatetime] NULL,
[DeftDTTAdjTime] [int] NULL,
[DeftDTTAdjReasonCode] [int] NULL,
[DeftDTTAdjReasonDesc] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[DeftOrgIdDecisionTreat] [int] NULL,
[DeftOrgCodeDecisionTreat] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[DeftOrgDescDecisionTreat] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[DeftOrgIdTreatment] [int] NULL,
[DeftOrgCodeTreatment] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[DeftOrgDescTreatment] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[DeftDefinitiveTreatment] [int] NULL,
[DeftChemoRT] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TxModTreatmentEventCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TxModTreatmentEventDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[TxModTreatmentCode] [char] (2) COLLATE Latin1_General_CI_AS NULL,
[TxModTreatmentDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[TxModTreatmentSettingCode] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[TxModTreatmentSettingDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[TxModDateDecisionTreat] [smalldatetime] NULL,
[TxModDateTreatment] [smalldatetime] NULL,
[TxModOrgIdDecisionTreat] [int] NULL,
[TxModOrgCodeDecisionTreat] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[TxModOrgDescDecisionTreat] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[TxModOrgIdTreatment] [int] NULL,
[TxModOrgCodeTreatment] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[TxModOrgDescTreatment] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[TxModDefinitiveTreatment] [int] NULL,
[TxModChemoRadio] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TxModChemoRT] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TxModModalitySubCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TxModRadioSurgery] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkTreatmentEventCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkTreatmentEventDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkTreatmentCode] [char] (2) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkTreatmentDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkTreatmentSettingCode] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkTreatmentSettingDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkDateDecisionTreat] [smalldatetime] NULL,
[ChemRtLinkDateTreatment] [smalldatetime] NULL,
[ChemRtLinkOrgIdDecisionTreat] [int] NULL,
[ChemRtLinkOrgCodeDecisionTreat] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkOrgDescDecisionTreat] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkOrgIdTreatment] [int] NULL,
[ChemRtLinkOrgCodeTreatment] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkOrgDescTreatment] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkDefinitiveTreatment] [int] NULL,
[ChemRtLinkChemoRadio] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkModalitySubCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkRadioSurgery] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[cwtFlag2WW] [int] NULL,
[cwtFlag28] [int] NULL,
[cwtFlag31] [int] NULL,
[cwtFlag62] [int] NULL,
[cwtType2WW] [int] NULL,
[cwtType28] [int] NULL,
[cwtType31] [int] NULL,
[cwtType62] [int] NULL,
[cwtReason2WW] [int] NULL,
[cwtReason28] [int] NULL,
[cwtReason31] [int] NULL,
[cwtReason62] [int] NULL,
[HasTxMod] [int] NULL CONSTRAINT [DF__SCR_PTL_H__HasTx__17F790F9] DEFAULT ((0)),
[HasChemRtLink] [int] NULL CONSTRAINT [DF__SCR_PTL_H__HasCh__18EBB532] DEFAULT ((0)),
[ClockStartDate2WW] [smalldatetime] NULL,
[ClockStartDate28] [smalldatetime] NULL,
[ClockStartDate31] [smalldatetime] NULL,
[ClockStartDate62] [smalldatetime] NULL,
[AdjTime2WW] [int] NULL,
[AdjTime28] [int] NULL,
[AdjTime31] [int] NULL,
[AdjTime62] [int] NULL,
[TargetDate2WW] [smalldatetime] NULL,
[TargetDate28] [smalldatetime] NULL,
[TargetDate31] [smalldatetime] NULL,
[TargetDate62] [smalldatetime] NULL,
[DaysTo2WWBreach] [int] NULL,
[DaysTo28DayBreach] [int] NULL,
[DaysTo31DayBreach] [int] NULL,
[DaysTo62DayBreach] [int] NULL,
[ClockStopDate2WW] [smalldatetime] NULL,
[ClockStopDate28] [smalldatetime] NULL,
[ClockStopDate31] [smalldatetime] NULL,
[ClockStopDate62] [smalldatetime] NULL,
[Waitingtime2WW] [int] NULL,
[Waitingtime28] [int] NULL,
[Waitingtime31] [int] NULL,
[Waitingtime62] [int] NULL,
[Breach2WW] [int] NULL,
[Breach28] [int] NULL,
[Breach31] [int] NULL,
[Breach62] [int] NULL,
[DaysTo62DayBreachNoDTT] [int] NULL,
[Treated7Days] [int] NULL,
[Treated7Days62Days] [int] NULL,
[FutureAchieve62Days] [int] NULL,
[FutureFail62Days] [int] NULL,
[ActualWaitDTTTreatment] [int] NULL,
[DTTTreated7Days] [int] NULL,
[Treated7Days31Days] [int] NULL,
[Treated7DaysBreach31Days] [int] NULL,
[FutureAchieve31Days] [int] NULL,
[FutureFail31Days] [int] NULL,
[FutureDTT] [int] NULL,
[NoDTTDate] [int] NULL,
[LastCommentUser] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[LastCommentDate] [datetime] NULL,
[CwtReportDate] [datetime] NULL,
[Pathway] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[TrackingNotes] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[DateLastTracked] [datetime] NULL,
[CommentUser] [varchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[DaysSinceLastTracked] [int] NULL,
[Weighting] [numeric] (2, 1) NOT NULL,
[DaysToNextBreach] [int] NULL,
[NextBreachTarget] [varchar] (17) COLLATE Latin1_General_CI_AS NOT NULL,
[NextBreachDate] [smalldatetime] NULL,
[DominantColourValue] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[ColourValue2WW] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[ColourValue28Day] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[ColourValue31Day] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[ColourValue62Day] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[DominantColourDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[ColourDesc2WW] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[ColourDesc28Day] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[ColourDesc31Day] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[ColourDesc62Day] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[DominantPriority] [int] NULL,
[Priority2WW] [int] NULL,
[Priority28] [int] NULL,
[Priority31] [int] NULL,
[Priority62] [int] NULL,
[PathwayUpdateEventID] [int] NULL,
[NextActionDesc] [varchar] (75) COLLATE Latin1_General_CI_AS NULL,
[NextActionSpecificDesc] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[NextActionTargetDate] [date] NULL,
[DaysToNextAction] [int] NULL,
[OwnerDesc] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[AdditionalDetails] [varchar] (55) COLLATE Latin1_General_CI_AS NULL,
[Escalated] [int] NULL,
[ReportingPathwayLength] [int] NULL,
[DominantCWTStatusCode] [int] NULL,
[DominantCWTStatusDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CWTStatusCode2WW] [int] NULL,
[CWTStatusDesc2WW] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CWTStatusCode28] [int] NULL,
[CWTStatusDesc28] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CWTStatusCode31] [int] NULL,
[CWTStatusDesc31] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CWTStatusCode62] [int] NULL,
[CWTStatusDesc62] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SSRS_PTLFlag62] [int] NULL,
[OrgIdDiagnosis] [int] NULL,
[OrgCodeDiagnosis] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[OrgDescDiagnosis] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[PtlSnapshotId] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Reporting_History].[SCR_PTL_History] ADD CONSTRAINT [PK_SCR_PTL_History] PRIMARY KEY CLUSTERED  ([PtlSnapshotId] DESC, [CWT_ID] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_CARE_ID] ON [SCR_Reporting_History].[SCR_PTL_History] ([CARE_ID] DESC) ON [PRIMARY]
GO
