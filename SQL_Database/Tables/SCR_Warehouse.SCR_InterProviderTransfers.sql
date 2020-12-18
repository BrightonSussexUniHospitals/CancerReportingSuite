CREATE TABLE [SCR_Warehouse].[SCR_InterProviderTransfers]
(
[TertiaryReferralID] [int] NOT NULL,
[CareID] [int] NULL,
[ACTION_ID] [int] NULL,
[IPTTypeCode] [int] NULL,
[IPTTypeDesc] [varchar] (100) NULL,
[IPTDate] [datetime] NULL,
[IPTReferralReasonCode] [int] NULL,
[IPTReferralReasonDesc] [varchar] (100) NULL,
[IPTReceiptReasonCode] [int] NULL,
[IPTReceiptReasonDesc] [varchar] (100) NULL,
[ReferringOrgID] [int] NULL,
[ReferringOrgCode] [varchar] (5) NULL,
[ReferringOrgName] [varchar] (100) NULL,
[TertiaryReferralOutComments] [varchar] (max) NULL,
[ReceivingOrgID] [int] NULL,
[ReceivingOrgCode] [varchar] (5) NULL,
[ReceivingOrgName] [varchar] (100) NULL,
[TertiaryReferralInComments] [varchar] (max) NULL,
[IptReasonTypeCareIdIx] [int] NULL,
[IsTransferOfCare] [bit] NULL,
[LastUpdatedBy] [varchar] (50) NULL
) ON [PRIMARY]
GO
ALTER TABLE [SCR_Warehouse].[SCR_InterProviderTransfers] ADD CONSTRAINT [PK_InterProviderTransfers] PRIMARY KEY CLUSTERED  ([TertiaryReferralID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [Ix_CARE_ID] ON [SCR_Warehouse].[SCR_InterProviderTransfers] ([CareID]) ON [PRIMARY]
GO
