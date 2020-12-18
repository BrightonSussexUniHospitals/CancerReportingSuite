CREATE TABLE [SCR_Reporting_History].[SCR_PTL_LT_ChangeHistory]
(
[PtlSnapshotId_Start] [int] NOT NULL,
[CWT_ID] [varchar] (255) NOT NULL,
[FieldNameId] [int] NOT NULL,
[FieldValueInt] [real] NULL,
[FieldValueString] [varchar] (max) NULL,
[FieldValueDatetime] [datetime2] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UK_SCR_PTL_LT_ChangeHistory] ON [SCR_Reporting_History].[SCR_PTL_LT_ChangeHistory] ([FieldNameId] DESC, [PtlSnapshotId_Start] DESC, [CWT_ID]) ON [PRIMARY]
GO
