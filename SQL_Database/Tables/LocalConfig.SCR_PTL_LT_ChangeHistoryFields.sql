CREATE TABLE [LocalConfig].[SCR_PTL_LT_ChangeHistoryFields]
(
[FieldNameId] [int] NOT NULL IDENTITY(1, 1),
[FieldName] [varchar] (255) NOT NULL,
[FieldType] [varchar] (255) NOT NULL,
[Inactive] [bit] NOT NULL CONSTRAINT [DF__SCR_PTL_L__Inact__0D7A0286] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [LocalConfig].[SCR_PTL_LT_ChangeHistoryFields] ADD CONSTRAINT [PK_SCR_PTL_LT_ChangeHistoryFields] PRIMARY KEY CLUSTERED  ([FieldNameId]) ON [PRIMARY]
GO
