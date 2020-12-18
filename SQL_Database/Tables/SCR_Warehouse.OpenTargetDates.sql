CREATE TABLE [SCR_Warehouse].[OpenTargetDates]
(
[OpenTargetDatesId] [int] NOT NULL IDENTITY(1, 1),
[CARE_ID] [int] NOT NULL,
[CWT_ID] [varchar] (255) NOT NULL,
[DaysToTarget] [int] NULL,
[TargetDate] [datetime] NULL,
[DaysToBreach] [int] NULL,
[BreachDate] [datetime] NULL,
[TargetType] [varchar] (255) NULL,
[WaitTargetGroupDesc] [varchar] (255) NULL,
[WaitTargetPriority] [int] NULL,
[ReportDate] [datetime] NULL,
[IxFirstOpenTargetDate] [int] NULL,
[IxLastOpenTargetDate] [int] NULL,
[IxNextFutureOpenTargetDate] [int] NULL,
[IxLastFutureOpenTargetDate] [int] NULL,
[IxFirstOpenGroupTargetDate] [int] NULL,
[IxLastOpenGroupTargetDate] [int] NULL,
[IxNextFutureOpenGroupTargetDate] [int] NULL,
[IxLastFutureOpenGroupTargetDate] [int] NULL,
[IxFirstOpenBreachDate] [int] NULL,
[IxLastOpenBreachDate] [int] NULL,
[IxNextFutureOpenBreachDate] [int] NULL,
[IxLastFutureOpenBreachDate] [int] NULL,
[IxFirstOpenGroupBreachDate] [int] NULL,
[IxLastOpenGroupBreachDate] [int] NULL,
[IxNextFutureOpenGroupBreachDate] [int] NULL,
[IxLastFutureOpenGroupBreachDate] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Warehouse].[OpenTargetDates] ADD CONSTRAINT [PK_OpenTargetDates] PRIMARY KEY CLUSTERED  ([OpenTargetDatesId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_CARE_ID_Work] ON [SCR_Warehouse].[OpenTargetDates] ([CARE_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_CWT_ID_Work] ON [SCR_Warehouse].[OpenTargetDates] ([CWT_ID]) ON [PRIMARY]
GO
