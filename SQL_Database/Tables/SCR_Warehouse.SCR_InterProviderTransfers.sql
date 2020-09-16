USE [CancerReporting]
GO
/****** Object:  Table [SCR_Warehouse].[SCR_InterProviderTransfers]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [SCR_Warehouse].[SCR_InterProviderTransfers](
	[TertiaryReferralID] [int] NOT NULL,
	[CareID] [int] NULL,
	[ACTION_ID] [int] NULL,
	[IPTTypeCode] [int] NULL,
	[IPTTypeDesc] [varchar](100) NULL,
	[IPTDate] [datetime] NULL,
	[IPTReferralReasonCode] [int] NULL,
	[IPTReferralReasonDesc] [varchar](100) NULL,
	[IPTReceiptReasonCode] [int] NULL,
	[IPTReceiptReasonDesc] [varchar](100) NULL,
	[ReferringOrgID] [int] NULL,
	[ReferringOrgCode] [varchar](5) NULL,
	[ReferringOrgName] [varchar](100) NULL,
	[TertiaryReferralOutComments] [varchar](max) NULL,
	[ReceivingOrgID] [int] NULL,
	[ReceivingOrgCode] [varchar](5) NULL,
	[ReceivingOrgName] [varchar](100) NULL,
	[TertiaryReferralInComments] [varchar](max) NULL,
	[IptReasonTypeCareIdIx] [int] NULL,
	[LastUpdatedBy] [varchar](50) NULL,
 CONSTRAINT [PK_InterProviderTransfers] PRIMARY KEY CLUSTERED 
(
	[TertiaryReferralID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Index [Ix_CARE_ID]    Script Date: 03/09/2020 23:41:02 ******/
CREATE NONCLUSTERED INDEX [Ix_CARE_ID] ON [SCR_Warehouse].[SCR_InterProviderTransfers]
(
	[CareID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
