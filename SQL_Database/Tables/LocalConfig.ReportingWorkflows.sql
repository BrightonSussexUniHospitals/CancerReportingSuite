CREATE TABLE [LocalConfig].[ReportingWorkflows]
(
[WorkflowID] [int] NOT NULL,
[WorkflowDesc] [varchar] (255) NOT NULL,
[WorkflowSortOrder] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [LocalConfig].[ReportingWorkflows] ADD CONSTRAINT [PK_ReportingWorkflows] PRIMARY KEY CLUSTERED  ([WorkflowID]) ON [PRIMARY]
GO
