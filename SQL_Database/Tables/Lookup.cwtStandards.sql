USE [CancerReporting]
GO
/****** Object:  Table [Lookup].[cwtStandards]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Lookup].[cwtStandards](
	[cwtStandardId] [int] NOT NULL,
	[cwtStandardDesc] [varchar](255) NULL,
 CONSTRAINT [PK_cwtStandards] PRIMARY KEY CLUSTERED 
(
	[cwtStandardId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
