CREATE TABLE [SCR_Warehouse].[SCR_NextActions_work]
(
[PathwayUpdateEventID] [int] NOT NULL,
[CareID] [int] NULL,
[NextActionID] [int] NULL,
[NextActionDesc] [varchar] (75) COLLATE Latin1_General_CI_AS NULL,
[NextActionSpecificID] [int] NULL,
[NextActionSpecificDesc] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[AdditionalDetails] [varchar] (55) COLLATE Latin1_General_CI_AS NULL,
[OwnerID] [int] NULL,
[OwnerDesc] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[OwnerRole] [varchar] (55) COLLATE Latin1_General_CI_AS NULL,
[OwnerName] [varchar] (55) COLLATE Latin1_General_CI_AS NULL,
[TargetDate] [date] NULL,
[Escalate] [int] NULL,
[OrganisationID] [int] NULL,
[OrganisationDesc] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[ActionComplete] [bit] NULL,
[Inserted] [datetime] NULL,
[InsertedBy] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ACTION_ID] [int] NULL,
[LastUpdated] [datetime] NULL,
[LastUpdatedBy] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CareIdIx] [int] NULL,
[CareIdRevIx] [int] NULL,
[CareIdIncompleteIx] [int] NULL,
[CareIdIncompleteRevIx] [int] NULL,
[ReportDate] [datetime] NULL,
[NextActionColourValue] [varchar] (50) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_CARE_ID_Work] ON [SCR_Warehouse].[SCR_NextActions_work] ([CareID]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [CIX_NextAction_work] ON [SCR_Warehouse].[SCR_NextActions_work] ([PathwayUpdateEventID] DESC, [ACTION_ID] DESC) ON [PRIMARY]
GO
