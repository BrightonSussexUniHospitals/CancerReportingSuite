CREATE TABLE [SCR_Warehouse].[ProcessAudit]
(
[Process] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[Step] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[LastStarted] [datetime] NULL,
[LastSuccessfullyCompleted] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Warehouse].[ProcessAudit] ADD CONSTRAINT [PK_ProcessAudit] PRIMARY KEY CLUSTERED  ([Process], [Step]) ON [PRIMARY]
GO
