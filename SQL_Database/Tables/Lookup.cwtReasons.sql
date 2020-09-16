USE [CancerReporting]
GO
/****** Object:  Table [Lookup].[cwtReasons]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Lookup].[cwtReasons](
	[cwtReasonID] [int] NOT NULL,
	[cwtFlagID] [int] NULL,
	[applicable2WW] [bit] NULL,
	[applicable28] [bit] NULL,
	[applicable31] [bit] NULL,
	[applicable62] [bit] NULL,
	[cwtReasonDesc] [varchar](255) NULL,
 CONSTRAINT [PK_cwtReasons] PRIMARY KEY CLUSTERED 
(
	[cwtReasonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
