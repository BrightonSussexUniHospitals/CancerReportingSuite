USE [CancerReporting]
GO
/****** Object:  Table [SCR_Reporting_History].[SCR_PTL_LT_ChangeHistory]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SCR_Reporting_History].[SCR_PTL_LT_ChangeHistory](
	[PtlSnapshotId_Start] [int] NOT NULL,
	[CWT_ID] [varchar](255) NOT NULL,
	[FieldNameId] [int] NOT NULL,
	[FieldValueInt] [real] NULL,
	[FieldValueString] [varchar](max) NULL,
	[FieldValueDatetime] [datetime2](7) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UK_SCR_PTL_LT_ChangeHistory]    Script Date: 03/09/2020 23:41:02 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UK_SCR_PTL_LT_ChangeHistory] ON [SCR_Reporting_History].[SCR_PTL_LT_ChangeHistory]
(
	[FieldNameId] DESC,
	[PtlSnapshotId_Start] DESC,
	[CWT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
