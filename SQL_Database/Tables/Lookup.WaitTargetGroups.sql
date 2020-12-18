CREATE TABLE [Lookup].[WaitTargetGroups]
(
[WaitTargetGroupId] [int] NOT NULL,
[WaitTargetGroupDesc] [varchar] (255) NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[WaitTargetGroups] ADD CONSTRAINT [PK_WaitTargetGroups] PRIMARY KEY CLUSTERED  ([WaitTargetGroupId]) ON [PRIMARY]
GO
