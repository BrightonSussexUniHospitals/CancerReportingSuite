CREATE TABLE [LocalConfig].[ReportingWorkflows]
(
[WorkflowID] [int] NOT NULL,
[WorkflowDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[WorkflowSortOrder] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [LocalConfig].[ReportingWorkflows] ADD CONSTRAINT [PK_ReportingWorkflows] PRIMARY KEY CLUSTERED  ([WorkflowID]) ON [PRIMARY]
GO
