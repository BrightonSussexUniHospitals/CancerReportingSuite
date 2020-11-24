CREATE TABLE [SCR_Warehouse].[Workflow]
(
[CWT_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[WorkflowID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Warehouse].[Workflow] ADD CONSTRAINT [PK_Workflow] PRIMARY KEY CLUSTERED  ([CWT_ID], [WorkflowID]) ON [PRIMARY]
GO
