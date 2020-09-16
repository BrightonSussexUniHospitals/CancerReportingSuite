USE [CancerReporting]
GO
/****** Object:  Table [Lookup].[WaitTargets]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Lookup].[WaitTargets](
	[WaitTargetId] [int] NOT NULL,
	[WaitTargetDesc] [varchar](255) NULL,
	[WaitTargetDays] [int] NULL,
	[WaitTargetGroupId] [int] NULL,
	[WaitTargetPriority] [int] NOT NULL,
 CONSTRAINT [PK_WaitTargets] PRIMARY KEY CLUSTERED 
(
	[WaitTargetId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UK_WaitTargetPriority] UNIQUE NONCLUSTERED 
(
	[WaitTargetPriority] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
