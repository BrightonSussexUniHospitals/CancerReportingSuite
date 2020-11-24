CREATE TABLE [Lookup].[WaitTargetsOpenCwtMapping]
(
[WaitTargetId] [int] NOT NULL,
[cwtStandardId] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[WaitTargetsOpenCwtMapping] ADD CONSTRAINT [PK_WaitTargetsOpenCwtMapping] PRIMARY KEY CLUSTERED  ([WaitTargetId], [cwtStandardId]) ON [PRIMARY]
GO
