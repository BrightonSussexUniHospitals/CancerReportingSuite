CREATE TABLE [Lookup].[commentTypes]
(
[commentTypeID] [int] NOT NULL,
[commentTypeDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[commentTypes] ADD CONSTRAINT [PK_commentTypes] PRIMARY KEY CLUSTERED  ([commentTypeID]) ON [PRIMARY]
GO
