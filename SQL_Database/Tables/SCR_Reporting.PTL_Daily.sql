CREATE TABLE [SCR_Reporting].[PTL_Daily]
(
[CARE_ID] [int] NOT NULL,
[CWT_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[Pathway] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CancerSiteBS] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Forename] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Surname] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[HospitalNumber] [varchar] (20) COLLATE Latin1_General_CI_AS NULL,
[NHSNumber] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[Waitingtime2WW] [int] NULL,
[Waitingtime28] [int] NULL,
[Waitingtime31] [int] NULL,
[Waitingtime62] [int] NULL,
[ReportingPathwayLength] [int] NULL,
[OrgCodeFirstSeen] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[OrgDescFirstSeen] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[TrackingNotes] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[DateLastTracked] [datetime] NULL,
[CommentUser] [varchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[DaysSinceLastTracked] [int] NULL,
[Weighting] [numeric] (2, 1) NULL,
[DominantCWTStatusCode] [int] NULL,
[CWTStatusCode2WW] [int] NULL,
[CWTStatusCode28] [int] NULL,
[CWTStatusCode31] [int] NULL,
[CWTStatusCode62] [int] NULL,
[DominantCWTStatusDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CWTStatusDesc2WW] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CWTStatusDesc28] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CWTStatusDesc31] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CWTStatusDesc62] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DaysToNextBreach] [int] NULL,
[NextBreachTarget] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[NextBreachDate] [datetime] NULL,
[DominantColourValue] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourValue2WW] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourValue28Day] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourValue31Day] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourValue62Day] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DominantColourDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourDesc2WW] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourDesc28Day] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourDesc31Day] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourDesc62Day] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DominantPriority] [int] NULL,
[Priority2WW] [int] NULL,
[Priority28] [int] NULL,
[Priority31] [int] NULL,
[Priority62] [int] NULL,
[cwtFlag2WW] [int] NULL,
[cwtFlag28] [int] NULL,
[cwtFlag31] [int] NULL,
[cwtFlag62] [int] NULL,
[PathwayUpdateEventID] [int] NULL,
[NextActionDesc] [varchar] (75) COLLATE Latin1_General_CI_AS NULL,
[NextActionSpecificDesc] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[NextActionTargetDate] [date] NULL,
[DaysToNextAction] [int] NULL,
[OwnerDesc] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[AdditionalDetails] [varchar] (55) COLLATE Latin1_General_CI_AS NULL,
[Escalated] [int] NULL,
[ReportDate] [datetime] NULL,
[PtlSnapshotDate] [datetime] NOT NULL,
[NextActionColourValue] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[EstimatedBreachMonth] [date] NULL,
[EstimatedWeight] [real] NULL,
[EBMonthValue] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NOT NULL,
[SSRS_PTLFlag62] [int] NOT NULL,
[NextActionId] [int] NULL,
[NextActionSpecificId] [int] NULL,
[OwnerId] [int] NULL,
[cwtType62] [int] NULL,
[DaysTo62DayBreach] [int] NULL,
[DeftDateDecisionTreat] [smalldatetime] NULL,
[SSRS_DTTFlag] [bit] NULL,
[WillBeWaitingtime2WW] [int] NULL,
[WillBeWaitingtime28] [int] NULL,
[WillBeWaitingtime31] [int] NULL,
[WillBeWaitingtime62] [int] NULL,
[ReportingcwtTypeID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Reporting].[PTL_Daily] ADD CONSTRAINT [PK_PTL_Daily] PRIMARY KEY CLUSTERED  ([CWT_ID]) ON [PRIMARY]
GO
