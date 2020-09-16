USE [CancerReporting]
GO
/****** Object:  Table [CancerTransactions].[EstimatedBreach]    Script Date: 03/09/2020 23:41:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [CancerTransactions].[EstimatedBreach](
	[EstimatedBreachId] [int] IDENTITY(1,1) NOT NULL,
	[CWT_ID] [varchar](255) NOT NULL,
	[EstimatedWeight] [real] NULL,
	[EstimatedBreachDate] [date] NULL,
	[CapturedDate] [datetime] NULL,
	[CapturedBy] [varchar](255) NULL,
	[CurrentRecord] [bit] NULL,
 CONSTRAINT [PK_EstimatedBreachId] PRIMARY KEY CLUSTERED 
(
	[EstimatedBreachId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [Ix_EstimatedBreach]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_EstimatedBreach] ON [CancerTransactions].[EstimatedBreach]
(
	[CWT_ID] ASC,
	[CurrentRecord] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
