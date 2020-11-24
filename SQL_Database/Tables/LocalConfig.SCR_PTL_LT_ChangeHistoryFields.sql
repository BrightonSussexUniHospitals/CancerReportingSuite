CREATE TABLE [LocalConfig].[SCR_PTL_LT_ChangeHistoryFields]
(
[FieldNameId] [int] NOT NULL IDENTITY(1, 1),
[FieldName] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[FieldType] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[Inactive] [bit] NOT NULL CONSTRAINT [DF__SCR_PTL_L__Inact__0D7A0286] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UK_SCR_PTL_LT_ChangeHistoryFields] ON [LocalConfig].[SCR_PTL_LT_ChangeHistoryFields] ([FieldNameId]) ON [PRIMARY]
GO
