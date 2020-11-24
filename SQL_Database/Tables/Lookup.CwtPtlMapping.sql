CREATE TABLE [Lookup].[CwtPtlMapping]
(
[CwtPtlMappingId] [int] NOT NULL IDENTITY(1, 1),
[cwtReason2WW] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[cwtReason28] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[cwtReason31] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[cwtReason62] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[cwtType2WW] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[cwtType28] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[cwtType31] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[cwtType62] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[InExcelPtl_RTT] [int] NOT NULL,
[InExcelPtl_Screening] [int] NOT NULL,
[InExcelPtl_Upgrade] [int] NOT NULL,
[InExcelPtl_DTT] [int] NOT NULL,
[InExcelPtl_SubsequentTx] [int] NOT NULL
) ON [PRIMARY]
GO
