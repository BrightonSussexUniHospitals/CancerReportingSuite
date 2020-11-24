CREATE TABLE [SCR_Warehouse].[ProcessAuditHistory]
(
[ProcessAuditHistoryId] [int] NOT NULL IDENTITY(1, 1),
[Process] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[Step] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[LastStarted] [datetime] NULL,
[LastSuccessfullyCompleted] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Warehouse].[ProcessAuditHistory] ADD CONSTRAINT [PK_ProcessAuditHistory] PRIMARY KEY CLUSTERED  ([ProcessAuditHistoryId]) ON [PRIMARY]
GO
