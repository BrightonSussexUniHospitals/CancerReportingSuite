USE [CancerReporting]
GO
/****** Object:  Table [SCR_Warehouse].[OpenTargetDates]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SCR_Warehouse].[OpenTargetDates](
	[OpenTargetDatesId] [int] IDENTITY(1,1) NOT NULL,
	[CARE_ID] [int] NOT NULL,
	[CWT_ID] [varchar](255) NOT NULL,
	[DaysToTarget] [int] NULL,
	[TargetDate] [datetime] NULL,
	[DaysToBreach] [int] NULL,
	[BreachDate] [datetime] NULL,
	[TargetType] [varchar](255) NULL,
	[WaitTargetGroupDesc] [varchar](255) NULL,
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
	[IxLastFutureOpenGroupBreachDate] [int] NULL,
 CONSTRAINT [PK_OpenTargetDates] PRIMARY KEY CLUSTERED 
(
	[OpenTargetDatesId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Index [Ix_CARE_ID_Work]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_CARE_ID_Work] ON [SCR_Warehouse].[OpenTargetDates]
(
	[CARE_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [Ix_CWT_ID_Work]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_CWT_ID_Work] ON [SCR_Warehouse].[OpenTargetDates]
(
	[CWT_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
