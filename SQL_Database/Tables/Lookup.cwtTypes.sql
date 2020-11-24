CREATE TABLE [Lookup].[cwtTypes]
(
[cwtTypeID] [int] NOT NULL,
[cwtTypeDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[cwtStandardId] [int] NULL,
[cwtStandard_WaitTargetId] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[cwtTypes] ADD CONSTRAINT [PK_cwtTypes] PRIMARY KEY CLUSTERED  ([cwtTypeID]) ON [PRIMARY]
GO
