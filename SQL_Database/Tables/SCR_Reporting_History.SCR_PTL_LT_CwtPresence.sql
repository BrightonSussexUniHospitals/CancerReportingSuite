CREATE TABLE [SCR_Reporting_History].[SCR_PTL_LT_CwtPresence]
(
[PtlSnapshotId] [int] NOT NULL,
[CWT_ID] [varchar] (255) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Reporting_History].[SCR_PTL_LT_CwtPresence] ADD CONSTRAINT [PK_SCR_PTL_LT_CwtPresence] PRIMARY KEY CLUSTERED  ([PtlSnapshotId], [CWT_ID]) ON [PRIMARY]
GO
