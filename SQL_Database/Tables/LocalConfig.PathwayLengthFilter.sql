CREATE TABLE [LocalConfig].[PathwayLengthFilter]
(
[PathwayLengthFilterId] [int] NOT NULL,
[PathwayLengthFilterName] [varchar] (255) NOT NULL,
[LowerBound] [int] NULL,
[UpperBound] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [LocalConfig].[PathwayLengthFilter] ADD CONSTRAINT [PK_PathwayLengthFilterId] PRIMARY KEY CLUSTERED  ([PathwayLengthFilterId]) ON [PRIMARY]
GO
