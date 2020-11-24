CREATE TABLE [Lookup].[cwtStandards]
(
[cwtStandardId] [int] NOT NULL,
[cwtStandardDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[cwtStandards] ADD CONSTRAINT [PK_cwtStandards] PRIMARY KEY CLUSTERED  ([cwtStandardId]) ON [PRIMARY]
GO
