CREATE TABLE [SCR_Warehouse].[Workflow]
(
[IdentityTypeRecordId] [varchar] (255) NOT NULL,
[IdentityTypeId] [int] NOT NULL,
[WorkflowID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Warehouse].[Workflow] ADD CONSTRAINT [PK_Workflow] PRIMARY KEY CLUSTERED  ([IdentityTypeRecordId], [IdentityTypeId], [WorkflowID]) ON [PRIMARY]
GO
