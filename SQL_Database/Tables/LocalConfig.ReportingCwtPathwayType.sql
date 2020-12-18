CREATE TABLE [LocalConfig].[ReportingCwtPathwayType]
(
[CwtPathwayTypeId] [int] NOT NULL,
[CwtPathwayTypeDesc] [varchar] (255) NULL,
[SortOrder] [int] NULL,
[DefaultShow] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [LocalConfig].[ReportingCwtPathwayType] ADD CONSTRAINT [PK_ReportingCwtPathwayType] PRIMARY KEY CLUSTERED  ([CwtPathwayTypeId]) ON [PRIMARY]
GO
