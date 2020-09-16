USE [CancerReporting]
GO
/****** Object:  Table [Lookup].[WaitTargetRagColours]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Lookup].[WaitTargetRagColours](
	[WaitTargetRagColourId] [int] NOT NULL,
	[WaitTargetRagColourDesc] [varchar](255) NULL,
	[WaitTargetRagColourValue] [varchar](255) NULL,
	[WaitTargetRagColourPriority] [int] NULL,
 CONSTRAINT [PK_WaitTargetRagColours] PRIMARY KEY CLUSTERED 
(
	[WaitTargetRagColourId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
