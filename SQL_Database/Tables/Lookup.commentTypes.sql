USE [CancerReporting]
GO
/****** Object:  Table [Lookup].[commentTypes]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Lookup].[commentTypes](
	[commentTypeID] [int] NOT NULL,
	[commentTypeDesc] [varchar](255) NULL,
 CONSTRAINT [PK_commentTypes] PRIMARY KEY CLUSTERED 
(
	[commentTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
