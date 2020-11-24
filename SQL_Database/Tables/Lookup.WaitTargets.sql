CREATE TABLE [Lookup].[WaitTargets]
(
[WaitTargetId] [int] NOT NULL,
[WaitTargetDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[WaitTargetDays] [int] NULL,
[WaitTargetGroupId] [int] NULL,
[WaitTargetPriority] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[WaitTargets] ADD CONSTRAINT [PK_WaitTargets] PRIMARY KEY CLUSTERED  ([WaitTargetId]) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[WaitTargets] ADD CONSTRAINT [UK_WaitTargetPriority] UNIQUE NONCLUSTERED  ([WaitTargetPriority]) ON [PRIMARY]
GO
