USE [CancerReporting]
GO
/****** Object:  Table [LocalConfig].[PathwayLengthFilter]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [LocalConfig].[PathwayLengthFilter](
	[PathwayLengthFilterId] [int] NOT NULL,
	[PathwayLengthFilterName] [varchar](255) NOT NULL,
	[LowerBound] [int] NULL,
	[UpperBound] [int] NULL,
 CONSTRAINT [PK_PathwayLengthFilterId] PRIMARY KEY CLUSTERED 
(
	[PathwayLengthFilterId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
