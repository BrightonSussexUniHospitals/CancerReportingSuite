CREATE TABLE [SCR_Reporting_History].[SCR_PTL_SnapshotDates]
(
[PtlSnapshotId] [int] NOT NULL IDENTITY(1, 1),
[PtlSnapshotDate] [datetime] NOT NULL CONSTRAINT [DF__SCR_PTL_S__PtlSn__19DFD96B] DEFAULT (getdate()),
[LoadedIntoLTChangeHistory] [bit] NOT NULL CONSTRAINT [DF__SCR_PTL_S__Loade__1AD3FDA4] DEFAULT ((0)),
[LoadedIntoStatistics] [bit] NOT NULL CONSTRAINT [DF__SCR_PTL_S__Loade__1BC821DD] DEFAULT ((0)),
[LoadedIntoLastPtlRecord] [bit] NOT NULL CONSTRAINT [DF__SCR_PTL_S__Loade__1CBC4616] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Reporting_History].[SCR_PTL_SnapshotDates] ADD CONSTRAINT [PK_SCR_PTL_SnapshotDates] PRIMARY KEY CLUSTERED  ([PtlSnapshotId] DESC) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UK_SCR_PTL_SnapshotDates] ON [SCR_Reporting_History].[SCR_PTL_SnapshotDates] ([PtlSnapshotDate]) ON [PRIMARY]
GO
