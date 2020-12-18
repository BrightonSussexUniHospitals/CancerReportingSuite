CREATE TABLE [SCR_Warehouse].[SCR_NextActions]
(
[PathwayUpdateEventID] [int] NOT NULL,
[CareID] [int] NULL,
[NextActionID] [int] NULL,
[NextActionDesc] [varchar] (75) NULL,
[NextActionSpecificID] [int] NULL,
[NextActionSpecificDesc] [varchar] (50) NULL,
[AdditionalDetails] [varchar] (55) NULL,
[OwnerID] [int] NULL,
[OwnerDesc] [varchar] (50) NULL,
[OwnerRole] [varchar] (55) NULL,
[OwnerName] [varchar] (55) NULL,
[TargetDate] [date] NULL,
[Escalate] [int] NULL,
[OrganisationID] [int] NULL,
[OrganisationDesc] [varchar] (250) NULL,
[ActionComplete] [bit] NULL,
[Inserted] [datetime] NULL,
[InsertedBy] [varchar] (255) NULL,
[ACTION_ID] [int] NULL,
[LastUpdated] [datetime] NULL,
[LastUpdatedBy] [varchar] (255) NULL,
[CareIdIx] [int] NULL,
[CareIdRevIx] [int] NULL,
[CareIdIncompleteIx] [int] NULL,
[CareIdIncompleteRevIx] [int] NULL,
[ReportDate] [datetime] NULL,
[NextActionColourValue] [varchar] (50) NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_CARE_ID] ON [SCR_Warehouse].[SCR_NextActions] ([CareID]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [CIX_NextAction] ON [SCR_Warehouse].[SCR_NextActions] ([PathwayUpdateEventID] DESC, [ACTION_ID] DESC) ON [PRIMARY]
GO
