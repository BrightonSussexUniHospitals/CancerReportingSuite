USE [CancerReporting]
GO
INSERT [LocalConfig].[ReportingCwtPathwayType] ([CwtPathwayTypeId], [CwtPathwayTypeDesc], [SortOrder], [DefaultShow]) VALUES (1, N'On PTL', 1, 1)
INSERT [LocalConfig].[ReportingCwtPathwayType] ([CwtPathwayTypeId], [CwtPathwayTypeDesc], [SortOrder], [DefaultShow]) VALUES (2, N'In CWT submission', 2, 0)
INSERT [LocalConfig].[ReportingCwtPathwayType] ([CwtPathwayTypeId], [CwtPathwayTypeDesc], [SortOrder], [DefaultShow]) VALUES (3, N'Filtered out', 3, 0)
