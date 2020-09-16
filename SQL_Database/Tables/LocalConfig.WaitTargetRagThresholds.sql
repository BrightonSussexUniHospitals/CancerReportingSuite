USE [CancerReporting]
GO
/****** Object:  Table [LocalConfig].[WaitTargetRagThresholds]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [LocalConfig].[WaitTargetRagThresholds](
	[WaitTargetRagThresholdId] [int] NOT NULL,
	[WaitTargetId] [int] NULL,
	[WaitTargetRagColourId] [int] NULL,
	[WaitTargetRagThresholdGreaterThanValue] [int] NULL,
 CONSTRAINT [PK_WaitTargetRagThresholds] PRIMARY KEY CLUSTERED 
(
	[WaitTargetRagThresholdId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
