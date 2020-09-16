USE [CancerReporting]
GO
INSERT [LocalConfig].[ReportingWorkflows] ([WorkflowID], [WorkflowDesc], [WorkflowSortOrder]) VALUES (0, N'All Pathways', 0)
INSERT [LocalConfig].[ReportingWorkflows] ([WorkflowID], [WorkflowDesc], [WorkflowSortOrder]) VALUES (1, N'2ww: Undated', 1)
INSERT [LocalConfig].[ReportingWorkflows] ([WorkflowID], [WorkflowDesc], [WorkflowSortOrder]) VALUES (2, N'2ww: Undated > 5 Days', 2)
INSERT [LocalConfig].[ReportingWorkflows] ([WorkflowID], [WorkflowDesc], [WorkflowSortOrder]) VALUES (3, N'2ww: Pending', 3)
INSERT [LocalConfig].[ReportingWorkflows] ([WorkflowID], [WorkflowDesc], [WorkflowSortOrder]) VALUES (4, N'2ww: Pending > 14 Days', 4)
INSERT [LocalConfig].[ReportingWorkflows] ([WorkflowID], [WorkflowDesc], [WorkflowSortOrder]) VALUES (5, N'62 Day: > 104 Days', 5)
INSERT [LocalConfig].[ReportingWorkflows] ([WorkflowID], [WorkflowDesc], [WorkflowSortOrder]) VALUES (6, N'62 Day: > 62 Days', 6)
INSERT [LocalConfig].[ReportingWorkflows] ([WorkflowID], [WorkflowDesc], [WorkflowSortOrder]) VALUES (7, N'62 Day: 28-62 Days', 7)
INSERT [LocalConfig].[ReportingWorkflows] ([WorkflowID], [WorkflowDesc], [WorkflowSortOrder]) VALUES (8, N'Next Action Date in Past or Undated', 8)
INSERT [LocalConfig].[ReportingWorkflows] ([WorkflowID], [WorkflowDesc], [WorkflowSortOrder]) VALUES (9, N'Next Action Date > 10 days away', 9)
INSERT [LocalConfig].[ReportingWorkflows] ([WorkflowID], [WorkflowDesc], [WorkflowSortOrder]) VALUES (10, N'No Next Action', 10)
