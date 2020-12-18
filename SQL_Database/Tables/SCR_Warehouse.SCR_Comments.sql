CREATE TABLE [SCR_Warehouse].[SCR_Comments]
(
[SourceRecordId] [varchar] (255) NOT NULL,
[SourceTableName] [varchar] (255) NOT NULL,
[SourceColumnName] [varchar] (255) NOT NULL,
[CARE_ID] [int] NOT NULL,
[Comment] [varchar] (max) NULL,
[CommentUser] [varchar] (50) NULL,
[CommentDate] [datetime] NULL,
[CommentType] [int] NULL,
[CareIdIx] [int] NULL,
[CareIdRevIx] [int] NULL,
[CommentTypeCareIdIx] [int] NULL,
[CommentTypeCareIdRevIx] [int] NULL,
[ReportDate] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Warehouse].[SCR_Comments] ADD CONSTRAINT [PK_SCR_Comments] PRIMARY KEY CLUSTERED  ([SourceRecordId], [SourceTableName], [SourceColumnName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_CARE_ID] ON [SCR_Warehouse].[SCR_Comments] ([CARE_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_CommentTypeCareIdIx] ON [SCR_Warehouse].[SCR_Comments] ([CARE_ID], [CommentTypeCareIdIx], [CommentType]) INCLUDE ([Comment], [CommentDate]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_PTL_Live] ON [SCR_Warehouse].[SCR_Comments] ([CommentType], [CommentTypeCareIdRevIx], [CARE_ID]) INCLUDE ([Comment], [CommentUser]) ON [PRIMARY]
GO
