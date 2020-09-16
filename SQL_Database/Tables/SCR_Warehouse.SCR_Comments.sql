USE [CancerReporting]
GO
/****** Object:  Table [SCR_Warehouse].[SCR_Comments]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SCR_Warehouse].[SCR_Comments](
	[SourceRecordId] [varchar](255) NOT NULL,
	[SourceTableName] [varchar](255) NOT NULL,
	[SourceColumnName] [varchar](255) NOT NULL,
	[CARE_ID] [int] NOT NULL,
	[Comment] [varchar](max) NULL,
	[CommentUser] [varchar](50) NULL,
	[CommentDate] [datetime] NULL,
	[CommentType] [int] NULL,
	[CareIdIx] [int] NULL,
	[CareIdRevIx] [int] NULL,
	[CommentTypeCareIdIx] [int] NULL,
	[CommentTypeCareIdRevIx] [int] NULL,
	[ReportDate] [datetime] NULL,
 CONSTRAINT [PK_SCR_Comments] PRIMARY KEY CLUSTERED 
(
	[SourceRecordId] ASC,
	[SourceTableName] ASC,
	[SourceColumnName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Index [Ix_CARE_ID]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_CARE_ID] ON [SCR_Warehouse].[SCR_Comments]
(
	[CARE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Ix_CommentTypeCareIdIx]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_CommentTypeCareIdIx] ON [SCR_Warehouse].[SCR_Comments]
(
	[CARE_ID] ASC,
	[CommentTypeCareIdIx] ASC,
	[CommentType] ASC
)
INCLUDE([Comment],[CommentDate]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Ix_PTL_Live]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_PTL_Live] ON [SCR_Warehouse].[SCR_Comments]
(
	[CommentType] ASC,
	[CommentTypeCareIdRevIx] ASC,
	[CARE_ID] ASC
)
INCLUDE([Comment],[CommentUser]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
