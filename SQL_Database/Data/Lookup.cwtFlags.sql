USE [CancerReporting]
GO
INSERT [Lookup].[cwtFlags] ([cwtFlagID], [cwtFlagDesc]) VALUES (0, N'Closed / Excluded')
INSERT [Lookup].[cwtFlags] ([cwtFlagID], [cwtFlagDesc]) VALUES (1, N'Open')
INSERT [Lookup].[cwtFlags] ([cwtFlagID], [cwtFlagDesc]) VALUES (2, N'Reportable')
INSERT [Lookup].[cwtFlags] ([cwtFlagID], [cwtFlagDesc]) VALUES (4, N'Not Applicable')
INSERT [Lookup].[cwtFlags] ([cwtFlagID], [cwtFlagDesc]) VALUES (5, N'Error!')
