USE [CancerReporting]
GO
/****** Object:  Table [LocalConfig].[ReportingCwtStatus]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [LocalConfig].[ReportingCwtStatus](
	[cwtStatusId] [int] NOT NULL,
	[cwtStatus] [varchar](255) NULL,
	[CwtPathwayTypeId] [int] NULL,
	[SortOrder] [int] NULL,
	[DefaultShow2WW] [bit] NULL,
	[DefaultShow28] [bit] NULL,
	[DefaultShow31] [bit] NULL,
	[DefaultShow62] [bit] NULL,
	[applicable2WW] [bit] NULL,
	[applicable28] [bit] NULL,
	[applicable31] [bit] NULL,
	[applicable62] [bit] NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_ReportingCwtStatus] PRIMARY KEY CLUSTERED 
(
	[cwtStatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
