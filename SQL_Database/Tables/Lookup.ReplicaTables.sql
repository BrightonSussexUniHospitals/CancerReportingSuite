CREATE TABLE [Lookup].[ReplicaTables]
(
[name] [sys].[sysname] NOT NULL,
[DataViewVersion] [varchar] (15) NOT NULL CONSTRAINT [DF_ReplicaTables_DataViewVersion] DEFAULT ('unknown'),
[VersionSpecificSQL] [nvarchar] (max) NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[ReplicaTables] ADD CONSTRAINT [PK_ReplicaTables] PRIMARY KEY CLUSTERED  ([name], [DataViewVersion]) ON [PRIMARY]
GO
