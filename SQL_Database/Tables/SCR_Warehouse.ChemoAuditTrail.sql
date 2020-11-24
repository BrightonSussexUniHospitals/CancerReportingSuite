CREATE TABLE [SCR_Warehouse].[ChemoAuditTrail]
(
[CARE_ID] [int] NOT NULL,
[CHEMO_ID] [int] NOT NULL,
[DEFINITIVE_TREATMENT] [int] NULL,
[N_CHEMORADIO] [int] NULL,
[DecisionDate] [smalldatetime] NULL,
[StartDate] [smalldatetime] NULL,
[EndDate] [smalldatetime] NULL,
[ACTION_ID] [int] NULL,
[TABLE_NAME] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[RECORD_ID] [bigint] NULL,
[Upd_ACTION_TYPE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Ins_ACTION_TYPE] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[LastUpdatedBy] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[LastUpdated] [smalldatetime] NULL,
[InsertedBy] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Inserted] [smalldatetime] NULL,
[ChemoInsertIx] [bigint] NULL,
[InCWT] [int] NOT NULL,
[TELE_ID] [int] NULL
) ON [PRIMARY]
GO
