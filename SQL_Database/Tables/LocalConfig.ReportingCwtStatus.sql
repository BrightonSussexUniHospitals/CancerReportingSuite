CREATE TABLE [LocalConfig].[ReportingCwtStatus]
(
[cwtStatusId] [int] NOT NULL,
[cwtStatus] [varchar] (255) NULL,
[CwtPathwayTypeId] [int] NULL,
[SortOrder] [int] NULL,
[DefaultShow2WW] [bit] NULL,
[DefaultShow28] [bit] NULL,
[DefaultShow31] [bit] NULL,
[DefaultShow62] [bit] NULL,
[applicable2WW] [bit] NULL,
[applicable28] [bit] NULL,
[applicable31] [bit] NULL,
[applicable62] [bit] NULL,
[IsDeleted] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [LocalConfig].[ReportingCwtStatus] ADD CONSTRAINT [PK_ReportingCwtStatus] PRIMARY KEY CLUSTERED  ([cwtStatusId]) ON [PRIMARY]
GO
