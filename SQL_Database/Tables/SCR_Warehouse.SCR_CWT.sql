USE [CancerReporting]
GO
/****** Object:  Table [SCR_Warehouse].[SCR_CWT]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SCR_Warehouse].[SCR_CWT](
	[CWTInsertIx] [int] IDENTITY(1,1) NOT NULL,
	[OriginalCWTInsertIx] [int] NULL,
	[CARE_ID] [int] NOT NULL,
	[CWT_ID] [varchar](255) NOT NULL,
	[Tx_ID] [varchar](255) NOT NULL,
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
	[DeftTreatmentEventCode] [varchar](2) NULL,
	[DeftTreatmentEventDesc] [varchar](100) NULL,
	[DeftTreatmentCode] [char](2) NULL,
	[DeftTreatmentDesc] [varchar](100) NULL,
	[DeftTreatmentSettingCode] [varchar](50) NULL,
	[DeftTreatmentSettingDesc] [varchar](100) NULL,
	[DeftDateDecisionTreat] [smalldatetime] NULL,
	[DeftDateTreatment] [smalldatetime] NULL,
	[DeftDTTAdjTime] [int] NULL,
	[DeftDTTAdjReasonCode] [int] NULL,
	[DeftDTTAdjReasonDesc] [varchar](150) NULL,
	[DeftOrgIdDecisionTreat] [int] NULL,
	[DeftOrgCodeDecisionTreat] [varchar](5) NULL,
	[DeftOrgDescDecisionTreat] [varchar](250) NULL,
	[DeftOrgIdTreatment] [int] NULL,
	[DeftOrgCodeTreatment] [varchar](5) NULL,
	[DeftOrgDescTreatment] [varchar](250) NULL,
	[DeftDefinitiveTreatment] [int] NULL,
	[DeftChemoRT] [varchar](2) NULL,
	[TxModTreatmentEventCode] [varchar](2) NULL,
	[TxModTreatmentEventDesc] [varchar](100) NULL,
	[TxModTreatmentCode] [char](2) NULL,
	[TxModTreatmentDesc] [varchar](100) NULL,
	[TxModTreatmentSettingCode] [varchar](50) NULL,
	[TxModTreatmentSettingDesc] [varchar](100) NULL,
	[TxModDateDecisionTreat] [smalldatetime] NULL,
	[TxModDateTreatment] [smalldatetime] NULL,
	[TxModOrgIdDecisionTreat] [int] NULL,
	[TxModOrgCodeDecisionTreat] [varchar](5) NULL,
	[TxModOrgDescDecisionTreat] [varchar](250) NULL,
	[TxModOrgIdTreatment] [int] NULL,
	[TxModOrgCodeTreatment] [varchar](5) NULL,
	[TxModOrgDescTreatment] [varchar](250) NULL,
	[TxModDefinitiveTreatment] [int] NULL,
	[TxModChemoRadio] [varchar](2) NULL,
	[TxModChemoRT] [varchar](2) NULL,
	[TxModModalitySubCode] [varchar](2) NULL,
	[TxModRadioSurgery] [varchar](2) NULL,
	[ChemRtLinkTreatmentEventCode] [varchar](2) NULL,
	[ChemRtLinkTreatmentEventDesc] [varchar](100) NULL,
	[ChemRtLinkTreatmentCode] [char](2) NULL,
	[ChemRtLinkTreatmentDesc] [varchar](100) NULL,
	[ChemRtLinkTreatmentSettingCode] [varchar](50) NULL,
	[ChemRtLinkTreatmentSettingDesc] [varchar](100) NULL,
	[ChemRtLinkDateDecisionTreat] [smalldatetime] NULL,
	[ChemRtLinkDateTreatment] [smalldatetime] NULL,
	[ChemRtLinkOrgIdDecisionTreat] [int] NULL,
	[ChemRtLinkOrgCodeDecisionTreat] [varchar](5) NULL,
	[ChemRtLinkOrgDescDecisionTreat] [varchar](250) NULL,
	[ChemRtLinkOrgIdTreatment] [int] NULL,
	[ChemRtLinkOrgCodeTreatment] [varchar](5) NULL,
	[ChemRtLinkOrgDescTreatment] [varchar](250) NULL,
	[ChemRtLinkDefinitiveTreatment] [int] NULL,
	[ChemRtLinkChemoRadio] [varchar](2) NULL,
	[ChemRtLinkModalitySubCode] [varchar](2) NULL,
	[ChemRtLinkRadioSurgery] [varchar](2) NULL,
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
	[HasTxMod] [int] NULL,
	[HasChemRtLink] [int] NULL,
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
	[WillBeClockStopDate2WW] [smalldatetime] NULL,
	[WillBeClockStopDate28] [smalldatetime] NULL,
	[WillBeClockStopDate31] [smalldatetime] NULL,
	[WillBeClockStopDate62] [smalldatetime] NULL,
	[WillBeWaitingtime2WW] [int] NULL,
	[WillBeWaitingtime28] [int] NULL,
	[WillBeWaitingtime31] [int] NULL,
	[WillBeWaitingtime62] [int] NULL,
	[WillBeBreach2WW] [int] NULL,
	[WillBeBreach28] [int] NULL,
	[WillBeBreach31] [int] NULL,
	[WillBeBreach62] [int] NULL,
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
	[LastCommentUser] [varchar](50) NULL,
	[LastCommentDate] [datetime] NULL,
	[ReportDate] [datetime] NULL,
	[DominantCWTStatusCode] [int] NULL,
	[DominantCWTStatusDesc] [varchar](255) NULL,
	[CWTStatusCode2WW] [int] NULL,
	[CWTStatusDesc2WW] [varchar](255) NULL,
	[CWTStatusCode28] [int] NULL,
	[CWTStatusDesc28] [varchar](255) NULL,
	[CWTStatusCode31] [int] NULL,
	[CWTStatusDesc31] [varchar](255) NULL,
	[CWTStatusCode62] [int] NULL,
	[CWTStatusDesc62] [varchar](255) NULL,
	[Pathway] [varchar](255) NULL,
	[ReportingPathwayLength] [int] NULL,
	[Weighting] [numeric](2, 1) NULL,
	[DominantColourValue] [varchar](255) NULL,
	[ColourValue2WW] [varchar](255) NULL,
	[ColourValue28Day] [varchar](255) NULL,
	[ColourValue31Day] [varchar](255) NULL,
	[ColourValue62Day] [varchar](255) NULL,
	[DominantColourDesc] [varchar](255) NULL,
	[ColourDesc2WW] [varchar](255) NULL,
	[ColourDesc28Day] [varchar](255) NULL,
	[ColourDesc31Day] [varchar](255) NULL,
	[ColourDesc62Day] [varchar](255) NULL,
	[DominantPriority] [int] NULL,
	[Priority2WW] [int] NULL,
	[Priority28] [int] NULL,
	[Priority31] [int] NULL,
	[Priority62] [int] NULL,
 CONSTRAINT [PK_SCR_CWT] PRIMARY KEY CLUSTERED 
(
	[CWT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [Ix_CARE_ID]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_CARE_ID] ON [SCR_Warehouse].[SCR_CWT]
(
	[CARE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Ix_cwtFlag28]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_cwtFlag28] ON [SCR_Warehouse].[SCR_CWT]
(
	[cwtFlag28] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Ix_cwtFlag2WW]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_cwtFlag2WW] ON [SCR_Warehouse].[SCR_CWT]
(
	[cwtFlag2WW] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Ix_cwtFlag31]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_cwtFlag31] ON [SCR_Warehouse].[SCR_CWT]
(
	[cwtFlag31] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Ix_cwtFlag62]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_cwtFlag62] ON [SCR_Warehouse].[SCR_CWT]
(
	[cwtFlag62] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [Ix_TxMod]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_TxMod] ON [SCR_Warehouse].[SCR_CWT]
(
	[CARE_ID] ASC,
	[TREAT_ID] ASC,
	[DeftTreatmentCode] ASC,
	[DeftChemoRT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [SCR_Warehouse].[SCR_CWT] ADD  DEFAULT ('') FOR [CWT_ID]
GO
ALTER TABLE [SCR_Warehouse].[SCR_CWT] ADD  DEFAULT ('') FOR [Tx_ID]
GO
ALTER TABLE [SCR_Warehouse].[SCR_CWT] ADD  DEFAULT ((0)) FOR [HasTxMod]
GO
ALTER TABLE [SCR_Warehouse].[SCR_CWT] ADD  DEFAULT ((0)) FOR [HasChemRtLink]
GO
