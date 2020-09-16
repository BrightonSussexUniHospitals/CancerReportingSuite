USE [CancerReporting]
GO
/****** Object:  Table [LocalConfig].[ReportingCwtPathwayType]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [LocalConfig].[ReportingCwtPathwayType](
	[CwtPathwayTypeId] [int] NOT NULL,
	[CwtPathwayTypeDesc] [varchar](255) NULL,
	[SortOrder] [int] NULL,
	[DefaultShow] [bit] NULL,
 CONSTRAINT [PK_ReportingCwtPathwayType] PRIMARY KEY CLUSTERED 
(
	[CwtPathwayTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
