CREATE TABLE [LocalConfig].[ReportingCwtPathwayType]
(
[CwtPathwayTypeId] [int] NOT NULL,
[CwtPathwayTypeDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SortOrder] [int] NULL,
[DefaultShow] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [LocalConfig].[ReportingCwtPathwayType] ADD CONSTRAINT [PK_ReportingCwtPathwayType] PRIMARY KEY CLUSTERED  ([CwtPathwayTypeId]) ON [PRIMARY]
GO
