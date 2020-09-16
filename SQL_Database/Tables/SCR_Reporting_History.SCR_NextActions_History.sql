USE [CancerReporting]
GO
/****** Object:  Table [SCR_Reporting_History].[SCR_NextActions_History]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SCR_Reporting_History].[SCR_NextActions_History](
	[PathwayUpdateEventID] [int] NOT NULL,
	[CareID] [int] NULL,
	[NextActionID] [int] NULL,
	[NextActionDesc] [varchar](75) NULL,
	[NextActionSpecificID] [int] NULL,
	[NextActionSpecificDesc] [varchar](50) NULL,
	[AdditionalDetails] [varchar](55) NULL,
	[OwnerID] [int] NULL,
	[OwnerDesc] [varchar](50) NULL,
	[OwnerRole] [varchar](55) NULL,
	[OwnerName] [varchar](55) NULL,
	[TargetDate] [date] NULL,
	[Escalate] [int] NULL,
	[OrganisationID] [int] NULL,
	[OrganisationDesc] [varchar](250) NULL,
	[ActionComplete] [bit] NULL,
	[Inserted] [datetime] NULL,
	[InsertedBy] [varchar](255) NULL,
	[ACTION_ID] [int] NOT NULL,
	[LastUpdated] [datetime] NULL,
	[LastUpdatedBy] [varchar](255) NULL,
	[ReportDate] [datetime] NULL,
	[UpdateIx] [int] NULL,
	[UpdateRevIx] [int] NULL,
	[NextActionColourValue] [varchar](50) NULL,
 CONSTRAINT [PK_NextAction_History] PRIMARY KEY CLUSTERED 
(
	[PathwayUpdateEventID] DESC,
	[ACTION_ID] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [Ix_CARE_ID]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_CARE_ID] ON [SCR_Reporting_History].[SCR_NextActions_History]
(
	[CareID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Ix_LastUpdated]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_LastUpdated] ON [SCR_Reporting_History].[SCR_NextActions_History]
(
	[LastUpdated] ASC,
	[UpdateIx] ASC,
	[UpdateRevIx] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
