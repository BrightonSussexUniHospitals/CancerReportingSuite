CREATE TABLE [SCR_Warehouse].[RadioAuditTrail]
(
[CARE_ID] [int] NOT NULL,
[TELE_ID] [int] NOT NULL,
[DEFINITIVE_TREATMENT] [int] NULL,
[N_CHEMORADIO] [int] NULL,
[DecisionDate] [smalldatetime] NULL,
[StartDate] [smalldatetime] NULL,
[EndDate] [smalldatetime] NULL,
[ACTION_ID] [int] NULL,
[TABLE_NAME] [varchar] (50) NULL,
[RECORD_ID] [bigint] NULL,
[Upd_ACTION_TYPE] [varchar] (50) NULL,
[Ins_ACTION_TYPE] [varchar] (50) NULL,
[LastUpdatedBy] [varchar] (50) NULL,
[LastUpdated] [smalldatetime] NULL,
[InsertedBy] [varchar] (50) NULL,
[Inserted] [smalldatetime] NULL,
[RadioInsertIx] [bigint] NULL,
[InCWT] [int] NOT NULL,
[CHEMO_ID] [int] NULL
) ON [PRIMARY]
GO
