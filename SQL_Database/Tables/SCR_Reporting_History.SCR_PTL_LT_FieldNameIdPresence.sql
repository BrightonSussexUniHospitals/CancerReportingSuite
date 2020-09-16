USE [CancerReporting]
GO
/****** Object:  Table [SCR_Reporting_History].[SCR_PTL_LT_FieldNameIdPresence]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SCR_Reporting_History].[SCR_PTL_LT_FieldNameIdPresence](
	[PtlSnapshotId] [int] NOT NULL,
	[FieldNameId] [varchar](255) NOT NULL,
 CONSTRAINT [PK_SCR_PTL_LT_FieldNameIdPresence] PRIMARY KEY CLUSTERED 
(
	[PtlSnapshotId] ASC,
	[FieldNameId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
