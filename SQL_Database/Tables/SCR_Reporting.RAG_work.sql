CREATE TABLE [SCR_Reporting].[RAG_work]
(
[CWT_ID] [varchar] (255) NOT NULL,
[DominantPriority] [int] NULL,
[Priority2WW] [int] NULL,
[Priority28] [int] NULL,
[Priority31] [int] NULL,
[Priority62] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Reporting].[RAG_work] ADD CONSTRAINT [PK_RAG_work] PRIMARY KEY CLUSTERED  ([CWT_ID]) ON [PRIMARY]
GO
