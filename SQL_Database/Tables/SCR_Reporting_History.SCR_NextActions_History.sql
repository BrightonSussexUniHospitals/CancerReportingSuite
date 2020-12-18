CREATE TABLE [SCR_Reporting_History].[SCR_NextActions_History]
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
[ACTION_ID] [int] NOT NULL,
[LastUpdated] [datetime] NULL,
[LastUpdatedBy] [varchar] (255) NULL,
[ReportDate] [datetime] NULL,
[UpdateIx] [int] NULL,
[UpdateRevIx] [int] NULL,
[NextActionColourValue] [varchar] (50) NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Reporting_History].[SCR_NextActions_History] ADD CONSTRAINT [PK_NextAction_History] PRIMARY KEY CLUSTERED  ([PathwayUpdateEventID] DESC, [ACTION_ID] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_CARE_ID] ON [SCR_Reporting_History].[SCR_NextActions_History] ([CareID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_LastUpdated] ON [SCR_Reporting_History].[SCR_NextActions_History] ([LastUpdated], [UpdateIx], [UpdateRevIx] DESC) ON [PRIMARY]
GO
