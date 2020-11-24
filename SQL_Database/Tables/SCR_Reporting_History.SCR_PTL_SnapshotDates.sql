CREATE TABLE [SCR_Reporting_History].[SCR_PTL_SnapshotDates]
(
[PtlSnapshotId] [int] NOT NULL IDENTITY(1, 1),
[PtlSnapshotDate] [datetime] NOT NULL CONSTRAINT [DF__SCR_PTL_S__PtlSn__5535A963] DEFAULT (getdate()),
[LoadedIntoLTChangeHistory] [bit] NOT NULL CONSTRAINT [DF__SCR_PTL_S__Loade__5629CD9C] DEFAULT ((0)),
[LoadedIntoStatistics] [bit] NOT NULL CONSTRAINT [DF__SCR_PTL_S__Loade__571DF1D5] DEFAULT ((0)),
[LoadedIntoLastPtlRecord] [bit] NOT NULL CONSTRAINT [DF__SCR_PTL_S__Loade__5812160E] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Reporting_History].[SCR_PTL_SnapshotDates] ADD CONSTRAINT [PK_SCR_PTL_SnapshotDates] PRIMARY KEY CLUSTERED  ([PtlSnapshotId] DESC) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UK_SCR_PTL_SnapshotDates] ON [SCR_Reporting_History].[SCR_PTL_SnapshotDates] ([PtlSnapshotDate]) ON [PRIMARY]
GO
