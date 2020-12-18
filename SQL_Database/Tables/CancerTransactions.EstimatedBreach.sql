CREATE TABLE [CancerTransactions].[EstimatedBreach]
(
[EstimatedBreachId] [int] NOT NULL IDENTITY(1, 1),
[CWT_ID] [varchar] (255) NOT NULL,
[EstimatedWeight] [real] NULL,
[EstimatedBreachDate] [date] NULL,
[CapturedDate] [datetime] NULL,
[CapturedBy] [varchar] (255) NULL,
[CurrentRecord] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [CancerTransactions].[EstimatedBreach] ADD CONSTRAINT [PK_EstimatedBreachId] PRIMARY KEY CLUSTERED  ([EstimatedBreachId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_EstimatedBreach] ON [CancerTransactions].[EstimatedBreach] ([CWT_ID], [CurrentRecord]) ON [PRIMARY]
GO
