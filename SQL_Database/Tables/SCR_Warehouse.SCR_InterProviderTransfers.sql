CREATE TABLE [SCR_Warehouse].[SCR_InterProviderTransfers]
(
[TertiaryReferralID] [int] NOT NULL,
[CareID] [int] NULL,
[ACTION_ID] [int] NULL,
[IPTTypeCode] [int] NULL,
[IPTTypeDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[IPTDate] [datetime] NULL,
[IPTReferralReasonCode] [int] NULL,
[IPTReferralReasonDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[IPTReceiptReasonCode] [int] NULL,
[IPTReceiptReasonDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[ReferringOrgID] [int] NULL,
[ReferringOrgCode] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ReferringOrgName] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[TertiaryReferralOutComments] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[ReceivingOrgID] [int] NULL,
[ReceivingOrgCode] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ReceivingOrgName] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[TertiaryReferralInComments] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[IptReasonTypeCareIdIx] [int] NULL,
[IsTransferOfCare] [bit] NULL,
[LastUpdatedBy] [varchar] (50) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Warehouse].[SCR_InterProviderTransfers] ADD CONSTRAINT [PK_InterProviderTransfers] PRIMARY KEY CLUSTERED  ([TertiaryReferralID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_CARE_ID] ON [SCR_Warehouse].[SCR_InterProviderTransfers] ([CareID]) ON [PRIMARY]
GO
