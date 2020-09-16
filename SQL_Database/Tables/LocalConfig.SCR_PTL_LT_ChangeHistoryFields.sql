USE [CancerReporting]
GO
/****** Object:  Table [LocalConfig].[SCR_PTL_LT_ChangeHistoryFields]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [LocalConfig].[SCR_PTL_LT_ChangeHistoryFields](
	[FieldNameId] [int] IDENTITY(1,1) NOT NULL,
	[FieldName] [varchar](255) NOT NULL,
	[FieldType] [varchar](255) NOT NULL,
	[Inactive] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Index [UK_SCR_PTL_LT_ChangeHistoryFields]    Script Date: 03/09/2020 23:41:02 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UK_SCR_PTL_LT_ChangeHistoryFields] ON [LocalConfig].[SCR_PTL_LT_ChangeHistoryFields]
(
	[FieldNameId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [LocalConfig].[SCR_PTL_LT_ChangeHistoryFields] ADD  DEFAULT ((0)) FOR [Inactive]
GO
