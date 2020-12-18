CREATE TABLE [SCR_Warehouse].[ProcessAudit]
(
[Process] [varchar] (255) NOT NULL,
[Step] [varchar] (255) NOT NULL,
[LastStarted] [datetime] NULL,
[LastSuccessfullyCompleted] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Warehouse].[ProcessAudit] ADD CONSTRAINT [PK_ProcessAudit] PRIMARY KEY CLUSTERED  ([Process], [Step]) ON [PRIMARY]
GO
