CREATE TABLE [Lookup].[cwtReasons]
(
[cwtReasonID] [int] NOT NULL,
[cwtFlagID] [int] NULL,
[applicable2WW] [bit] NULL,
[applicable28] [bit] NULL,
[applicable31] [bit] NULL,
[applicable62] [bit] NULL,
[cwtReasonDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Lookup].[cwtReasons] ADD CONSTRAINT [PK_cwtReasons] PRIMARY KEY CLUSTERED  ([cwtReasonID]) ON [PRIMARY]
GO
