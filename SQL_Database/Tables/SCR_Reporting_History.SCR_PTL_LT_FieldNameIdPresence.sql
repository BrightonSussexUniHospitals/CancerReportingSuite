CREATE TABLE [SCR_Reporting_History].[SCR_PTL_LT_FieldNameIdPresence]
(
[PtlSnapshotId] [int] NOT NULL,
[FieldNameId] [varchar] (255) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Reporting_History].[SCR_PTL_LT_FieldNameIdPresence] ADD CONSTRAINT [PK_SCR_PTL_LT_FieldNameIdPresence] PRIMARY KEY CLUSTERED  ([PtlSnapshotId], [FieldNameId]) ON [PRIMARY]
GO
