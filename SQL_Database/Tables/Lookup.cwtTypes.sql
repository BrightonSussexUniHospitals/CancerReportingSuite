USE [CancerReporting]
GO
/****** Object:  Table [Lookup].[cwtTypes]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Lookup].[cwtTypes](
	[cwtTypeID] [int] NOT NULL,
	[cwtTypeDesc] [varchar](255) NULL,
	[cwtStandardId] [int] NULL,
	[cwtStandard_WaitTargetId] [int] NULL,
 CONSTRAINT [PK_cwtTypes] PRIMARY KEY CLUSTERED 
(
	[cwtTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
