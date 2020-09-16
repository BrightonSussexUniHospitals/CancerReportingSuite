USE [CancerReporting]
GO
/****** Object:  Table [SCR_Reporting_History].[SCR_PTL_SnapshotDates]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SCR_Reporting_History].[SCR_PTL_SnapshotDates](
	[PtlSnapshotId] [int] IDENTITY(1,1) NOT NULL,
	[PtlSnapshotDate] [datetime] NOT NULL,
	[LoadedIntoLTChangeHistory] [bit] NOT NULL,
	[LoadedIntoStatistics] [bit] NOT NULL,
	[LoadedIntoLastPtlRecord] [bit] NOT NULL,
 CONSTRAINT [PK_SCR_PTL_SnapshotDates] PRIMARY KEY CLUSTERED 
(
	[PtlSnapshotId] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [UK_SCR_PTL_SnapshotDates]    Script Date: 03/09/2020 23:41:02 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UK_SCR_PTL_SnapshotDates] ON [SCR_Reporting_History].[SCR_PTL_SnapshotDates]
(
	[PtlSnapshotDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [SCR_Reporting_History].[SCR_PTL_SnapshotDates] ADD  DEFAULT (getdate()) FOR [PtlSnapshotDate]
GO
ALTER TABLE [SCR_Reporting_History].[SCR_PTL_SnapshotDates] ADD  DEFAULT ((0)) FOR [LoadedIntoLTChangeHistory]
GO
ALTER TABLE [SCR_Reporting_History].[SCR_PTL_SnapshotDates] ADD  DEFAULT ((0)) FOR [LoadedIntoStatistics]
GO
ALTER TABLE [SCR_Reporting_History].[SCR_PTL_SnapshotDates] ADD  DEFAULT ((0)) FOR [LoadedIntoLastPtlRecord]
GO
