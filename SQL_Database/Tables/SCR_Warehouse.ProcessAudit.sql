USE [CancerReporting]
GO
/****** Object:  Table [SCR_Warehouse].[ProcessAudit]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SCR_Warehouse].[ProcessAudit](
	[Process] [varchar](255) NOT NULL,
	[Step] [varchar](255) NOT NULL,
	[LastStarted] [datetime] NULL,
	[LastSuccessfullyCompleted] [datetime] NULL,
 CONSTRAINT [PK_ProcessAudit] PRIMARY KEY CLUSTERED 
(
	[Process] ASC,
	[Step] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
