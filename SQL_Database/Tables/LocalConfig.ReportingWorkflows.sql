USE [CancerReporting]
GO
/****** Object:  Table [LocalConfig].[ReportingWorkflows]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [LocalConfig].[ReportingWorkflows](
	[WorkflowID] [int] NOT NULL,
	[WorkflowDesc] [varchar](255) NOT NULL,
	[WorkflowSortOrder] [int] NULL,
 CONSTRAINT [PK_ReportingWorkflows] PRIMARY KEY CLUSTERED 
(
	[WorkflowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
