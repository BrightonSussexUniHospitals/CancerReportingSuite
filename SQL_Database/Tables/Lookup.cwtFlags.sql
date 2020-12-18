CREATE TABLE [Lookup].[cwtFlags]
(
[cwtFlagID] [int] NOT NULL,
[cwtFlagDesc] [varchar] (255) NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[cwtFlags] ADD CONSTRAINT [PK_cwtFlags] PRIMARY KEY CLUSTERED  ([cwtFlagID]) ON [PRIMARY]
GO
