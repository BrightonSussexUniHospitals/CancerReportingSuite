CREATE TABLE [Lookup].[WaitTargetRagColours]
(
[WaitTargetRagColourId] [int] NOT NULL,
[WaitTargetRagColourDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[WaitTargetRagColourValue] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[WaitTargetRagColourPriority] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[WaitTargetRagColours] ADD CONSTRAINT [PK_WaitTargetRagColours] PRIMARY KEY CLUSTERED  ([WaitTargetRagColourId]) ON [PRIMARY]
GO
