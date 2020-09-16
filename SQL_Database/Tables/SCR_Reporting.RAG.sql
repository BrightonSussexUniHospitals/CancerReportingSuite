USE [CancerReporting]
GO
/****** Object:  Table [SCR_Reporting].[RAG]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SCR_Reporting].[RAG](
	[CWT_ID] [varchar](255) NOT NULL,
	[DominantPriority] [int] NULL,
	[Priority2WW] [int] NULL,
	[Priority28] [int] NULL,
	[Priority31] [int] NULL,
	[Priority62] [int] NULL,
 CONSTRAINT [PK_RAG] PRIMARY KEY CLUSTERED 
(
	[CWT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
