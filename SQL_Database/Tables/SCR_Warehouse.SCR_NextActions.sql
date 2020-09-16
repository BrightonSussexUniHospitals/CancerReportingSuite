USE [CancerReporting]
GO
/****** Object:  Table [SCR_Warehouse].[SCR_NextActions]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SCR_Warehouse].[SCR_NextActions](
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
	[ACTION_ID] [int] NULL,
	[LastUpdated] [datetime] NULL,
	[LastUpdatedBy] [varchar](255) NULL,
	[CareIdIx] [int] NULL,
	[CareIdRevIx] [int] NULL,
	[CareIdIncompleteIx] [int] NULL,
	[CareIdIncompleteRevIx] [int] NULL,
	[ReportDate] [datetime] NULL,
	[NextActionColourValue] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Index [CIX_NextAction]    Script Date: 03/09/2020 23:41:02 ******/
CREATE CLUSTERED INDEX [CIX_NextAction] ON [SCR_Warehouse].[SCR_NextActions]
(
	[PathwayUpdateEventID] DESC,
	[ACTION_ID] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Ix_CARE_ID]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_CARE_ID] ON [SCR_Warehouse].[SCR_NextActions]
(
	[CareID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
