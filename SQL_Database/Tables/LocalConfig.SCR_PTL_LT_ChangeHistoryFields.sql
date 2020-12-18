CREATE TABLE [LocalConfig].[SCR_PTL_LT_ChangeHistoryFields]
(
[FieldNameId] [int] NOT NULL IDENTITY(1, 1),
[FieldName] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[FieldType] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[Inactive] [bit] NOT NULL CONSTRAINT [DF__SCR_PTL_L__Inact__0E6E26BF] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [LocalConfig].[SCR_PTL_LT_ChangeHistoryFields] ADD CONSTRAINT [PK_SCR_PTL_LT_ChangeHistoryFields] PRIMARY KEY CLUSTERED  ([FieldNameId]) ON [PRIMARY]
GO
