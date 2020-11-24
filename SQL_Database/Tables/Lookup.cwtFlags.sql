CREATE TABLE [Lookup].[cwtFlags]
(
[cwtFlagID] [int] NOT NULL,
[cwtFlagDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[cwtFlags] ADD CONSTRAINT [PK_cwtFlags] PRIMARY KEY CLUSTERED  ([cwtFlagID]) ON [PRIMARY]
GO
