CREATE TABLE [SCR_Reporting].[RAG]
(
[CWT_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[DominantPriority] [int] NULL,
[Priority2WW] [int] NULL,
[Priority28] [int] NULL,
[Priority31] [int] NULL,
[Priority62] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Reporting].[RAG] ADD CONSTRAINT [PK_RAG] PRIMARY KEY CLUSTERED  ([CWT_ID]) ON [PRIMARY]
GO
