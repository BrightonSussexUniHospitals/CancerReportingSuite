USE [CancerReporting]
GO
/****** Object:  Table [SCR_Reporting_History].[SCR_PTL_Statistics]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SCR_Reporting_History].[SCR_PTL_Statistics](
	[PtlSnapshotId] [int] NOT NULL,
	[StatisticsDimensionGroupId] [int] NOT NULL,
	[PtlRecordCount] [int] NOT NULL
) ON [PRIMARY]
GO
