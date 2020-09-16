USE [CancerReporting]
GO
/****** Object:  Table [Lookup].[CwtPtlMapping]    Script Date: 03/09/2020 23:41:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Lookup].[CwtPtlMapping](
	[CwtPtlMappingId] [int] IDENTITY(1,1) NOT NULL,
	[cwtReason2WW] [varchar](255) NOT NULL,
	[cwtReason28] [varchar](255) NOT NULL,
	[cwtReason31] [varchar](255) NOT NULL,
	[cwtReason62] [varchar](255) NOT NULL,
	[cwtType2WW] [varchar](255) NOT NULL,
	[cwtType28] [varchar](255) NOT NULL,
	[cwtType31] [varchar](255) NOT NULL,
	[cwtType62] [varchar](255) NOT NULL,
	[InExcelPtl_RTT] [int] NOT NULL,
	[InExcelPtl_Screening] [int] NOT NULL,
	[InExcelPtl_Upgrade] [int] NOT NULL,
	[InExcelPtl_DTT] [int] NOT NULL,
	[InExcelPtl_SubsequentTx] [int] NOT NULL
) ON [PRIMARY]
GO
