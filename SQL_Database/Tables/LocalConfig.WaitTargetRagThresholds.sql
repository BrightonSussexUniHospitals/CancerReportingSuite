CREATE TABLE [LocalConfig].[WaitTargetRagThresholds]
(
[WaitTargetRagThresholdId] [int] NOT NULL,
[WaitTargetId] [int] NULL,
[WaitTargetRagColourId] [int] NULL,
[WaitTargetRagThresholdGreaterThanValue] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [LocalConfig].[WaitTargetRagThresholds] ADD CONSTRAINT [PK_WaitTargetRagThresholds] PRIMARY KEY CLUSTERED  ([WaitTargetRagThresholdId]) ON [PRIMARY]
GO
