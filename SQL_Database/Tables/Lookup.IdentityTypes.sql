CREATE TABLE [Lookup].[IdentityTypes]
(
[IdentityTypeID] [int] NOT NULL,
[IdentityTypeDesc] [varchar] (255) NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[IdentityTypes] ADD CONSTRAINT [PK_IdentityTypes] PRIMARY KEY CLUSTERED  ([IdentityTypeID]) ON [PRIMARY]
GO
