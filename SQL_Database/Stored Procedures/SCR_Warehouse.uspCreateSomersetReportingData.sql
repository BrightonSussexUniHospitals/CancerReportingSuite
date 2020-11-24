SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [SCR_Warehouse].[uspCreateSomersetReportingData] 
		(@IncrementalUpdate bit = 0
		,@UpdatePtlSnapshots int = 0
		)
AS

PRINT CAST(@IncrementalUpdate AS varchar(255)) + ' @IncrementalUpdate value'
PRINT CAST(@UpdatePtlSnapshots AS varchar(255)) + ' @UpdatePtlSnapshots value'

-- EXEC SCR_Warehouse.uspCreateSomersetReportingData @IncrementalUpdate = 1, @UpdatePtlSnapshots = 0 -- Run Me

/******************************************************** © Copyright & Licensing ****************************************************************
© 2019 Perspicacity Ltd & Brighton & Sussex University Hospitals

This code / file is part of Perspicacity & BSUH's Cancer Data Warehouse & Reporting suite.

This Cancer Data Warehouse & Reporting suite is free software: you can 
redistribute it and/or modify it under the terms of the GNU Affero 
General Public License as published by the Free Software Foundation, 
either version 3 of the License, or (at your option) any later version.

This Cancer Data Warehouse & Reporting suite is distributed in the hope 
that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

A full copy of this code can be found at https://github.com/BrightonSussexUniHospitals/CancerReportingSuite

You may also be interested in the other repositories at https://github.com/perspicacity-ltd or
https://github.com/BrightonSussexUniHospitals

Original Work Created Date:	01/03/2019
Original Work Created By:	Perspicacity Ltd (Matthew Bishop) & BSUH (Lawrence Simpson)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk / lawrencesimpson@nhs.net
Description:				Create the warehouse datasets for all SCR / Somerset reporting
**************************************************************************************************************************************************/

/************************************************************************************************************************************************************************************************************
-- Understanding the parameters for this stored procedure
	-- @IncrementalUpdate
	This parameter will instruct the stored procedure whether it should perform an incremental update to the SCR_CWT table, 
	rather than updating the entire table, or not. The purpose is to reduce the amount of time it takes to update the table 
	by reducing the number of records we are refreshing - this is done by identifying records that have changed since the 
	last update using the tblAUDIT table as the determinant of when records are updated.
	The default value is 0 - an incremental update will not be performed and records will be bulk updated

	-- @UpdatePtlSnapshots
	This parameter determines which snapshots of the reporting PTL the stored procedure will be updated
	It has 7 possible values (NB: this is a bitwise representation of 3 bits representing whether each of the 3 PTL's is run or not):
		0	None						No PTL snapshots will be updated, regardless of what changes have happened in the data
		1	Selective					The selective reporting PTL will only be updated with changes that we wish to filter through from the Live PTL
		2	Daily						The daily reporting PTL will be updated to match the Live PTL
		3	Daily + Selective			The selective reporting PTL will only be updated with changes that we wish to filter through from the Live PTL + the daily reporting PTL will be updated to match the Live PTL
		4	Weekly						The weekly reporting PTL will be updated to match the Live PTL
		5	Weekly + Selective			The selective reporting PTL will only be updated with changes that we wish to filter through from the Live PTL + the weekly reporting PTL will be updated to match the Live PTL
		6	Weekly + Daily				The weekly & daily reporting PTL will be updated to match the Live PTL
		7	Weekly + Daily + Selective	The selective reporting PTL will only be updated with changes that we wish to filter through from the Live PTL + the weekly & daily reporting PTL will be updated to match the Live PTL

************************************************************************************************************************************************************************************************************/

/************************************************************************************************************************************************************************************************************
-- Procedure:		uspCreateSomersetReportingData
-- Author(s):		Lawrence Simpson & Matthew Bishop
-- email:			lawrencesimpson@nhs.net & matthew.bishop@perspicacityltd.co.uk
-- Created:			20190313
-- Last Updated:	20190403
-- Description:		produces a set of tables required to report the entire SCR PTL 
************************************************************************************************************************************************************************************************************/

/************************************************************************************************************************************************************************************************************
-- Create SCR Working tables
************************************************************************************************************************************************************************************************************/

		-- DROP SCR_Referrals_work table if it exists
		if object_ID('SCR_Warehouse.SCR_Referrals_work') is not null 
		   DROP TABLE SCR_Warehouse.SCR_Referrals_work
		 
		-- Create SCR Referrals Work table
		CREATE TABLE SCR_Warehouse.SCR_Referrals_work(
			-- ID's
			CARE_ID int NOT NULL,
			PatientPathwayID varchar(20) NULL,
			PatientPathwayIdIssuer varchar(3) NULL,
			PATIENT_ID int NULL DEFAULT 0,				-- Internal patient ID
			MainRefActionId int NULL,					-- audit trail action ID from the tblMainReferrals table
			DiagnosisActionId int NULL,					-- audit trail action ID from the tblMainReferrals table (for the diagnosis portion of the referrals table)
			DemographicsActionId int NULL,				-- audit trail action ID from the tblDEMOGRAPHICS table	
			-- Demographics
			Forename varchar(50) NULL,
			Surname varchar(60) NULL,			
			DateBirth date NULL,
			HospitalNumber varchar(20) NULL,
			NHSNumber varchar(10) NULL,
			NHSNumberStatusCode varchar(3) NULL,		-- NHS_NUMBER_STATUS
			NstsStatus int NULL,						-- L_NSTS_STATUS
			IsTemporaryNHSNumber int NULL,
			DeathStatus int NULL,
			DateDeath date NULL,
			PctCode varchar(5) NULL,					-- N1_13_PCT
			PctDesc varchar(100) NULL,					-- ltblNATIONAL_PCT.PCT_DESC
			CcgCode varchar(3) NULL,					-- try searching code from BIvwReferrals
			CcgDesc varchar(100) NULL,					-- try searching code from BIvwReferrals
			-- Referral Pathway data
			CancerSite varchar(50) NULL,				-- The Cancer Site (taken from L_CANCER_SITE)
			CancerSiteBS varchar(50) NULL,				-- The Cancer Site with Breast Symptomatic differentiated (taken from L_CANCER_SITE)
			CancerSubSiteCode int NULL,					-- The Cancer subsite (now taken from tblMAIN_REFERRALS and relevant for all cancer sites rather than specifically for Upper GI)
			CancerSubSiteDesc varchar(25) NULL,			-- The Cancer subsite (taken from CancerReferralSubsites)
			ReferralCancerSiteCode varchar(50) NULL,	-- The Referral Cancer Site Code (derived from N2_12_CANCER_TYPE)
			ReferralCancerSiteDesc varchar(50) NULL,	-- The Referral Cancer Site (derived from N2_12_CANCER_TYPE)
			ReferralCancerSiteBS varchar(50) NULL,		-- The Referral Cancer Site Code with Breast Symptomatic differentiated (derived from N2_12_CANCER_TYPE)
			CancerTypeCode varchar(2) NULL,				-- N2_12_CANCER_TYPE
			CancerTypeDesc varchar(100) NULL,           
			PriorityTypeCode varchar(2) NULL,			-- N2_4_PRIORITY_TYPE
			PriorityTypeDesc varchar(13) NULL,
			SourceReferralCode varchar(2) NULL,			-- N2_16_OP_REFERRAL
			SourceReferralDesc varchar(100) NULL, 
			ReferralMethodCode int NULL,				-- L_REFERRAL_METHOD
			DecisionToReferDate smalldatetime NULL,		-- N2_5_DECISION_DATE
			TumourStatusCode varchar(50) NULL,			-- L_TUMOUR_STATUS
			TumourStatusDesc varchar(50) NULL,
			PatientStatusCode varchar(2) NULL,			-- N2_13_CANCER_STATUS
			PatientStatusDesc varchar(100) NULL,
			PatientStatusCodeCwt varchar(2) NULL,			
			PatientStatusDescCwt varchar(100) NULL,
			ConsultantCode varchar(8) NULL,				-- N2_7_CONSULTANT
			ConsultantName varchar(255) NULL,
			InappropriateRef int NULL,					-- L_INAP_REF
			-- Referral Transfer Data
			TransferReason int NULL,					-- TRANSFER_REASON
			TransferNewRefDate smalldatetime NULL,		-- DATE_NEW_REFERRAL
			TransferTumourSiteCode int NULL,			-- TUMOUR_SITE_NEW
			TransferTumourSiteDesc varchar(100) NULL,	-- L_NEW_CA_SITE (for pre-2014 records) / Lookup from TransferTumourSiteCode for post 2014
			TransferActionedDate smalldatetime NULL,	-- DATE_TRANSFER_ACTIONED
			TransferSourceCareId int NULL,				-- SOURCE_CARE_ID
			TransferOrigSourceCareId int NULL,			-- ORIGINAL_SOURCE_CARE_ID
			-- Faster Diagnosis
			FastDiagInformedDate smalldatetime NULL,	-- tblMAIN_REFERRALS.L_PT_INFORMED_DATE
			FastDiagExclDate datetime NULL,				-- tblMAIN_REFERRALS.FasterDiagnosisExclusionDate
			FastDiagCancerSiteID int NULL,				-- ltblDIAGNOSIS.FasterDiagnosisCancerSiteID (from ltblDIAGNOSIS.DIAG_CODE = tblMAIN_REFERRALS.N4_2_DIAGNOSIS_CODE)
			FastDiagCancerSiteOverrideID int NULL,		-- tblMAIN_REFERRALS.FasterDiagnosisCancerSiteOverrideID
			FastDiagCancerSiteCode varchar(2) NULL,		-- ltblFasterDiagnosisCancerSite.CWTCode
			FastDiagCancerSiteDesc varchar(50) NULL,	-- ltblFasterDiagnosisCancerSite.Description
			FastDiagEndReasonID int NULL,				-- (calculated)
			FastDiagEndReasonCode varchar(2) NULL,		-- ltblFasterDiagnosisPathwayEndReason.CWTCode
			FastDiagEndReasonDesc varchar(25) NULL,		-- ltblFasterDiagnosisPathwayEndReason.Description
			FastDiagDelayReasonID int NULL,				-- tblMAIN_REFERRALS.FasterDiagnosisDelayReasonID
			FastDiagDelayReasonCode varchar(2) NULL,	-- ltblFasterDiagnosisDelayReason.CWTCode
			FastDiagDelayReasonDesc varchar(160) NULL,	-- ltblFasterDiagnosisDelayReason.Description
			FastDiagDelayReasonComments varchar(max) NULL, -- tblMAIN_REFERRALS.FasterDiagnosisDelayReasonComments
			FastDiagExclReasonID int NULL,				-- tblMAIN_REFERRALS.FasterDiagnosisExclusionReasonID
			FastDiagExclReasonCode varchar(2) NULL,		-- ltblFasterDiagnosisExclusionReason.CWTCode
			FastDiagExclReasonDesc varchar(80) NULL,	-- ltblFasterDiagnosisExclusionReason.Description
			FastDiagOrgID int NULL,						-- tblMAIN_REFERRALS.FasterDiagnosisOrganisationID
			FastDiagOrgCode varchar(5) NULL,			-- OrganisationSites.Code
			FastDiagOrgDesc varchar(250) NULL,			-- OrganisationSites.Description
			FastDiagCommMethodID int NULL,				-- tblMAIN_REFERRALS.FasterDiagnosisCommunicationMethodID
			FastDiagCommMethodCode varchar(2) NULL,		-- ltblFasterDiagnosisCommunicationMethod.CWTCode
			FastDiagCommMethodDesc varchar(30) NULL,	-- ltblFasterDiagnosisCommunicationMethod.Description
			FastDiagOtherCommMethod varchar(50) NULL,	-- tblMAIN_REFERRALS.FasterDiagnosisOtherCommunicationMethod
			FastDiagInformingCareProfID int NULL,		-- tblMAIN_REFERRALS.FasterDiagnosisInformingCareProfessionalID
			FastDiagInformingCareProfCode varchar(3) NULL,	-- ltblCareProfessional.DataDictionaryCode
			FastDiagInformingCareProfDesc varchar(70) NULL,	-- ltblCareProfessional.Description
			FastDiagOtherCareProf varchar(50) NULL,		-- tblMAIN_REFERRALS.FasterDiagnosisOtherCareProfessional
			-- Diagnoses
			DateDiagnosis smalldatetime NULL,			-- N4_1_DIAGNOSIS_DATE
			AgeAtDiagnosis int NULL,
			DiagnosisCode varchar(5) NULL,				-- L_Diagnosis
			DiagnosisSubCode varchar(5) NULL,			-- N4_2_DIAGNOSIS_CODE
			DiagnosisDesc varchar(150) NULL,
			DiagnosisSubDesc varchar(150) NULL,
			OrgIdDiagnosis int NULL,					-- OrganisationSites.Id
			OrgCodeDiagnosis varchar(5) NULL,			-- L_ORG_CODE_DIAGNOSIS
			OrgDescDiagnosis varchar(250) NULL,			-- OrganisationSites.Description
			SnomedCT_ID int NULL,						-- SNOMed_CT
			SnomedCT_MCode varchar(10),					-- ltblSNOMedCT.Code - derived from tblMAIN_REFERRALS.SNOMed_CT = ltblSNOMedCT.CT_Snomed_ID
			SnomedCT_ConceptID bigint NULL,				-- ltblSNOMedCT.CT_Concept_ID - derived from tblMAIN_REFERRALS.SNOMed_CT = ltblSNOMedCT.CT_Snomed_ID
			SnomedCT_Desc varchar(100) NULL,			-- ltblSNOMedCT.CT_Description - derived from tblMAIN_REFERRALS.SNOMed_CT = ltblSNOMedCT.CT_Snomed_ID
			Histology varchar(10) NULL,					-- N4_5_HISTOLOGY
			-- Referral Waits data
			DateReceipt smalldatetime NULL,				-- N2_6_RECEIPT_DATE
			AgeAtReferral int NULL,
			AppointmentCancelledDate smalldatetime NULL,-- L_CANCELLED_DATE
			DateConsultantUpgrade smalldatetime NULL,	-- N_UPGRADE_DATE
			DateFirstSeen smalldatetime NULL,			-- N2_9_FIRST_SEEN_DATE
			OrgIdUpgrade int NULL,						-- OrganisationSites.Id
			OrgCodeUpgrade varchar(5) NULL,				-- N_UPGRADE_ORG_CODE
			OrgDescUpgrade varchar(250) NULL,			-- OrganisationSites.Description
			OrgIdFirstSeen int NULL,					-- OrganisationSites.Id
			OrgCodeFirstSeen varchar(5) NULL,			-- N1_3_ORG_CODE_SEEN
			OrgDescFirstSeen varchar(250) NULL,			-- OrganisationSites.Description
			FirstAppointmentTypeCode int NULL,			-- L_FIRST_APP
			FirstAppointmentTypeDesc varchar(255) NULL,
			FirstAppointmentOffered int NULL,			-- L_FIRST_APPOINTMENT
			ReasonNoAppointmentCode int NULL,			-- L_NO_APP
			ReasonNoAppointmentDesc varchar(255) NULL,
			FirstSeenAdjTime int NULL,					-- N2_14_ADJ_TIME
			FirstSeenAdjReasonCode int NULL,			-- N2_15_ADJ_REASON			
			FirstSeenAdjReasonDesc varchar(150) NULL,
			FirstSeenDelayReasonCode int NULL,			-- N2_10_FIRST_SEEN_DELAY
			FirstSeenDelayReasonDesc varchar(255) NULL,
			FirstSeenDelayReasonComment varchar(MAX) NULL, -- N2_11_FIRST_SEEN_REASON
			DTTAdjTime int NULL,						-- N16_2_ADJ_DAYS
			DTTAdjReasonCode int NULL,					-- N16_4_ADJ_TREAT_CODE
			DTTAdjReasonDesc varchar(150) NULL,			-- ltblADJ_TREATMENT.ADJ_REASON_DESC
			-- Referral data flags
			IsBCC int NULL,
			IsCwtCancerDiagnosis int NULL,
			UnderCancerCareFlag int NULL,
			-- Provenance
			RefreshMaxActionDate datetime NULL,			-- The date of the last action in the tblAUDIT table when the last reporting data update was performed
			ReportDate datetime NULL,					-- The runtime date when the last reporting data update was performed
			-- TECHNICAL DEBT -- Tracking 
			DateLastTracked datetime NULL,
			DaysSinceLastTracked int NULL
			
			)

		-- DROP SCR_CWT_work table if it exists
		if object_ID('SCR_Warehouse.SCR_CWT_work') is not null 
		   DROP TABLE SCR_Warehouse.SCR_CWT_work
		 
		-- Create SCR CWT Work table
		CREATE TABLE SCR_Warehouse.SCR_CWT_work(
			-- ID's
			CWTInsertIx int NOT NULL IDENTITY(1,1),		-- An identity field to provide us with an initial primary key and provide a reference to the order records were inserted (autonumber)
			OriginalCWTInsertIx int NULL,				-- A record of the CWTInsertIx used in processing incremental records before we append to the SCR_CWT table
			CARE_ID int NOT NULL,
			CWT_ID varchar(255) NOT NULL DEFAULT '',	-- Composite Key for the CWT record (careid, treatmentid, all modality ids)
			Tx_ID varchar(255) NOT NULL DEFAULT '',		-- Composite Key for the modality specific treatment (careid, all modality ids)
			TREATMENT_ID int NULL,						-- CWT record ID
			TREAT_ID int NULL,							-- CWT record link to modality specific Treatment ID
			CHEMO_ID int NULL,							-- modality specific Treatment ID from the tblMAIN_CHEMOTHERAPY table
			TELE_ID int NULL,							-- modality specific Treatment ID from the tblMAIN_TELETHERAPY table
			PALL_ID int NULL,							-- modality specific Treatment ID from the tblMAIN_PALLIATIVE table
			BRACHY_ID int NULL,							-- modality specific Treatment ID from the tblMAIN_BRACHYTHERAPY table
			OTHER_ID int NULL,							-- modality specific Treatment ID from the tblOTHER_TREATMENT table
			SURGERY_ID int NULL,						-- modality specific Treatment ID from the tblMAIN_SURGERY table
			MONITOR_ID int NULL,						-- modality specific Treatment ID from the tblMONITORING table
			ChemoActionId int NULL,						-- audit trail action ID from the tblMAIN_CHEMOTHERAPY table
			TeleActionId int NULL,						-- audit trail action ID from the tblMAIN_TELETHERAPY table
			PallActionId int NULL,						-- audit trail action ID from the tblMAIN_PALLIATIVE table
			BrachyActionId int NULL,					-- audit trail action ID from the tblMAIN_BRACHYTHERAPY table
			OtherActionId int NULL,						-- audit trail action ID from the tblOTHER_TREATMENT table
			SurgeryActionId int NULL,					-- audit trail action ID from the tblMAIN_SURGERY table
			MonitorActionId int NULL,					-- audit trail action ID from the tblMONITORING table
			-- Definitive Treatment Waits data (treatments, or potential to treat, with CWT flags)
			DeftTreatmentEventCode varchar(2) NULL,
			DeftTreatmentEventDesc varchar(100) NULL,			
			DeftTreatmentCode char(2) NULL,			
			DeftTreatmentDesc varchar(100) NULL,
			DeftTreatmentSettingCode varchar(50) NULL,
			DeftTreatmentSettingDesc varchar(100) NULL,
			DeftDateDecisionTreat smalldatetime NULL,
			DeftDateTreatment smalldatetime NULL,
			DeftDTTAdjTime int NULL,
			DeftDTTAdjReasonCode int NULL,							-- Deft.ADJ_CODE
			DeftDTTAdjReasonDesc varchar(150) NULL,					-- ltblADJ_TREATMENT.ADJ_REASON_DESC
			DeftOrgIdDecisionTreat int NULL,						-- OrganisationSites.Id
			DeftOrgCodeDecisionTreat varchar(5) NULL,
			DeftOrgDescDecisionTreat varchar(250) NULL,				-- OrganisationSites.Description
			DeftOrgIdTreatment int NULL,							-- OrganisationSites.Id
			DeftOrgCodeTreatment varchar(5) NULL,
			DeftOrgDescTreatment varchar(250) NULL,					-- OrganisationSites.Description
			DeftDefinitiveTreatment int NULL,
			DeftChemoRT varchar(2) NULL,							-- The CHEMO_RT data from tblDEFINITIVE_TREATMENT - has a value of 'C' where Chemotherapy is the 1st treatment in a combined treatment regime and 'R' where Radiotherapy is the 1st treatment
			-- Treatment Modality Treatment Waits data
			TxModTreatmentEventCode varchar(2) NULL,
			TxModTreatmentEventDesc varchar(100) NULL,			
			TxModTreatmentCode char(2) NULL,			
			TxModTreatmentDesc varchar(100) NULL,
			TxModTreatmentSettingCode varchar(50) NULL,
			TxModTreatmentSettingDesc varchar(100) NULL,
			TxModDateDecisionTreat smalldatetime NULL,
			TxModDateTreatment smalldatetime NULL,
			TxModOrgIdDecisionTreat int NULL,						-- OrganisationSites.Id
			TxModOrgCodeDecisionTreat varchar(5) NULL,
			TxModOrgDescDecisionTreat varchar(250) NULL,			-- OrganisationSites.Description
			TxModOrgIdTreatment int NULL,							-- OrganisationSites.Id
			TxModOrgCodeTreatment varchar(5) NULL,
			TxModOrgDescTreatment varchar(250) NULL,				-- OrganisationSites.Description
			TxModDefinitiveTreatment int NULL,
			TxModChemoRadio varchar(2) NULL,						-- The ChemoRadio data from the treatment modality table - has a value of 1 where the treatment is part of a combined treatment regime and 0 if not
			TxModChemoRT varchar(2) NULL,							-- Designed to work like the CHEMO_RT data from tblDEFINITIVE_TREATMENT using the data from the treatment modality table - has a value of 'C' where Chemotherapy is the 1st treatment in a combined treatment regime and 'R' where Radiotherapy is the 1st treatment
			TxModModalitySubCode varchar(2) NULL,
			TxModRadioSurgery varchar(2) NULL,
			-- ChemoRT Treatment Modality Treatment Waits data 
			ChemRtLinkTreatmentEventCode varchar(2) NULL,
			ChemRtLinkTreatmentEventDesc varchar(100) NULL,			
			ChemRtLinkTreatmentCode char(2) NULL,			
			ChemRtLinkTreatmentDesc varchar(100) NULL,
			ChemRtLinkTreatmentSettingCode varchar(50) NULL,
			ChemRtLinkTreatmentSettingDesc varchar(100) NULL,
			ChemRtLinkDateDecisionTreat smalldatetime NULL,
			ChemRtLinkDateTreatment smalldatetime NULL,
			ChemRtLinkOrgIdDecisionTreat int NULL,					-- OrganisationSites.Id
			ChemRtLinkOrgCodeDecisionTreat varchar(5) NULL,
			ChemRtLinkOrgDescDecisionTreat varchar(250) NULL,		-- OrganisationSites.Description
			ChemRtLinkOrgIdTreatment int NULL,						-- OrganisationSites.Id
			ChemRtLinkOrgCodeTreatment varchar(5) NULL,
			ChemRtLinkOrgDescTreatment varchar(250) NULL,			-- OrganisationSites.Description
			ChemRtLinkDefinitiveTreatment int NULL,
			ChemRtLinkChemoRadio varchar(2) NULL,					-- The ChemoRadio data from the treatment modality table - has a value of 1 where the treatment is part of a combined treatment regime and 0 if not
			ChemRtLinkModalitySubCode varchar(2) NULL,
			ChemRtLinkRadioSurgery varchar(2) NULL,
			-- Waits Data Flags
			cwtFlag2WW int NULL,									-- A flag that represents whether the 2WW CWT is closed (non-reportable), open or reportable (and closed)
			cwtFlag28  int NULL,									-- A flag that represents whether the 28 day faster treatment CWT is closed (non-reportable), open or reportable (and closed)
			cwtFlag31  int NULL,									-- A flag that represents whether the 31 day CWT is closed (non-reportable), open or reportable (and closed)
			cwtFlag62  int NULL,									-- A flag that represents whether the 62 day CWT is closed (non-reportable), open or reportable (and closed)
			cwtType2WW int NULL,									-- A representation of the type of 2WW pathway that this CWT is classified as
			cwtType28  int NULL,									-- A representation of the type of 28 day faster treatment pathway that this CWT is classified as
			cwtType31  int NULL,									-- A representation of the type of 31 day pathway that this CWT is classified as
			cwtType62  int NULL,									-- A representation of the type of 62 day pathway that this CWT is classified as
			cwtReason2WW int NULL,									-- The component of the CWT flag setting case statment that was true for the CWT flag to have ended up with it's current value
			cwtReason28  int NULL,									-- The component of the CWT flag setting case statment that was true for the CWT flag to have ended up with it's current value
			cwtReason31  int NULL,									-- The component of the CWT flag setting case statment that was true for the CWT flag to have ended up with it's current value
			cwtReason62  int NULL,									-- The component of the CWT flag setting case statment that was true for the CWT flag to have ended up with it's current value	
			HasTxMod int NULL DEFAULT 0,							-- Flags the presence of the Treatment Modality (TxMod) Record (1 = updated as a part of an existing DEFT record, 2 = inserted because there was no DEFT record)
			HasChemRtLink int NULL DEFAULT 0,						-- Flags the presence of the ChemoRT-linked Treatment Modality (TxMod) Record (1 = updated as a part of an existing DEFT record, 2 = inserted because there was no DEFT record)	
			-- CWT Wait Calculations
			ClockStartDate2WW smalldatetime NULL,
			ClockStartDate28 smalldatetime NULL,
			ClockStartDate31 smalldatetime NULL,
			ClockStartDate62 smalldatetime NULL,
			AdjTime2WW int NULL,
			AdjTime28 int NULL,
			AdjTime31 int NULL,
			AdjTime62 int NULL,
			TargetDate2WW smalldatetime NULL,
			TargetDate28 smalldatetime NULL,
			TargetDate31 smalldatetime NULL,
			TargetDate62 smalldatetime NULL,
			DaysTo2WWBreach int NULL,
			DaysTo28DayBreach int NULL,
			DaysTo31DayBreach int NULL,
			DaysTo62DayBreach int NULL,
			ClockStopDate2WW smalldatetime NULL,
			ClockStopDate28 smalldatetime NULL,
			ClockStopDate31 smalldatetime NULL,
			ClockStopDate62 smalldatetime NULL,
			Waitingtime2WW int NULL,
			Waitingtime28 int NULL,
			Waitingtime31 int NULL,
			Waitingtime62 int NULL,
			Breach2WW int NULL,
			Breach28 int NULL,
			Breach31 int NULL,
			Breach62 int NULL,
			WillBeClockStopDate2WW smalldatetime NULL,
			WillBeClockStopDate28 smalldatetime NULL,
			WillBeClockStopDate31 smalldatetime NULL,
			WillBeClockStopDate62 smalldatetime NULL,
			WillBeWaitingtime2WW int NULL,
			WillBeWaitingtime28 int NULL,
			WillBeWaitingtime31 int NULL,
			WillBeWaitingtime62 int NULL,
			WillBeBreach2WW int NULL,
			WillBeBreach28 int NULL,
			WillBeBreach31 int NULL,
			WillBeBreach62 int NULL,
			DaysTo62DayBreachNoDTT int NULL,
			Treated7Days int NULL,
			Treated7Days62Days int NULL,
			FutureAchieve62Days int NULL,
			FutureFail62Days int NULL,
			ActualWaitDTTTreatment int NULL,
			DTTTreated7Days int NULL,
			Treated7Days31Days int NULL,
			Treated7DaysBreach31Days int NULL,
			FutureAchieve31Days int NULL,
			FutureFail31Days int NULL,
			FutureDTT int NULL,
			NoDTTDate int NULL,
			-- Provenance
			LastCommentUser varchar(50) NULL,
			LastCommentDate datetime NULL,
			ReportDate datetime NULL,								-- The runtime date when the last reporting data update was performed
			-- TECHNICAL DEBT -- PTL Status
			DominantCWTStatusCode int NULL,
			DominantCWTStatusDesc varchar (255) NULL,
			CWTStatusCode2WW int NULL,
			CWTStatusDesc2WW varchar (255) NULL,
			CWTStatusCode28 int NULL,
			CWTStatusDesc28 varchar (255) NULL,
			CWTStatusCode31 int NULL,
			CWTStatusDesc31 varchar (255) NULL,
			CWTStatusCode62 int NULL,
			CWTStatusDesc62 varchar (255) NULL,
			Pathway varchar (255) NULL,
			ReportingPathwayLength int NULL,
			Weighting numeric (2,1) NULL,
			-- TECHNICAL DEBT --PTL RAG
			DominantColourValue varchar (255) NULL,				-- Determines the report row RAG colour for each waiting time standard
			ColourValue2WW varchar (255) NULL,
			ColourValue28Day varchar (255) NULL,
			ColourValue31Day varchar (255) NULL,
			ColourValue62Day varchar (255) NULL,
			DominantColourDesc varchar (255) NULL,
			ColourDesc2WW varchar (255) NULL,
			ColourDesc28Day varchar (255) NULL,
			ColourDesc31Day varchar (255) NULL,
			ColourDesc62Day varchar (255) NULL,
			DominantPriority int NULL,
			Priority2WW int NULL,
			Priority28 int NULL,
			Priority31 int NULL,
			Priority62 int NULL
		)

		-- Create a Primary Key for the CWT table
		ALTER TABLE SCR_Warehouse.SCR_CWT_work		-- sets CWTInsertIx as Primary key
		ADD CONSTRAINT PK_SCR_CWT_work PRIMARY KEY (
				CWTInsertIx ASC 
				)


/************************************************************************************************************************************************************************************************************
-- Create the table of Incremental Care ID's (if we are doing an incremental update)
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the incremental update started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'Incremental Update'
				
		-- DROP #Incremental table if it exists
		if object_ID('tempdb.dbo.#Incremental') is not null 
		   DROP TABLE #Incremental
		 
		-- Create an #Incremental table of CARE_IDs to be updated incrementally (so we have an 
		-- empty table that exists where we are not doing an incremental update and so we can 
		-- define CARE_ID as NOT NULL for the Primary Key)
		CREATE TABLE	#Incremental
					(
					CARE_ID int NOT NULL
					)
				
		-- Declare the @ReportDate and @RefreshMaxActionDate variables
		DECLARE	@ReportDate datetime
		DECLARE	@RefreshMaxActionDate datetime
		 
		-- Capture the most recent tblAUDIT timestamp, at the start of the update process, to 
		-- control the record retrieval and to be recorded in the ReportDate Field
		SELECT		@ReportDate = GETDATE()
					,@RefreshMaxActionDate = MAX(ACTION_DATE)
		FROM		LocalConfig.tblAUDIT
		
		-- Insert the Incremental Care ID's (if we are doing an incremental update)
		IF @IncrementalUpdate = 1
		BEGIN
			
				-- Declare the @ReferralRefreshMaxActionDate variable
				DECLARE		@ReferralRefreshMaxActionDate datetime

				-- Assign the last RefreshMaxActionDate from SCR_Referrals to @ReferralRefreshMaxActionDate
				SELECT		@ReferralRefreshMaxActionDate = MAX(RefreshMaxActionDate)
				FROM		SCR_Warehouse.SCR_Referrals
			
				-- Insert CARE_IDs into the #Incremental table from tblAUDIT where the ACTION_DATE is
				-- after the last RefreshMaxActionDate from the SCR_Referrals dataset
				INSERT INTO	#Incremental
							(
							CARE_ID
							)
				SELECT		CARE_ID					=	a.CARE_ID
				FROM		LocalConfig.tblAUDIT a
				WHERE		a.CARE_ID IS NOT NULL
				AND			(a.ACTION_DATE >= @ReferralRefreshMaxActionDate	-- on or after the last action date used to process SCR_Referrals (note that the ACTION_DATE is only accurate to the minute, so we must take records with an equal value)
				OR			@ReferralRefreshMaxActionDate IS NULL			-- return all records if SCR_Referrals has no last action dates
							)
				GROUP BY	a.CARE_ID
				
				-- Insert CARE_IDs into the #Incremental table from tblAUDIT_DELETIONS where the ACTION_DATE is
				-- after the last RefreshMaxActionDate from the SCR_Referrals dataset
				INSERT INTO	#Incremental
							(
							CARE_ID
							)
				SELECT		CARE_ID					=	mainref.CARE_ID
				FROM		LocalConfig.tblAUDIT_DELETIONS ad
				INNER JOIN	LocalConfig.tblDEMOGRAPHICS dem
								ON	ad.HOSPITAL_NUMBER = dem.N1_2_HOSPITAL_NUMBER
								OR	ad.NHS_NUMBER = dem.NHS_NUMBER_STATUS
				INNER JOIN	LocalConfig.tblMAIN_REFERRALS mainref
								ON	dem.PATIENT_ID = mainref.PATIENT_ID
				LEFT JOIN	#Incremental Inc
								ON	mainref.CARE_ID = Inc.CARE_ID
				WHERE		mainref.CARE_ID IS NOT NULL
				AND			Inc.CARE_ID IS NULL									-- not already in the #Incremental table
				AND			(ad.DATE_DELETED >= @ReferralRefreshMaxActionDate	-- on or after the last action date used to process SCR_Referrals (note that the ACTION_DATE is only accurate to the minute, so we must take records with an equal value)
				OR			@ReferralRefreshMaxActionDate IS NULL			-- return all records if SCR_Referrals has no last action dates
							)
				GROUP BY	mainref.CARE_ID
				
				-- Create a Primary Key for the #Incremental table
				ALTER TABLE #Incremental 
				ADD CONSTRAINT PK_IncrementalCareId PRIMARY KEY (
						CARE_ID ASC 
						)

		END
				
		-- Keep a record of when the incremental update finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'Incremental Update'
				
/************************************************************************************************************************************************************************************************************
-- Initial Population of SCR Referrals Work table for every Cancer Pathway (Referral)
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the Initial Population of SCR Referrals started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'Initial Population of SCR Referrals'
				
		-- Insert all pathway level data from records in tblMAIN_REFERRALS (Cancer Pathways) 
		INSERT into SCR_Warehouse.SCR_Referrals_work (
					CARE_ID
					,PatientPathwayIdIssuer
					,Patient_ID
					,MainRefActionId
					,DiagnosisActionId
					,CancerSite
					,CancerSiteBS
					,CancerSubSiteCode
					,CancerTypeCode
					,PriorityTypeCode
					,SourceReferralCode
					,ReferralMethodCode
					,DecisionToReferDate
					,TumourStatusCode
					,PatientStatusCode
					,PatientStatusCodeCwt
					,ConsultantCode
					,InappropriateRef
					,TransferReason
					,TransferNewRefDate
					,TransferTumourSiteCode
					,TransferTumourSiteDesc
					,TransferActionedDate
					,TransferSourceCareId
					,TransferOrigSourceCareId
					,FastDiagInformedDate
					,FastDiagExclDate
					,FastDiagCancerSiteOverrideID
					,FastDiagDelayReasonID
					,FastDiagDelayReasonComments
					,FastDiagExclReasonID
					,FastDiagOrgID
					,FastDiagCommMethodID
					,FastDiagOtherCommMethod
					,FastDiagInformingCareProfID
					,FastDiagOtherCareProf
					,DateDiagnosis
					,DiagnosisCode
					,DiagnosisSubCode
					,OrgCodeDiagnosis
					,SnomedCT_ID
					,Histology
					,DateReceipt
					,AppointmentCancelledDate
					,DateConsultantUpgrade
					,DateFirstSeen
					,OrgCodeUpgrade
					,OrgCodeFirstSeen	
					,FirstAppointmentTypeCode
					,FirstAppointmentOffered
					,ReasonNoAppointmentCode
					,FirstSeenAdjTime			
					,FirstSeenAdjReasonCode
					,FirstSeenDelayReasonCode
					,FirstSeenDelayReasonComment
					,DTTAdjTime
					,DTTAdjReasonCode
					,RefreshMaxActionDate
					,ReportDate
					)
		SELECT
					CARE_ID							=	mainref.CARE_ID
					,PatientPathwayIdIssuer			=	CASE	WHEN	mainref.L_REFERRAL_METHOD = 7
																THEN	'X09'
																ELSE	LEFT(mainref.N1_3_ORG_CODE_SEEN, 3)
																END
					,Patient_ID						=	mainref.Patient_ID
					,MainRefActionId				=	mainref.ACTION_ID
					,DiagnosisActionId				=	mainref.DIAGNOSIS_ACTION_ID
					,CancerSite						=	mainref.[L_CANCER_SITE]  
					,CancerSiteBS					=	Case	
														when	mainref.N2_12_CANCER_TYPE  = 16 then 'Breast Symptomatic'    
														else	(mainref.l_cancer_site) 
														end		
					,CancerSubSiteCode				=	mainref.SubsiteID
					,CancerTypeCode					=	mainref.N2_12_CANCER_TYPE	
					,PriorityTypeCode				=	mainref.N2_4_PRIORITY_TYPE
					,SourceReferralCode				=	mainref.N2_16_OP_REFERRAL
					,ReferralMethodCode				=	mainref.L_REFERRAL_METHOD
					,DecisionToReferDate			=	mainref.N2_5_DECISION_DATE
					,TumourStatusCode				=	mainref.L_TUMOUR_STATUS
					,PatientStatusCode				=	mainref.N2_13_CANCER_STATUS
					,PatientStatusCodeCwt			=	CASE	WHEN mainref.N2_13_CANCER_STATUS = '69'
																THEN '03'
																ELSE mainref.N2_13_CANCER_STATUS
																END
					,ConsultantCode					=	mainref.N2_7_CONSULTANT
					,InappropriateRef				=	mainref.L_INAP_REF
					,TransferReason					=	mainref.TRANSFER_REASON
					,TransferNewRefDate				=	mainref.DATE_NEW_REFERRAL
					,TransferTumourSiteCode			=	mainref.TUMOUR_SITE_NEW
					,TransferTumourSiteDesc			=	mainref.L_NEW_CA_SITE
					,TransferActionedDate			=	mainref.DATE_TRANSFER_ACTIONED
					,TransferSourceCareId			=	mainref.SOURCE_CARE_ID
					,TransferOrigSourceCareId		=	mainref.ORIGINAL_SOURCE_CARE_ID
					,FastDiagInformedDate			=	mainref.L_PT_INFORMED_DATE
					,FastDiagExclDate				=	mainref.FasterDiagnosisExclusionDate
					,FastDiagCancerSiteOverrideID	=	mainref.FasterDiagnosisCancerSiteOverrideID
					,FastDiagDelayReasonID			=	mainref.FasterDiagnosisDelayReasonID
					,FastDiagDelayReasonComments	=	mainref.FasterDiagnosisDelayReasonComments
					,FastDiagExclReasonID			=	mainref.FasterDiagnosisExclusionReasonID
					,FastDiagOrgID					=	mainref.FasterDiagnosisOrganisationID
					,FastDiagCommMethodID			=	mainref.FasterDiagnosisCommunicationMethodID
					,FastDiagOtherCommMethod		=	mainref.FasterDiagnosisOtherCommunicationMethod
					,FastDiagInformingCareProfID	=	mainref.FasterDiagnosisInformingCareProfessionalID
					,FastDiagOtherCareProf			=	mainref.FasterDiagnosisOtherCareProfessional
					,DateDiagnosis					=	mainref.N4_1_DIAGNOSIS_DATE 
					,DiagnosisCode					=	CASE WHEN mainref.L_Diagnosis = '' THEN CAST(NULL AS varchar(255)) ELSE mainref.L_Diagnosis END
					,DiagnosisSubCode				=	CASE WHEN mainref.N4_2_DIAGNOSIS_CODE = '' THEN CAST(NULL AS varchar(255)) ELSE mainref.N4_2_DIAGNOSIS_CODE END
					,OrgCodeDiagnosis				=	mainref.L_ORG_CODE_DIAGNOSIS
					,SnomedCT_ID					=	mainref.SNOMed_CT
					,Histology						=	mainref.N4_5_HISTOLOGY	
					,DateReceipt					=	mainref.[N2_6_RECEIPT_DATE]	--2ww and 62 day Ref2Treat clock start date
					,AppointmentCancelledDate		=	mainref.L_CANCELLED_DATE
					,DateConsultantUpgrade			=	mainref.N_UPGRADE_DATE
					,DateFirstSeen					=	mainref.[N2_9_FIRST_SEEN_DATE] --2ww clock stop date
					,OrgCodeUpgrade					=	mainref.N_UPGRADE_ORG_CODE	
					,OrgCodeFirstSeen				=	mainref.[N1_3_ORG_CODE_SEEN]
					,FirstAppointmentTypeCode		=	mainref.L_FIRST_APP
					,FirstAppointmentOffered		=	mainref.L_FIRST_APPOINTMENT
					,ReasonNoAppointmentCode		=	mainref.L_NO_APP
					,FirstSeenAdjTime				=	mainref.N2_14_ADJ_TIME       
					,FirstSeenAdjReasonCode			=	mainref.[N2_15_ADJ_REASON]
					,FirstSeenDelayReasonCode		=	mainref.N2_10_FIRST_SEEN_DELAY
					,FirstSeenDelayReasonComment	=	mainref.N2_11_FIRST_SEEN_REASON
					,DTTAdjTime						=	mainref.N16_2_ADJ_DAYS
					,DTTAdjReasonCode				=	mainref.N16_4_ADJ_TREAT_CODE
					,RefreshMaxActionDate			=	@RefreshMaxActionDate
					,ReportDate						=	@ReportDate
		FROM		LocalConfig.[tblMAIN_REFERRALS] mainref	
		LEFT JOIN	#Incremental Inc
						ON	mainref.CARE_ID = Inc.CARE_ID
		WHERE		Inc.CARE_ID IS NOT NULL			-- The record is in the incremental dataset
		OR			mainref.CARE_ID IS NULL			-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0			-- We are doing a bulk load (in which case we should ignore the incremental dataset)

		-- Keep a record of when the Initial Population of SCR Referrals finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'Initial Population of SCR Referrals'
				


/************************************************************************************************************************************************************************************************************
-- Initial Population of SCR CWT Work table for every CWT / DefinitiveTreatment record (i.e. anything that is anywhere on a CWT or has previously been on a CWT)
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the Initial Population of SCR CWT started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'Initial Population of CWT Referrals'
				
		-- Insert all period level data from tblMAIN_REFERRALS (Cancer Pathways) and their associated record(s) (there can be more than 1 per pathway) 
		-- from tblDEFINITIVE_TREATMENT (CWT records) into SCR_CWT_work 
		INSERT into SCR_Warehouse.SCR_CWT_work (
					CARE_ID
					,Treatment_ID
					,TREAT_ID
					,DeftTreatmentEventCode	
					,DeftTreatmentCode			
					,DeftTreatmentSettingCode	
					,DeftDateDecisionTreat		
					,DeftDateTreatment
					,DeftDTTAdjTime	
					,DeftDTTAdjReasonCode	
					,DeftOrgCodeDecisionTreat		
					,DeftOrgCodeTreatment	
					,DeftDefinitiveTreatment	
					,DeftChemoRT
					,ReportDate	
					)
		SELECT                   --*** THIS SELECT STATEMENT NEEDs TO BE IN SAME ORDER AS INSERT INTO ABOVE***  
					Care_ID							=	deft.CARE_ID
					,Treatment_ID					=	deft.Treatment_ID
					,Treat_ID						=	deft.TREAT_ID
					,DeftTreatmentEventCode			=	Deft.TREATMENT_EVENT		
					,DeftTreatmentCode				=	Deft.TREATMENT				
					,DeftTreatmentSettingCode		=	Deft.TREATMENT_SETTING
					,DeftDateDecisionTreat			=	Deft.DECISION_DATE 			
					,DeftDateTreatment				=	Deft.START_DATE				
					,DeftDTTAdjTime					=	Deft.ADJ_DAYS				
					,DeftDTTAdjReasonCode			=	Deft.ADJ_CODE	    			
					,DeftOrgCodeDecisionTreat		=	Deft.ORG_CODE_DTT
					,DeftOrgCodeTreatment			=	Deft.ORG_CODE				
					,DeftDefinitiveTreatment		=	Deft.TREAT_NO	
					,DeftChemoRT					=	Deft.CHEMO_RT			
					,ReportDate						=	@ReportDate
		FROM		LocalConfig.tblDEFINITIVE_TREATMENT Deft 
		LEFT JOIN	#Incremental Inc
						ON	deft.CARE_ID = Inc.CARE_ID
		WHERE		Inc.CARE_ID IS NOT NULL			-- The record is in the incremental dataset
		OR			deft.CARE_ID IS NULL			-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0			-- We are doing a bulk load (in which case we should ignore the incremental dataset)
	
		-- Keep a record of when the Initial Population of SCR CWT finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'Initial Population of CWT Referrals'
				


/************************************************************************************************************************************************************************************************************
-- Update the modality specific treatment columns for every treatment modality record related to a definitive treatment record (Tx mod columns)
-- NB: this doesn't update treatment modality records if they are marked as the adjunctive component of ChemoRadioTherapy (DEFINITIVE_TREATMENT = 99) as these are dealt with later
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the TxMod columns update started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'TxMod columns update'
				
		-- Create an Index to join to the treatment modality tables
		CREATE NONCLUSTERED INDEX Ix_TxMod_Work ON SCR_Warehouse.SCR_CWT_work (
				CARE_ID ASC
				,TREAT_ID ASC
				,DeftTreatmentCode ASC
				,DeftChemoRT
				)
		
		-- Update the CHEMO_ID column and TxMod columns where there is a corresponding record in tblMAIN_CHEMOTHERAPY
		UPDATE		CWT
		SET			CWT.CHEMO_ID						=	Tx.CHEMO_ID
					,CWT.ChemoActionId					=	Tx.ACTION_ID
					,CWT.TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
					,CWT.TxModTreatmentCode				=	CASE
																WHEN Tx.N_CHEMORADIO = '1'
																	THEN '04'
																WHEN ISNULL(Tx.N9_7_THERAPY_TYPE, '') IN ('C', 'W', 'Y')
																	THEN '02'
																WHEN ISNULL(Tx.N9_7_THERAPY_TYPE, '') IN ('I', 'X', 'Z')
																	THEN '15'
																WHEN Tx.N9_7_THERAPY_TYPE = 'H'
																	THEN '03'
																WHEN Tx.N9_7_THERAPY_TYPE = 'V'
																	THEN '21'
																ELSE '14'
															END
					,CWT.TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
					,CWT.TxModDateDecisionTreat			=	Tx.N9_4_DECISION_DATE
					,CWT.TxModDateTreatment				=	Tx.N9_10_START_DATE
					,CWT.TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
					,CWT.TxModOrgCodeTreatment			=	Tx.N9_1_SITE_CODE
					,CWT.TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
					,CWT.TxModChemoRadio				=	Tx.N_CHEMORADIO
					,CWT.TxModChemoRT					=	CASE WHEN Tx.N_CHEMORADIO = 1 THEN 'C' ELSE CAST(NULL AS varchar(2)) END
					,CWT.TxModModalitySubCode			=	Tx.N9_7_THERAPY_TYPE
					,CWT.HasTxMod						=	1
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	LocalConfig.tblMAIN_CHEMOTHERAPY Tx
						ON	CWT.TREAT_ID = Tx.CHEMO_ID
						AND	CWT.CARE_ID = Tx.CARE_ID
						AND	ISNULL(Tx.DEFINITIVE_TREATMENT,0) != 99				-- excludes 99 which are adjunctive chemo RTs 
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL								-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL										-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)									-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			(CWT.DeftTreatmentCode IN ('02','03', '14', '15', '21')	-- codes from ltblDEFINITIVE_TYPE that represent CHEMO
		OR			(CWT.DeftTreatmentCode = '04'							-- code from ltblDEFINITIVE_TYPE that represents CHEMORADIOTHERAPY
		AND			CWT.DeftChemoRT = 'C'))									-- code within tbl_DEFINITIVETREATMENT that tells us this CHEMORADIOTHERAPY has CHEMO as the "first" treatment	


		-- Update the TELE_ID column and TxMod columns where there is a corresponding record in tblMAIN_TELETHERAPY
		UPDATE		CWT
		SET			CWT.TELE_ID							=	Tx.TELE_ID
					,CWT.TeleActionId					=	Tx.ACTION_ID
					,CWT.TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
					,CWT.TxModTreatmentCode				=	CASE
																WHEN Tx.BRAIN_RADIOSURGERY_INDICATOR = 'Y'
																	THEN '22'
																WHEN Tx.N_CHEMORADIO = '1'
																	THEN '04'
																WHEN ISNULL(Tx.N10_16_BEAM_TYPE, '') IN ('z')
																	THEN '13'
																ELSE '05'
															END
					,CWT.TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
					,CWT.TxModDateDecisionTreat			=	Tx.N10_3_DECISION_DATE
					,CWT.TxModDateTreatment				=	Tx.N10_8_START_DATE
					,CWT.TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
					,CWT.TxModOrgCodeTreatment			=	Tx.N10_1_SITE_CODE
					,CWT.TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
					,CWT.TxModChemoRadio				=	Tx.N_CHEMORADIO
					,CWT.TxModChemoRT					=	CASE WHEN Tx.N_CHEMORADIO = 1 THEN 'R' ELSE CAST(NULL AS varchar(2)) END
					,CWT.TxModModalitySubCode			=	Tx.N10_16_BEAM_TYPE
					,CWT.TxModRadioSurgery				=	Tx.BRAIN_RADIOSURGERY_INDICATOR
					,CWT.HasTxMod						=	1
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	LocalConfig.tblMAIN_TELETHERAPY Tx
						ON	CWT.TREAT_ID = Tx.TELE_ID
						AND	CWT.CARE_ID = Tx.CARE_ID
						AND	ISNULL(Tx.DEFINITIVE_TREATMENT,0) != 99			-- excludes 99 which are adjunctive chemo RTs
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			(CWT.DeftTreatmentCode IN ('05','13', '22') -- codes from ltblDEFINITIVE_TYPE that represent RADIOTHERAPY
		OR			(CWT.DeftTreatmentCode = '04'				-- code from ltblDEFINITIVE_TYPE that represents CHEMORADIOTHERAPY
		AND			CWT.DeftChemoRT = 'R'))						-- code within tbl_DEFINITIVETREATMENT that tells us this CHEMORADIOTHERAPY has RADIOTHERAPY as the "first" treatment	


		-- Update the PALL_ID column and TxMod columns where there is a corresponding record in tblMAIN_PALLIATIVE
		UPDATE		CWT
		SET			CWT.PALL_ID = Tx.PALL_ID
					,CWT.PallActionId					=	Tx.ACTION_ID
					,CWT.TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
					,CWT.TxModTreatmentCode				=	Tx.N_SPECIALIST
					,CWT.TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
					,CWT.TxModDateDecisionTreat			=	Tx.N12_1_DECISION_DATE
					,CWT.TxModDateTreatment				=	Tx.N12_2_START_DATE
					,CWT.TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
					,CWT.TxModOrgCodeTreatment			=	Tx.N1_3_ORG_CODE_TREATMENT
					,CWT.TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
					,CWT.HasTxMod						=	1
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	LocalConfig.tblMAIN_PALLIATIVE Tx
						ON	CWT.TREAT_ID = Tx.PALL_ID
						AND	CWT.CARE_ID = Tx.CARE_ID
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			CWT.DeftTreatmentCode IN ('07','09')		-- codes from ltblDEFINITIVE_TYPE that represent PALLIATIVE CARE


		-- Update the BRACHY_ID column and TxMod columns where there is a corresponding record in tblMAIN_BRACHYTHERAPY
		UPDATE		CWT
		SET			CWT.BRACHY_ID = Tx.BRACHY_ID
					,CWT.BrachyActionId					=	Tx.ACTION_ID
					,CWT.TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
					,CWT.TxModTreatmentCode				=	CASE
																WHEN Tx.N11_7_TYPE = 'US'
																	THEN '19'
																ELSE '06'
															END
					,CWT.TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
					,CWT.TxModDateDecisionTreat			=	Tx.N11_3_DECISION_DATE
					,CWT.TxModDateTreatment				=	Tx.N11_9_START_DATE
					,CWT.TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
					,CWT.TxModOrgCodeTreatment			=	Tx.N11_1_SITE_CODE
					,CWT.TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
					,CWT.TxModModalitySubCode			=	Tx.N11_7_TYPE
					,CWT.HasTxMod						=	1
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	LocalConfig.tblMAIN_BRACHYTHERAPY Tx
						ON	CWT.TREAT_ID = Tx.BRACHY_ID
						AND	CWT.CARE_ID = Tx.CARE_ID
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			CWT.DeftTreatmentCode IN ('06','19')		-- codes from ltblDEFINITIVE_TYPE that represent BRACHYTHERAPY


		-- Update the OTHER_ID column and TxMod columns where there is a corresponding record in tblOTHER_TREATMENT
		UPDATE		CWT
		SET			CWT.OTHER_ID = Tx.OTHER_ID
					,CWT.OtherActionId					=	Tx.ACTION_ID
					,CWT.TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
					,CWT.TxModTreatmentCode				=	'97'
					,CWT.TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
					,CWT.TxModDateDecisionTreat			=	Tx.N16_9_DECISION_ACTIVE
					,CWT.TxModDateTreatment				=	Tx.N16_10_START_ACTIVE
					,CWT.TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
					,CWT.TxModOrgCodeTreatment			=	Tx.N1_3_ORG_CODE_TREATMENT
					,CWT.TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
					,CWT.HasTxMod						=	1
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	LocalConfig.tblOTHER_TREATMENT Tx
						ON	CWT.TREAT_ID = Tx.OTHER_ID
						AND	CWT.CARE_ID = Tx.CARE_ID
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			CWT.DeftTreatmentCode IN ('97')				-- codes from ltblDEFINITIVE_TYPE that represent Other Treatments


		-- Update the SURGERY_ID column and TxMod columns where there is a corresponding record in tblMAIN_SURGERY
		UPDATE		CWT
		SET			CWT.SURGERY_ID = Tx.SURGERY_ID
					,CWT.SurgeryActionId				=	Tx.ACTION_ID
					,CWT.TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
					,CWT.TxModTreatmentCode				=	CWT.DeftTreatmentCode
					,CWT.TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
					,CWT.TxModDateDecisionTreat			=	Tx.N7_5_DECISION_DATE
					,CWT.TxModDateTreatment				=	Tx.N7_8_ADMISSION_DATE
					,CWT.TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
					,CWT.TxModOrgCodeTreatment			=	Tx.N7_1_SITE_CODE
					,CWT.TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
					,CWT.HasTxMod						=	1
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	LocalConfig.tblMAIN_SURGERY Tx
						ON	CWT.TREAT_ID = Tx.SURGERY_ID
						AND	CWT.CARE_ID = Tx.CARE_ID
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL										-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL												-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)											-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			CWT.DeftTreatmentCode IN ('01','10','11','12','16','17','20')	-- codes from ltblDEFINITIVE_TYPE that represent Surgery


		-- Update the MONITOR_ID column and TxMod columns where there is a corresponding record in tblMONITORING
		UPDATE		CWT
		SET			CWT.MONITOR_ID = Tx.MONITOR_ID
					,CWT.MonitorActionId				=	Tx.ACTION_ID
					,CWT.TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
					,CWT.TxModTreatmentCode				=	'08'
					,CWT.TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
					,CWT.TxModDateDecisionTreat			=	Tx.N16_9_DECISION_ACTIVE
					,CWT.TxModDateTreatment				=	Tx.N16_10_START_ACTIVE
					,CWT.TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
					,CWT.TxModOrgCodeTreatment			=	Tx.N1_3_ORG_CODE_TREATMENT
					,CWT.TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
					,CWT.HasTxMod						=	1
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	LocalConfig.tblMONITORING Tx
						ON	CWT.TREAT_ID = Tx.MONITOR_ID
						AND	CWT.CARE_ID = Tx.CARE_ID
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL		-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL				-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)			-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND		CWT.DeftTreatmentCode IN ('08')		-- codes from ltblDEFINITIVE_TYPE that represent Monitoring

		-- Keep a record of when the TxMod columns update finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'TxMod columns update'
				

/************************************************************************************************************************************************************************************************************
-- Create Indexes for the respective Treatment Modality ID's in the CWT table
-- NB: Currently it takes longer to build and then rebuild these after the subsequent insert statements than it does to simply do a table scan instead
************************************************************************************************************************************************************************************************************/

		---- Create an Index for CHEMO_ID
		--CREATE NONCLUSTERED INDEX Ix_CHEMO_ID ON SCR_Warehouse.SCR_CWT_work (
		--		Chemo_ID ASC
		--		)

		---- Create an Index for TELE_ID
		--CREATE NONCLUSTERED INDEX Ix_TELE_ID ON SCR_Warehouse.SCR_CWT_work (
		--		TELE_ID ASC
		--		)

		---- Create an Index for PALL_ID
		--CREATE NONCLUSTERED INDEX Ix_PALL_ID ON SCR_Warehouse.SCR_CWT_work (
		--		PALL_ID ASC
		--		)

		---- Create an Index for BRACHY_ID
		--CREATE NONCLUSTERED INDEX Ix_BRACHY_ID ON SCR_Warehouse.SCR_CWT_work (
		--		BRACHY_ID ASC
		--		)

		---- Create an Index for OTHER_ID
		--CREATE NONCLUSTERED INDEX Ix_OTHER_ID ON SCR_Warehouse.SCR_CWT_work (
		--		OTHER_ID ASC
		--		)

		---- Create an Index for SURGERY_ID
		--CREATE NONCLUSTERED INDEX Ix_SURGERY_ID ON SCR_Warehouse.SCR_CWT_work (
		--		SURGERY_ID ASC
		--		)

		---- Create an Index for MONITOR_ID
		--CREATE NONCLUSTERED INDEX Ix_MONITOR_ID ON SCR_Warehouse.SCR_CWT_work (
		--		MONITOR_ID ASC
		--		)


/************************************************************************************************************************************************************************************************************
-- Population of SCR CWT Work table for every treatment modality record (i.e. anything that may be on a CWT in the future) that isn't yet a definitive treatment so not in Deft table
-- NB: this doesn't insert treatment modality records if they are marked as the adjunctive component of ChemoRadioTherapy (DEFINITIVE_TREATMENT = 99) as these are dealt with later
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the TxMod columns insert started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'TxMod columns insert'
				
		-- Insert treatments from tblMAIN_CHEMOTHERAPY that aren't yet reportable as 31 day CWT (not in tblDEFINITIVE_TREATMENT), but have been entered as a treatment
		INSERT into SCR_Warehouse.SCR_CWT_work (
		CARE_ID
		,CHEMO_ID
		,ChemoActionId
		,TxModTreatmentEventCode
		,TxModTreatmentCode
		,TxModTreatmentSettingCode
		,TxModDateDecisionTreat
		,TxModDateTreatment
		,TxModOrgCodeDecisionTreat
		,TxModOrgCodeTreatment
		,TxModDefinitiveTreatment
		,TxModChemoRadio
		,TxModChemoRT					
		,TxModModalitySubCode		
		,HasTxMod	
		,ReportDate	
		)
		
		SELECT
		CARE_ID							=	Tx.CARE_ID
		,CHEMO_ID						=	Tx.CHEMO_ID
		,ChemoActionId					=	Tx.ACTION_ID
		,TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
		,TxModTreatmentCode				=	CASE
												WHEN N_CHEMORADIO = '1'
													THEN '04'
												WHEN ISNULL(N9_7_THERAPY_TYPE, '') IN ('C', 'W', 'Y')
													THEN '02'
												WHEN ISNULL(N9_7_THERAPY_TYPE, '') IN ('I', 'X', 'Z')
													THEN '15'
												WHEN N9_7_THERAPY_TYPE = 'H'
													THEN '03'
												WHEN N9_7_THERAPY_TYPE = 'V'
													THEN '21'
												ELSE '14'
											END
		,TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
		,TxModDateDecisionTreat			=	Tx.N9_4_DECISION_DATE
		,TxModDateTreatment				=	Tx.N9_10_START_DATE
		,TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
		,TxModOrgCodeTreatment			=	Tx.N9_1_SITE_CODE
		,TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
		,TxModChemoRadio				=	Tx.N_CHEMORADIO
		,TxModChemoRT					=	CASE WHEN Tx.N_CHEMORADIO = 1 THEN 'C' ELSE CAST(NULL AS varchar(2)) END
		,TxModModalitySubCode			=	Tx.N9_7_THERAPY_TYPE
		,HasTxMod						=	2
		,ReportDate						=	@ReportDate 				
			  
		FROM		LocalConfig.tblMAIN_CHEMOTHERAPY Tx 
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	TX.CHEMO_ID = CWT.CHEMO_ID 
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			isnull (Tx.DEFINITIVE_TREATMENT,0) <> 99	-- excludes 99 which are adjunctive chemo RTs
		AND			CWT.CHEMO_ID IS NULL 						-- Not already in the CWT table


		-- Insert treatments from tblMAIN_TELETHERAPY that aren't yet reportable as 31 day CWT (not in tblDEFINITIVE_TREATMENT), but have been entered as a treatment
		INSERT into SCR_Warehouse.SCR_CWT_work (
		CARE_ID
		,TELE_ID
		,TeleActionId
		,TxModTreatmentEventCode		
		,TxModTreatmentCode									
		,TxModTreatmentSettingCode		
		,TxModDateDecisionTreat			
		,TxModDateTreatment				
		,TxModOrgCodeDecisionTreat		
		,TxModOrgCodeTreatment			
		,TxModDefinitiveTreatment	
		,TxModChemoRadio	
		,TxModChemoRT					
		,TxModModalitySubCode			
		,TxModRadioSurgery	
		,HasTxMod	
		,ReportDate	
		)
		
		SELECT
		CARE_ID							=	Tx.CARE_ID
		,TELE_ID						=	Tx.TELE_ID
		,TeleActionId					=	Tx.ACTION_ID
		,TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
		,TxModTreatmentCode				=	CASE
												WHEN Tx.BRAIN_RADIOSURGERY_INDICATOR = 'Y'
													THEN '22'
												WHEN Tx.N_CHEMORADIO = '1'
													THEN '04'
												WHEN ISNULL(Tx.N10_16_BEAM_TYPE, '') IN ('z')
													THEN '13'
												ELSE '05'
											END
		,TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
		,TxModDateDecisionTreat			=	Tx.N10_3_DECISION_DATE
		,TxModDateTreatment				=	Tx.N10_8_START_DATE
		,TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
		,TxModOrgCodeTreatment			=	Tx.N10_1_SITE_CODE
		,TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
		,TxModChemoRadio				=	Tx.N_CHEMORADIO
		,TxModChemoRT					=	CASE WHEN Tx.N_CHEMORADIO = 1 THEN 'R' ELSE CAST(NULL AS varchar(2)) END
		,TxModModalitySubCode			=	Tx.N10_16_BEAM_TYPE
		,TxModRadioSurgery				=	Tx.BRAIN_RADIOSURGERY_INDICATOR
		,HasTxMod						=	2
		,ReportDate						=	@ReportDate
			  
		FROM		LocalConfig.tblMAIN_TELETHERAPY Tx 
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	TX.TELE_ID = CWT.TELE_ID 
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			isnull (Tx.DEFINITIVE_TREATMENT,0) <> 99	-- excludes 99 which are adjunctive chemo RTs
		AND			CWT.TELE_ID IS NULL 						-- Not already in the CWT table				

		
		-- Insert treatments from tblMAIN_PALLIATIVE that aren't yet reportable as 31 day CWT (not in tblDEFINITIVE_TREATMENT), but have been entered as a treatment
		INSERT into SCR_Warehouse.SCR_CWT_work (
		CARE_ID
		,PALL_ID
		,PallActionId
		,TxModTreatmentEventCode		
		,TxModTreatmentCode				
		,TxModTreatmentSettingCode		
		,TxModDateDecisionTreat			
		,TxModDateTreatment				
		,TxModOrgCodeDecisionTreat		
		,TxModOrgCodeTreatment			
		,TxModDefinitiveTreatment
		,HasTxMod		
		,ReportDate	
		)
		
		SELECT 
		CARE_ID							=	Tx.CARE_ID
		,PALL_ID						=	Tx.PALL_ID
		,PallActionId					=	Tx.ACTION_ID  
		,TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
		,TxModTreatmentCode				=	Tx.N_SPECIALIST
		,TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
		,TxModDateDecisionTreat			=	Tx.N12_1_DECISION_DATE
		,TxModDateTreatment				=	Tx.N12_2_START_DATE
		,TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
		,TxModOrgCodeTreatment			=	Tx.N1_3_ORG_CODE_TREATMENT
		,TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
		,HasTxMod						=	2
		,ReportDate						=	@ReportDate 				
			  
		FROM		LocalConfig.tblMAIN_PALLIATIVE Tx 
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	TX.PALL_ID = CWT.PALL_ID 
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			CWT.PALL_ID IS NULL 						-- Not already in the CWT table	

	
		-- Insert treatments from tblMAIN_BRACHYTHERAPY that aren't yet reportable as 31 day CWT (not in tblDEFINITIVE_TREATMENT), but have been entered as a treatment
		INSERT into SCR_Warehouse.SCR_CWT_work (
		CARE_ID
		,BRACHY_ID
		,BrachyActionId	
		,TxModTreatmentEventCode		
		,TxModTreatmentCode								
		,TxModTreatmentSettingCode		
		,TxModDateDecisionTreat			
		,TxModDateTreatment				
		,TxModOrgCodeDecisionTreat		
		,TxModOrgCodeTreatment			
		,TxModDefinitiveTreatment		
		,TxModModalitySubCode
		,HasTxMod		
		,ReportDate	
		)
		
		SELECT 
		CARE_ID							=	Tx.CARE_ID
		,BRACHY_ID						=	Tx.BRACHY_ID
		,BrachyActionId					=	Tx.ACTION_ID 
		,TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
		,TxModTreatmentCode				=	CASE
												WHEN Tx.N11_7_TYPE = 'US'
													THEN '19'
												ELSE '06'
											END
		,TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
		,TxModDateDecisionTreat			=	Tx.N11_3_DECISION_DATE
		,TxModDateTreatment				=	Tx.N11_9_START_DATE
		,TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
		,TxModOrgCodeTreatment			=	Tx.N11_1_SITE_CODE
		,TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
		,TxModModalitySubCode			=	Tx.N11_7_TYPE
		,HasTxMod						=	2
		,ReportDate						=	@ReportDate			
			  
		FROM		LocalConfig.tblMAIN_BRACHYTHERAPY Tx 
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	TX.BRACHY_ID = CWT.BRACHY_ID 
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			CWT.BRACHY_ID IS NULL 						-- Not already in the CWT table		
		
		-- Insert treatments from tblOTHER_TREATMENT that aren't yet reportable as 31 day CWT (not in tblDEFINITIVE_TREATMENT), but have been entered as a treatment
		INSERT into SCR_Warehouse.SCR_CWT_work (
		CARE_ID
		,OTHER_ID
		,OtherActionId
		,TxModTreatmentEventCode		
		,TxModTreatmentCode				
		,TxModTreatmentSettingCode		
		,TxModDateDecisionTreat			
		,TxModDateTreatment				
		,TxModOrgCodeDecisionTreat		
		,TxModOrgCodeTreatment			
		,TxModDefinitiveTreatment
		,HasTxMod
		,ReportDate	
		)
		
		SELECT 
		CARE_ID							=	Tx.CARE_ID
		,OTHER_ID						=	Tx.OTHER_ID
		,OtherActionId					=	Tx.ACTION_ID    
		,TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
		,TxModTreatmentCode				=	'97'
		,TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
		,TxModDateDecisionTreat			=	Tx.N16_9_DECISION_ACTIVE
		,TxModDateTreatment				=	Tx.N16_10_START_ACTIVE
		,TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
		,TxModOrgCodeTreatment			=	Tx.N1_3_ORG_CODE_TREATMENT
		,TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
		,HasTxMod						=	2
		,ReportDate						=	@ReportDate			
			  
		FROM		LocalConfig.tblOTHER_TREATMENT Tx 
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	TX.OTHER_ID = CWT.OTHER_ID 
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			CWT.OTHER_ID IS NULL 						-- Not already in the CWT table
				

		-- Insert treatments from tblMAIN_SURGERY that aren't yet reportable as 31 day CWT (not in tblDEFINITIVE_TREATMENT), but have been entered as a treatment
		INSERT into SCR_Warehouse.SCR_CWT_work (
		CARE_ID
		,SURGERY_ID
		,SurgeryActionId
		,TxModTreatmentEventCode		
		,TxModTreatmentCode				
		,TxModTreatmentSettingCode		
		,TxModDateDecisionTreat			
		,TxModDateTreatment				
		,TxModOrgCodeDecisionTreat		
		,TxModOrgCodeTreatment			
		,TxModDefinitiveTreatment	
		,HasTxMod	
		,ReportDate	
		)
		
		SELECT 
		CARE_ID							=	Tx.CARE_ID
		,SURGERY_ID						=	Tx.SURGERY_ID
		,SurgeryActionId				=	Tx.ACTION_ID
		,TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
		,TxModTreatmentCode				=	CWT.DeftTreatmentCode
		,TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
		,TxModDateDecisionTreat			=	Tx.N7_5_DECISION_DATE
		,TxModDateTreatment				=	Tx.N7_8_ADMISSION_DATE
		,TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
		,TxModOrgCodeTreatment			=	Tx.N7_1_SITE_CODE
		,TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
		,HasTxMod						=	2
		,ReportDate						=	@ReportDate			
			  
		FROM		LocalConfig.tblMAIN_SURGERY Tx 
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	TX.SURGERY_ID = CWT.SURGERY_ID 
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			CWT.SURGERY_ID IS NULL 						-- Not already in the CWT table	


		-- Insert treatments from tblMONITORING that aren't yet reportable as 31 day CWT (not in tblDEFINITIVE_TREATMENT), but have been entered as a treatment
		INSERT into SCR_Warehouse.SCR_CWT_work (
		CARE_ID
		,MONITOR_ID
		,MonitorActionId
		,TxModTreatmentEventCode		
		,TxModTreatmentCode				
		,TxModTreatmentSettingCode		
		,TxModDateDecisionTreat			
		,TxModDateTreatment				
		,TxModOrgCodeDecisionTreat		
		,TxModOrgCodeTreatment			
		,TxModDefinitiveTreatment
		,HasTxMod
		,ReportDate	
		)
		
		SELECT 
		CARE_ID							=	Tx.CARE_ID
		,MONITOR_ID						=	Tx.MONITOR_ID
		,MonitorActionId				=	Tx.ACTION_ID  
		,TxModTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
		,TxModTreatmentCode				=	'08'
		,TxModTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
		,TxModDateDecisionTreat			=	Tx.N16_9_DECISION_ACTIVE
		,TxModDateTreatment				=	Tx.N16_10_START_ACTIVE
		,TxModOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
		,TxModOrgCodeTreatment			=	Tx.N1_3_ORG_CODE_TREATMENT
		,TxModDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
		,HasTxMod						=	2
		,ReportDate						=	@ReportDate		
			  
		FROM		LocalConfig.tblMONITORING Tx 	
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	TX.MONITOR_ID = CWT.MONITOR_ID
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			CWT.MONITOR_ID IS NULL 						-- Not already in the CWT table

		-- Keep a record of when the TxMod columns insert finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'TxMod columns insert'
				
/************************************************************************************************************************************************************************************************************
-- Update the linked modality specific treatment columns for every treatment modality record that is an adjunctive component of ChemoRadioTherapy (ChemRTLink columns)
-- NB: this only updates linked treatment modality records if there is a primary adjunctive component of ChemoRadioTherapy to link to
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the ChemRtLink update started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'ChemRtLink update'
				
		-- DROP ChemoAuditTrail_Work table if it exists
		if object_ID('SCR_Warehouse.ChemoAuditTrail_Work') is not null 
		   DROP TABLE SCR_Warehouse.ChemoAuditTrail_Work

		-- Create a table containing the creation date of every record in tblMAIN_CHEMOTHERAPY
		SELECT		Tx.CARE_ID
					,Tx.CHEMO_ID
					,Tx.DEFINITIVE_TREATMENT
					,Tx.N_CHEMORADIO
					,Tx.N9_4_DECISION_DATE AS DecisionDate
					,Tx.N9_10_START_DATE AS StartDate
					,Tx.L_END_DATE AS EndDate
					,Tx.ACTION_ID
					,A.TABLE_NAME
					,A.RECORD_ID
					,A.ACTION_TYPE AS Upd_ACTION_TYPE
					,Ins.ACTION_TYPE AS Ins_ACTION_TYPE
					,A.USER_ID AS LastUpdatedBy
					,A.ACTION_DATE AS LastUpdated
					,Ins.USER_ID AS InsertedBy
					,Ins.ACTION_DATE AS Inserted
					,ROW_NUMBER() OVER (PARTITION BY Tx.CHEMO_ID ORDER BY Ins.ACTION_DATE ASC, Ins.ACTION_ID) AS ChemoInsertIx
					,CASE WHEN CWT.CHEMO_ID IS NOT NULL THEN 1 ELSE 0 END AS InCWT
					,CAST(NULL AS int) AS TELE_ID
		INTO		SCR_Warehouse.ChemoAuditTrail_Work
		FROM		LocalConfig.tblMAIN_CHEMOTHERAPY Tx   
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		LEFT JOIN	LocalConfig.tblAUDIT A
						ON	Tx.ACTION_ID = A.ACTION_ID
		LEFT JOIN	LocalConfig.tblAUDIT Ins
						ON	A.TABLE_NAME = Ins.TABLE_NAME
						AND	A.RECORD_ID = Ins.RECORD_ID
						AND	Ins.ACTION_TYPE = 'Insert'
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	Tx.CHEMO_ID = CWT.CHEMO_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset) 

		-- DROP ChemoAuditTrail table if it exists
		if object_ID('SCR_Warehouse.ChemoAuditTrail') is not null 
		   DROP TABLE SCR_Warehouse.ChemoAuditTrail

		-- Rename the ChemoAuditTrail_Work table as ChemoAuditTrail
		EXEC sp_rename 'SCR_Warehouse.ChemoAuditTrail_Work', 'ChemoAuditTrail'

		-- DROP RadioAuditTrail_Work table if it exists
		if object_ID('SCR_Warehouse.RadioAuditTrail_Work') is not null 
		   DROP TABLE SCR_Warehouse.RadioAuditTrail_Work

		-- Create a table containing the creation date of every record in tblMAIN_TELETHERAPY
		SELECT		Tx.CARE_ID
					,Tx.TELE_ID
					,Tx.DEFINITIVE_TREATMENT
					,Tx.N_CHEMORADIO
					,Tx.N10_3_DECISION_DATE AS DecisionDate
					,Tx.N10_8_START_DATE AS StartDate
					,Tx.N10_9_END_DATE AS EndDate
					,Tx.ACTION_ID
					,A.TABLE_NAME
					,A.RECORD_ID
					,A.ACTION_TYPE AS Upd_ACTION_TYPE
					,Ins.ACTION_TYPE AS Ins_ACTION_TYPE
					,A.USER_ID AS LastUpdatedBy
					,A.ACTION_DATE AS LastUpdated
					,Ins.USER_ID AS InsertedBy
					,Ins.ACTION_DATE AS Inserted
					,ROW_NUMBER() OVER (PARTITION BY Tx.TELE_ID ORDER BY Ins.ACTION_DATE ASC, Ins.ACTION_ID) AS RadioInsertIx
					,CASE WHEN CWT.TELE_ID IS NOT NULL THEN 1 ELSE 0 END AS InCWT
					,CAST(NULL AS int) AS CHEMO_ID
		INTO		SCR_Warehouse.RadioAuditTrail_Work
		FROM		LocalConfig.tblMAIN_TELETHERAPY Tx   
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		LEFT JOIN	LocalConfig.tblAUDIT A
						ON	Tx.ACTION_ID = A.ACTION_ID
		LEFT JOIN	LocalConfig.tblAUDIT Ins
						ON	A.TABLE_NAME = Ins.TABLE_NAME
						AND	A.RECORD_ID = Ins.RECORD_ID
						AND	Ins.ACTION_TYPE = 'Insert'
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	Tx.TELE_ID = CWT.TELE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset) 

		-- DROP RadioAuditTrail table if it exists
		if object_ID('SCR_Warehouse.RadioAuditTrail') is not null 
		   DROP TABLE SCR_Warehouse.RadioAuditTrail

		-- Rename the RadioAuditTrail_Work table as RadioAuditTrail
		EXEC sp_rename 'SCR_Warehouse.RadioAuditTrail_Work', 'RadioAuditTrail'

		-- DROP #RadioLinkOrder table if it exists
		if object_ID('tempdb..#RadioLinkOrder') is not null 
		   DROP TABLE #RadioLinkOrder

		-- Create a table of the remaining RadioTherapy records that aren't already in the CWT table, but have a potential corresponding 
		-- Chemo record, ordered by the likelihood they are the secondary / adjunctive component of Chemo treatment,  no. 1 is highest priority
		SELECT		ROW_NUMBER() OVER (	PARTITION BY	rat.TELE_ID 
										ORDER BY		CASE WHEN DATEDIFF(MINUTE, cat.Inserted, rat.Inserted) BETWEEN 0 AND 10 THEN 1 ELSE 0 END DESC,			-- Whether the radio record we are looking to link as an adjunctive treatment was created between 0 and 10 minutes after the chemo record we are linking to
														ABS(DATEDIFF(MINUTE, cat.Inserted, rat.Inserted)) ASC,													-- How many minutes between the creation of the radio record we are looking to link as an adjunctive treatment and the chemo record we are linking to
														ISNULL(rat.N_CHEMORADIO,0) DESC,																		-- Prioritise where the radio record is marked as ChemoRT
														ABS(DATEDIFF(MINUTE, cat.StartDate, rat.StartDate)) ASC,												-- How many minutes between the StartDate of the radio record we are looking to link as an adjunctive treatment and the chemo record we are linking to
														ABS(DATEDIFF(MINUTE, cat.EndDate, rat.EndDate)) ASC														-- How many minutes between the EndDate of the radio record we are looking to link as an adjunctive treatment and the chemo record we are linking to
										) AS RadioLinkOrder
					,rat.TELE_ID
					,cat.CHEMO_ID
		INTO		#RadioLinkOrder
		FROM		SCR_Warehouse.RadioAuditTrail rat
		INNER JOIN	SCR_Warehouse.ChemoAuditTrail cat
						ON	rat.CARE_ID = cat.CARE_ID
						AND	rat.DecisionDate = cat.DecisionDate						-- The radio record we are looking to link as an adjunctive treatment and the chemo record we are linking to have the same DecisionToTreat date
						AND	rat.InsertedBy = cat.InsertedBy							-- The workflow on the front screens that allows a Chemo & Radio record to be "linked" can only be done by the same user
						AND	cat.InCWT = 1											-- The chemo records we are looking to link to are already in the CWT table as the primary treatment
						AND	cat.N_CHEMORADIO = 1									-- The chemo records we are looking to link to are marked as ChemoRadio
		WHERE		rat.InCWT = 0													-- The radio record we are looking to link as an adjunctive treatment is not already in the CWT table
		

		-- Update the TELE_ID column and ChemRtLink columns where there is a corresponding adjunctive treatment record in tblMAIN_TELETHERAPY
		-- that appears to correspond to a Chemo record already in the CWT table
		UPDATE		CWT
		SET			CWT.TELE_ID = Tx.TELE_ID
					,CWT.ChemRtLinkTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
					,CWT.ChemRtLinkTreatmentCode				=	CASE
																		WHEN Tx.BRAIN_RADIOSURGERY_INDICATOR = 'Y'
																			THEN '22'
																		WHEN Tx.N_CHEMORADIO = '1'
																			THEN '04'
																		WHEN ISNULL(Tx.N10_16_BEAM_TYPE, '') IN ('z')
																			THEN '13'
																		ELSE '05'
																	END
					,CWT.ChemRtLinkTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
					,CWT.ChemRtLinkDateDecisionTreat			=	Tx.N10_3_DECISION_DATE
					,CWT.ChemRtLinkDateTreatment				=	Tx.N10_8_START_DATE
					,CWT.ChemRtLinkOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
					,CWT.ChemRtLinkOrgCodeTreatment			=	Tx.N10_1_SITE_CODE
					,CWT.ChemRtLinkDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
					,CWT.ChemRtLinkChemoRadio				=	Tx.N_CHEMORADIO
					,CWT.ChemRtLinkModalitySubCode			=	Tx.N10_16_BEAM_TYPE
					,CWT.ChemRtLinkRadioSurgery				=	Tx.BRAIN_RADIOSURGERY_INDICATOR
					,CWT.HasChemRtLink						=	1
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	#RadioLinkOrder rlo
						ON	CWT.CHEMO_ID = rlo.CHEMO_ID
						AND	rlo.RadioLinkOrder = 1								--most eligible RT to link to chemotherapy
		INNER JOIN	LocalConfig.tblMAIN_TELETHERAPY Tx
						ON	rlo.TELE_ID = Tx.TELE_ID

		-- DROP #ChemoLinkOrder table if it exists
		if object_ID('tempdb..#ChemoLinkOrder') is not null 
		   DROP TABLE #ChemoLinkOrder

		-- Create a table of the remaining Chemo records that aren't already in the CWT table, but have a potential corresponding 
		-- RadioTherapy record, ordered by the likelihood they are the secondary / adjunctive component of RadioTherapy treatment, no. 1 is highest priority
		SELECT		ROW_NUMBER() OVER (	PARTITION BY	cat.CHEMO_ID 
										ORDER BY		CASE WHEN DATEDIFF(MINUTE, rat.Inserted, cat.Inserted) BETWEEN 0 AND 10 THEN 1 ELSE 0 END DESC,			-- Whether the chemo record we are looking to link as an adjunctive treatment was created between 0 and 10 minutes after the radio record we are linking to
														ABS(DATEDIFF(MINUTE, rat.Inserted, cat.Inserted)) ASC,													-- How many minutes between the creation of the chemo record we are looking to link as an adjunctive treatment and the radio record we are linking to
														ISNULL(cat.N_CHEMORADIO,0) DESC,																		-- Prioritise where the chemo record is marked as ChemoRT
														ABS(DATEDIFF(MINUTE, rat.StartDate, cat.StartDate)) ASC,												-- How many minutes between the StartDate of the chemo record we are looking to link as an adjunctive treatment and the radio record we are linking to
														ABS(DATEDIFF(MINUTE, rat.EndDate, cat.EndDate)) ASC														-- How many minutes between the EndDate of the chemo record we are looking to link as an adjunctive treatment and the radio record we are linking to
										) AS ChemoLinkOrder
					,cat.CHEMO_ID
					,rat.TELE_ID
		INTO		#ChemoLinkOrder
		FROM		SCR_Warehouse.ChemoAuditTrail cat
		INNER JOIN	SCR_Warehouse.RadioAuditTrail rat
						ON	cat.CARE_ID = rat.CARE_ID
						AND	cat.DecisionDate = rat.DecisionDate						-- The chemo record we are looking to link as an adjunctive treatment and the radio record we are linking to have the same DecisionToTreat date
						AND	cat.InsertedBy = rat.InsertedBy							-- The workflow on the front screens that allows a Chemo & Radio record to be "linked" can only be done by the same user
						AND	rat.InCWT = 1											-- The radio records we are looking to link to are already in the CWT table as the primary treatment
						AND	rat.N_CHEMORADIO = 1									-- The radio records we are looking to link to are marked as ChemoRadio
		WHERE		cat.InCWT = 0													-- The chemo record we are looking to link as an adjunctive treatment is not already in the CWT table
		
		-- Update the CHEMO_ID column and ChemRtLink columns where there is a corresponding adjunctive treatment record in tblMAIN_CHEMOTHERAPY
		-- that appears to correspond to a RadioTherapy record already in the CWT table
		UPDATE		CWT
		SET			CWT.CHEMO_ID = Tx.CHEMO_ID
					,CWT.ChemRtLinkTreatmentEventCode		=	Tx.N_TREATMENT_EVENT
					,CWT.ChemRtLinkTreatmentCode				=	CASE
																		WHEN Tx.N_CHEMORADIO = '1'
																			THEN '04'
																		WHEN ISNULL(Tx.N9_7_THERAPY_TYPE, '') IN ('C', 'W', 'Y')
																			THEN '02'
																		WHEN ISNULL(Tx.N9_7_THERAPY_TYPE, '') IN ('I', 'X', 'Z')
																			THEN '15'
																		WHEN Tx.N9_7_THERAPY_TYPE = 'H'
																			THEN '03'
																		WHEN Tx.N9_7_THERAPY_TYPE = 'V'
																			THEN '21'
																		ELSE '14'
																	END
					,CWT.ChemRtLinkTreatmentSettingCode		=	Tx.N_TREATMENT_SETTING
					,CWT.ChemRtLinkDateDecisionTreat			=	Tx.N9_4_DECISION_DATE
					,CWT.ChemRtLinkDateTreatment				=	Tx.N9_10_START_DATE
					,CWT.ChemRtLinkOrgCodeDecisionTreat		=	Tx.N_SITE_CODE_DTT
					,CWT.ChemRtLinkOrgCodeTreatment			=	Tx.N9_1_SITE_CODE
					,CWT.ChemRtLinkDefinitiveTreatment		=	Tx.DEFINITIVE_TREATMENT
					,CWT.ChemRtLinkChemoRadio				=	Tx.N_CHEMORADIO
					,CWT.ChemRtLinkModalitySubCode			=	Tx.N9_7_THERAPY_TYPE
					,CWT.HasChemRtLink						=	1
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	#ChemoLinkOrder clo
						ON	CWT.TELE_ID = clo.TELE_ID
						AND	clo.ChemoLinkOrder = 1
		INNER JOIN	LocalConfig.tblMAIN_CHEMOTHERAPY Tx
						ON	clo.CHEMO_ID = Tx.CHEMO_ID

		-- Keep a record of when the ChemRtLink update finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'ChemRtLink update'
				

/************************************************************************************************************************************************************************************************************
-- Insert the remaining linked modality specific treatment columns for treatment modality records that are an adjunctive component of ChemoRadioTherapy (ChemRTLink columns), but have
-- no primary adjunctive component of ChemoRadioTherapy to link to
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the orphaned ChemRtLink update started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'orphaned ChemRtLink update'
				
		-- Insert treatments from tblMAIN_CHEMOTHERAPY that aren't yet reportable as 31 day CWT (not in tblDEFINITIVE_TREATMENT), but have been entered as a treatment
		INSERT into SCR_Warehouse.SCR_CWT_work (
		CARE_ID
		,CHEMO_ID
		,ChemoActionId
		,ChemRtLinkTreatmentEventCode
		,ChemRtLinkTreatmentCode
		,ChemRtLinkTreatmentSettingCode
		,ChemRtLinkDateDecisionTreat
		,ChemRtLinkDateTreatment
		,ChemRtLinkOrgCodeDecisionTreat
		,ChemRtLinkOrgCodeTreatment
		,ChemRtLinkDefinitiveTreatment
		,ChemRtLinkChemoRadio				
		,ChemRtLinkModalitySubCode		
		,HasChemRtLink	
		,ReportDate	
		)
		
		SELECT
		CARE_ID									=	Tx.CARE_ID
		,CHEMO_ID								=	Tx.CHEMO_ID
		,ChemoActionId							=	Tx.ACTION_ID
		,ChemRtLinkTreatmentEventCode			=	Tx.N_TREATMENT_EVENT
		,ChemRtLinkTreatmentCode				=	CASE
														WHEN N_CHEMORADIO = '1'
															THEN '04'
														WHEN ISNULL(N9_7_THERAPY_TYPE, '') IN ('C', 'W', 'Y')
															THEN '02'
														WHEN ISNULL(N9_7_THERAPY_TYPE, '') IN ('I', 'X', 'Z')
															THEN '15'
														WHEN N9_7_THERAPY_TYPE = 'H'
															THEN '03'
														WHEN N9_7_THERAPY_TYPE = 'V'
															THEN '21'
														ELSE '14'
													END
		,ChemRtLinkTreatmentSettingCode			=	Tx.N_TREATMENT_SETTING
		,ChemRtLinkDateDecisionTreat			=	Tx.N9_4_DECISION_DATE
		,ChemRtLinkDateTreatment				=	Tx.N9_10_START_DATE
		,ChemRtLinkOrgCodeDecisionTreat			=	Tx.N_SITE_CODE_DTT
		,ChemRtLinkOrgCodeTreatment				=	Tx.N9_1_SITE_CODE
		,ChemRtLinkDefinitiveTreatment			=	Tx.DEFINITIVE_TREATMENT
		,ChemRtLinkChemoRadio					=	Tx.N_CHEMORADIO
		,ChemRtLinkModalitySubCode				=	Tx.N9_7_THERAPY_TYPE
		,HasChemRtLink							=	2
		,ReportDate								=	@ReportDate
			  
		FROM		LocalConfig.tblMAIN_CHEMOTHERAPY Tx 
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	TX.CHEMO_ID = CWT.CHEMO_ID 
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			CWT.CHEMO_ID IS NULL 						-- Not already in the CWT table				


		-- Insert treatments from tblMAIN_TELETHERAPY that aren't yet reportable as 31 day CWT (not in tblDEFINITIVE_TREATMENT), but have been entered as a treatment
		INSERT into SCR_Warehouse.SCR_CWT_work (
		CARE_ID
		,TELE_ID
		,TeleActionId
		,ChemRtLinkTreatmentEventCode		
		,ChemRtLinkTreatmentCode									
		,ChemRtLinkTreatmentSettingCode		
		,ChemRtLinkDateDecisionTreat			
		,ChemRtLinkDateTreatment				
		,ChemRtLinkOrgCodeDecisionTreat		
		,ChemRtLinkOrgCodeTreatment			
		,ChemRtLinkDefinitiveTreatment	
		,ChemRtLinkChemoRadio				
		,ChemRtLinkModalitySubCode			
		,ChemRtLinkRadioSurgery	
		,HasChemRtLink	
		,ReportDate	
		)
		
		SELECT
		CARE_ID									=	Tx.CARE_ID
		,TELE_ID								=	Tx.TELE_ID
		,TeleActionId							=	Tx.ACTION_ID
		,ChemRtLinkTreatmentEventCode			=	Tx.N_TREATMENT_EVENT
		,ChemRtLinkTreatmentCode				=	CASE
														WHEN Tx.BRAIN_RADIOSURGERY_INDICATOR = 'Y'
															THEN '22'
														WHEN Tx.N_CHEMORADIO = '1'
															THEN '04'
														WHEN ISNULL(Tx.N10_16_BEAM_TYPE, '') IN ('z')
															THEN '13'
														ELSE '05'
													END
		,ChemRtLinkTreatmentSettingCode			=	Tx.N_TREATMENT_SETTING
		,ChemRtLinkDateDecisionTreat			=	Tx.N10_3_DECISION_DATE
		,ChemRtLinkDateTreatment				=	Tx.N10_8_START_DATE
		,ChemRtLinkOrgCodeDecisionTreat			=	Tx.N_SITE_CODE_DTT
		,ChemRtLinkOrgCodeTreatment				=	Tx.N10_1_SITE_CODE
		,ChemRtLinkDefinitiveTreatment			=	Tx.DEFINITIVE_TREATMENT
		,ChemRtLinkChemoRadio					=	Tx.N_CHEMORADIO
		,ChemRtLinkModalitySubCode				=	Tx.N10_16_BEAM_TYPE
		,ChemRtLinkRadioSurgery					=	Tx.BRAIN_RADIOSURGERY_INDICATOR
		,HasChemRtLink							=	2
		,ReportDate								=	@ReportDate 				
			  
		FROM		LocalConfig.tblMAIN_TELETHERAPY Tx 
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	TX.TELE_ID = CWT.TELE_ID 
		LEFT JOIN	#Incremental Inc
						ON	Tx.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Tx.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			CWT.TELE_ID IS NULL 						-- Not already in the CWT table				

		-- Keep a record of when the orphaned ChemRtLink update finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'orphaned ChemRtLink update'
				
		
/************************************************************************************************************************************************************************************************************
-- Insert a CWT record for referrals without a corresponding CWT record
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the referrals without a corresponding CWT record started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'referrals without a corresponding CWT record'
				
		-- Insert a CWT record for referrals without a corresponding CWT record (to allow cwt flags to be calculated for 2WW)
		INSERT into SCR_Warehouse.SCR_CWT_work (
		CARE_ID
		)
		SELECT		Referrals.CARE_ID
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	Referrals.CARE_ID = CWT.CARE_ID 
		LEFT JOIN	#Incremental Inc
						ON	Referrals.CARE_ID = Inc.CARE_ID
		WHERE		(Inc.CARE_ID IS NOT NULL					-- The record is in the incremental dataset
		OR			Referrals.CARE_ID IS NULL							-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0)						-- We are doing a bulk load (in which case we should ignore the incremental dataset)
		AND			CWT.CARE_ID IS NULL 						-- Not already in the CWT table		

		-- Keep a record of when the referrals without a corresponding CWT record finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'referrals without a corresponding CWT record'
				

/************************************************************************************************************************************************************************************************************
-- (Re)Create Primary and Unique keys for the SCR CWT Work table
************************************************************************************************************************************************************************************************************/
		
		-- Keep a record of when the CWT_ID update started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'CWT_ID update'
				
		-- Populate the CWT_ID
		UPDATE		SCR_Warehouse.SCR_CWT_work
		SET			CWT_ID	=	CAST(CARE_ID AS varchar(255)) + '|' +
								ISNULL(CAST(TREATMENT_ID AS varchar(255)),'') + '|' +
								ISNULL(CAST(CHEMO_ID AS varchar(255)),'0') + '|' +
								ISNULL(CAST(TELE_ID AS varchar(255)),'0') + '|' +
								ISNULL(CAST(PALL_ID AS varchar(255)),'0') + '|' +
								ISNULL(CAST(BRACHY_ID AS varchar(255)),'0') + '|' +
								ISNULL(CAST(OTHER_ID AS varchar(255)),'0') + '|' +
								ISNULL(CAST(SURGERY_ID AS varchar(255)),'0') + '|' +
								ISNULL(CAST(MONITOR_ID AS varchar(255)),'0')

		-- Drop the existing CWT primary key (in favour of CWT_ID)
		ALTER TABLE SCR_Warehouse.SCR_CWT_work DROP CONSTRAINT PK_SCR_CWT_work
		
		-- Create the new Primary Key for the CWT table using CWT_ID
		ALTER TABLE SCR_Warehouse.SCR_CWT_work 
		ADD CONSTRAINT PK_SCR_CWT_work PRIMARY KEY (
				CWT_ID ASC
				)
		
		-- Populate the Tx_ID 
		UPDATE		SCR_Warehouse.SCR_CWT_work
		SET			Tx_ID	=	CAST(CARE_ID AS varchar(255)) + '|' +
								ISNULL(CAST(CHEMO_ID AS varchar(255)),'0') + '|' +
								ISNULL(CAST(TELE_ID AS varchar(255)),'0') + '|' +
								ISNULL(CAST(PALL_ID AS varchar(255)),'0') + '|' +
								ISNULL(CAST(BRACHY_ID AS varchar(255)),'0') + '|' +
								ISNULL(CAST(OTHER_ID AS varchar(255)),'0') + '|' +
								ISNULL(CAST(SURGERY_ID AS varchar(255)),'0') + '|' +
								ISNULL(CAST(MONITOR_ID AS varchar(255)),'0')

		-- Keep a record of when the CWT_ID update finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'CWT_ID update'
				
			
/************************************************************************************************************************************************************************************************************
-- Update metadata-lookups for SCR Referrals Work table
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the metadata-lookups for SCR Referrals update started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'metadata-lookups for SCR Referrals update'
				
		-- Update SCR Referrals Work with Pathway ID
		UPDATE		Referrals 
		SET			PatientPathwayID = dt.PATHWAY_ID
        FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		LEFT JOIN	LocalConfig.tblDEFINITIVE_TREATMENT dt 
						ON	Referrals.CARE_ID = dt.CARE_ID							--links to treatment table for PathwayID
						AND	dt.PATHWAY_ID is not null 
						AND	dt.PATHWAY_ID != ''
						AND	dt.TREAT_NO = 1
  
  
		-- Update SCR Referrals Work with demographics data
		UPDATE		Referrals
		 SET		Forename				=	dem.N1_6_FORENAME
					,Surname					=	dem.N1_5_SURNAME 
					,DateBirth				=	dem.N1_10_DATE_BIRTH 
					,AgeAtReferral			=	DATEDIFF(YY, dem.N1_10_DATE_BIRTH, Referrals.DateReceipt) - 
												CASE	WHEN MONTH(dem.N1_10_DATE_BIRTH) > MONTH(Referrals.DateReceipt) OR (MONTH(dem.N1_10_DATE_BIRTH) = MONTH(Referrals.DateReceipt) AND DAY(dem.N1_10_DATE_BIRTH) > DAY(Referrals.DateReceipt)) 
														THEN 1 
														ELSE 0 END
					,AgeAtDiagnosis			=	DATEDIFF(YY, dem.N1_10_DATE_BIRTH, ISNULL(Referrals.DateDiagnosis, Referrals.DateFirstSeen)) - 
												CASE	WHEN MONTH(dem.N1_10_DATE_BIRTH) > MONTH(ISNULL(Referrals.DateDiagnosis, Referrals.DateFirstSeen)) OR (MONTH(dem.N1_10_DATE_BIRTH) = MONTH(ISNULL(Referrals.DateDiagnosis, Referrals.DateFirstSeen)) AND DAY(dem.N1_10_DATE_BIRTH) > DAY(ISNULL(Referrals.DateDiagnosis, Referrals.DateFirstSeen))) 
														THEN 1 
														ELSE 0 END
					,HospitalNumber			=	dem.N1_2_HOSPITAL_NUMBER   
					,NHSNumber				=	dem.N1_1_NHS_NUMBER
					,NHSNumberStatusCode	=	dem.NHS_NUMBER_STATUS
					,NstsStatus				=	dem.L_NSTS_STATUS
					,IsTemporaryNhsNumber	=	CASE	WHEN	dem.L_NSTS_STATUS IN (0,9) 
														THEN	1
														ELSE	0
														END
					,DeathStatus			=	dem.L_DEATH_STATUS 
					,DateDeath				=	dem.N15_1_DATE_DEATH
					,PctCode				=	dem.N1_13_PCT
					,DemographicsActionId	=	dem.ACTION_ID
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		LEFT JOIN	LocalConfig.tblDEMOGRAPHICS dem 
						ON	Referrals.[Patient_ID] = dem.Patient_ID                 --links to  refs pt demographics table
		

		-- Update SCR Referrals Work with PCT data
		UPDATE		Referrals
		SET			PctDesc = PCT.PCT_DESC
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblNATIONAL_PCT PCT 
						ON	Referrals.PctCode = PCT.PCT_CODE
		

		-- Update SCR Referrals Work with Cancer SubSite data
		UPDATE		Referrals
		SET			CancerSubSiteDesc = crs.Description
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.CancerReferralSubsites crs
						ON	Referrals.CancerSubSiteCode = crs.ID
  

  		--Update SCR Referrals Work with Cancer Type Lookup
		UPDATE		Referrals
		SET			ReferralCancerSiteCode		=	CSite.CA_ID	
					,ReferralCancerSiteDesc		=	CSite.CA_SITE
					,ReferralCancerSiteBS		=	Case	when	Referrals.CancerTypeCode  = 16 then 'Breast Symptomatic'    
															else	CSite.CA_SITE
															end
					,CancerTypeDesc				=	CType.CANCER_TYPE_DESC
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		LEFT JOIN	LocalConfig.ltblCANCER_TYPE CType 
						ON	Referrals.CancerTypeCode = CType.CANCER_TYPE_CODE		--links to treatment table for PathwayID
		LEFT JOIN	LocalConfig.ltblCANCER_SITES CSite
						ON	CType.CANCER_SITE = CSite.CA_ID
	
  
		--Update SCR Referrals Work with Priority Type Lookup
		UPDATE		Referrals
		SET			PriorityTypeDesc = PType.PRIORITY_DESC
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		LEFT JOIN	LocalConfig.ltblPRIORITY_TYPE PType 
						ON	Referrals.PriorityTypeCode = PType.PRIORITY_CODE		--links to Priority Type Code lookup		
    
  
		--Update SCR Referrals Work with Source Referral Lookup
		UPDATE		Referrals
		SET			SourceReferralDesc = Ref.REF_DESC
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		LEFT JOIN	LocalConfig.ltblOUT_PATIENT_REFERRAL Ref
						ON	Referrals.SourceReferralCode = Ref.REF_CODE				--links to Referral Source Code lookup	
    	    
     
		--UPDATE SCR Referrals Work with Tumour Status Lookup
		UPDATE		Referrals
		SET			TumourStatusDesc = TStat.STATUS_DESC 
 		FROM		SCR_Warehouse.SCR_Referrals_work Referrals       		
		LEFT JOIN	LocalConfig.ltblCA_STATUS TStat 
						ON	Referrals.TumourStatusCode = TStat.STATUS_CODE			--links to Tumour Status description lookup - Unknown or Primary for 2ww
  
  
		--UPDATE SCR Referrals Work with Patient Status Lookup
		UPDATE		Referrals
		SET			PatientStatusDesc = PStat.STATUS_DESC
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		LEFT JOIN	LocalConfig.ltblSTATUS PStat 
						ON	Referrals.PatientStatusCode = PStat.STATUS_CODE			--links to PatientStatus description lookup
  
  
		--UPDATE SCR Referrals Work with Patient Status CWT Lookup
		UPDATE		Referrals
		SET			PatientStatusDescCwt = PStat.STATUS_DESC
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		LEFT JOIN	LocalConfig.ltblSTATUS PStat 
						ON	Referrals.PatientStatusCodeCwt = PStat.STATUS_CODE			--links to PatientStatus description lookup
  
  
		--Update SCR Referrals Work with Consultant Name
		UPDATE		Referrals
		SET			ConsultantName = RTRIM(con.CON_DESC) + ' - ' + con.CON_CODE
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	(SELECT *, ROW_NUMBER() OVER (PARTITION BY NATIONAL_CODE ORDER BY IS_DELETED ASC) AS Ix FROM LocalConfig.ltblCONSULTANTS) con
						ON	Referrals.ConsultantCode = con.NATIONAL_CODE
						AND	con.Ix = 1


		--Update SCR Referrals Work with Transfer Tumour Site
		UPDATE		Referrals
		SET			TransferTumourSiteDesc	=	CSite.CA_SITE
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblCANCER_SITES CSite
						ON	Referrals.TransferTumourSiteCode = CSite.CA_ID


		--UPDATE SCR Referrals Work with Diagnosis Lookup and Faster Diagnosis Cancer Site ID (from DiagnosisCode)
		UPDATE		Referrals
		SET			DiagnosisDesc = Diag.DIAG_DESC
					,FastDiagCancerSiteID = Diag.FasterDiagnosisCancerSiteID
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblDIAGNOSIS Diag 
						ON	Referrals.DiagnosisCode = Diag.DIAG_CODE				--links to diagnostic description lookup


		--UPDATE SCR Referrals Work with SubDiagnosis Lookup (from DiagnosisSubCode)
		UPDATE		Referrals
		SET			DiagnosisSubDesc = Diag.DIAG_DESC
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblDIAGNOSIS Diag 
						ON	Referrals.DiagnosisSubCode = Diag.DIAG_CODE				--links to diagnostic description lookup


		-- UPDATE SCR Referrals Work with Snomed
		UPDATE		Referrals
		SET			SnomedCT_MCode = smct.Code
					,SnomedCT_ConceptID = smct.CT_Concept_ID
					,SnomedCT_Desc = smct.CT_Description
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		LEFT JOIN	LocalConfig.ltblSNOMedCT smct
						ON	Referrals.SnomedCT_ID = smct.CT_Snomed_ID


		-- Referral / Diagnosis Basal Cell Carcinoma flag
		UPDATE		Referrals
		SET			IsBCC =	CASE	WHEN	Referrals.SnomedCT_ID IN (641, 642, 643, 644, 645, 646, 652)
										OR		Referrals.Histology IN ('M80903','M80913','M80923','M80933','M80943','M80953','M81103')
										OR		Referrals.SnomedCT_MCode IN ('M80903','M80913','M80923','M80933','M80943','M80953','M81103')
										OR		Referrals.SnomedCT_ConceptID IN (1338007,61098004,134152008,43369006,37304002,6641007,24762001)
										THEN	1 
										ELSE	0 
								END
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		LEFT JOIN	LocalConfig.ltblSNOMedCT smct
						ON	Referrals.SnomedCT_ID = smct.CT_Snomed_ID


		-- Referral / Diagnosis CWT Cancer Diagnosis flag
		UPDATE		Referrals
		SET			IsCwtCancerDiagnosis =	CASE	WHEN	(		LEFT(Referrals.DiagnosisCode, 3) >= 'C00'		-- Diagnosis ICD Code C00 - C97
															AND		LEFT(Referrals.DiagnosisCode, 3) < 'C98'		-- Diagnosis ICD Code C00 - C97
															AND NOT	(	LEFT(Referrals.DiagnosisCode, 3) = 'C44'	-- Excluding Basal Cell Carcinoma
																	AND	Referrals.IsBCC = 1							-- Excluding Basal Cell Carcinoma
																	)
															)	 
													OR		LEFT(Referrals.DiagnosisCode, 3) = 'D05'				-- Diagnosis ICD Code D05
													THEN	1
													WHEN	Referrals.DiagnosisCode IS NULL
													THEN	-1
													ELSE	0
											END
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		

		--Update SCR Referrals Work with Faster Diagnosis Cancer Site ID (from DiagnosisSubCode if there isn't one from the DiagnosisCode)
		UPDATE		Referrals
		SET			FastDiagCancerSiteID = Diag.FasterDiagnosisCancerSiteID
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblDIAGNOSIS Diag 
						ON	Referrals.DiagnosisSubCode = Diag.DIAG_CODE				--links to diagnostic description lookup
		WHERE		Referrals.FastDiagCancerSiteID IS NULL


		--Update SCR Referrals Work with Faster Diagnosis Cancer Site
		UPDATE		Referrals
		SET			FastDiagCancerSiteCode = fdcs.CWTCode
					,FastDiagCancerSiteDesc = fdcs.Description
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblFasterDiagnosisCancerSite fdcs
						ON	Referrals.FastDiagCancerSiteID = fdcs.ID


		--Update SCR Referrals Work with Faster Diagnosis End Reason ID
		UPDATE		Referrals
		SET			FastDiagEndReasonID = -- logic taken from SVVSCR01.CancerRegister.dbo.FasterDiagnosis view
					CASE	WHEN FastDiagExclDate IS NOT NULL AND FastDiagInformedDate IS NULL 
							THEN 3 -- Excluded
							WHEN IsCwtCancerDiagnosis = 0 AND FastDiagInformedDate IS NOT NULL 
							THEN 2 -- Ruled out
							WHEN Referrals.PatientStatusCode = '03' AND FastDiagInformedDate IS NOT NULL	-- No new cancer diagnosis identified
							THEN 2 -- Ruled out
							WHEN Referrals.TumourStatusCode = 3 AND FastDiagInformedDate IS NOT NULL		-- Non-cancer tumour status
							THEN 2 -- Ruled out
							WHEN FastDiagCancerSiteID IS NOT NULL -- Cancer with site
							THEN 1 -- Diagnosis of Cancer
							WHEN SnomedCT_ID IN (597, 725) -- Neuroendocrine
							THEN 1 -- Diagnosis of Cancer
							WHEN LEFT(Referrals.DiagnosisSubCode, 3) = 'C17' --Can't tell if this is colo or UGI, but it is a cancer
							THEN 1 -- Diagnosis of Cancer
							ELSE CAST(NULL AS int)
					END
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals


		--Update SCR Referrals Work with Faster Diagnosis End Reason
		UPDATE		Referrals
		SET			FastDiagEndReasonCode = fdper.CWTCode
					,FastDiagEndReasonDesc = fdper.Description
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblFasterDiagnosisPathwayEndReason fdper
						ON	Referrals.FastDiagEndReasonID = fdper.ID


		--Update SCR Referrals Work with Faster Diagnosis Delay Reason
		UPDATE		Referrals
		SET			FastDiagDelayReasonCode = fddr.CWTCode
					,FastDiagDelayReasonDesc = fddr.Description
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblFasterDiagnosisDelayReason fddr
						ON	Referrals.FastDiagDelayReasonID = fddr.ID


		--Update SCR Referrals Work with Faster Diagnosis Exclusion Delay Reason
		UPDATE		Referrals
		SET			FastDiagExclReasonCode = fder.CWTCode
					,FastDiagExclReasonDesc = fder.Description
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblFasterDiagnosisExclusionReason fder
						ON	Referrals.FastDiagExclReasonID = fder.ID


		--Update SCR Referrals Work with Faster Diagnosis Organisation
		UPDATE		Referrals
		SET			FastDiagOrgCode = Sites.Code
					,FastDiagOrgDesc = Sites.Description
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.OrganisationSites Sites
						ON	Referrals.FastDiagOrgID = Sites.ID


		--Update SCR Referrals Work with Faster Diagnosis Communication Method
		UPDATE		Referrals
		SET			FastDiagCommMethodCode = fdcm.CWTCode
					,FastDiagCommMethodDesc = fdcm.Description
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblFasterDiagnosisCommunicationMethod fdcm
						ON	Referrals.FastDiagCommMethodID = fdcm.ID


		--Update SCR Referrals Work with Faster Diagnosis Informing Care Professional
		UPDATE		Referrals
		SET			FastDiagInformingCareProfCode = cp.DataDictionaryCode
					,FastDiagInformingCareProfDesc = cp.Description
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblCareProfessional cp
						ON	Referrals.FastDiagInformingCareProfID = cp.ID
  
  
		--Update SCR Referrals Work with Diagnosis Organisation
		UPDATE		Referrals
		SET			OrgIdDiagnosis = Sites.ID
					,OrgDescDiagnosis = Sites.Description
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	(SELECT		*
								,ROW_NUMBER() OVER (PARTITION BY Code ORDER BY IsDeleted ASC, ID ASC) AS Ix 
					FROM		LocalConfig.OrganisationSites
					) Sites
						ON	Referrals.OrgCodeDiagnosis = Sites.Code
						AND	Sites.Ix = 1
  
  
		--Update SCR Referrals Work with Upgrade Organisation
		UPDATE		Referrals
		SET			OrgIdUpgrade = Sites.ID
					,OrgDescUpgrade = Sites.Description
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	(SELECT		*
								,ROW_NUMBER() OVER (PARTITION BY Code ORDER BY IsDeleted ASC, ID ASC) AS Ix 
					FROM		LocalConfig.OrganisationSites
					) Sites
						ON	Referrals.OrgCodeUpgrade = Sites.Code
						AND	Sites.Ix = 1
  
  
		--Update SCR Referrals Work with Organisation First Seen
		UPDATE		Referrals
		SET			OrgIdFirstSeen = Sites.ID
					,OrgDescFirstSeen = Sites.Description
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	(SELECT		*
								,ROW_NUMBER() OVER (PARTITION BY Code ORDER BY IsDeleted ASC, ID ASC) AS Ix 
					FROM		LocalConfig.OrganisationSites
					) Sites
						ON	Referrals.OrgCodeFirstSeen = Sites.Code
						AND	Sites.Ix = 1


		-- Update SCR Referrals work with FirstAppointmentType
		UPDATE		Referrals
		SET			FirstAppointmentTypeDesc = AppType.TYPE_DESC
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblAPP_TYPE AppType
						ON	Referrals.FirstAppointmentTypeCode = AppType.TYPE_CODE	--links to first appointment type
		
		
		-- Update SCR Referrals work with ReasonNoAppointment
		UPDATE		Referrals
		SET			ReasonNoAppointmentDesc = NoAppReason.APP_DESC
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals
		INNER JOIN	LocalConfig.ltblNO_APP NoAppReason
						ON	Referrals.ReasonNoAppointmentCode = NoAppReason.APP_CODE	--links to reason no appointment

		
		--UPDATE SCR Referrals Work with First Seen Adjustment Reason Lookup
		UPDATE		Referrals
		SET			FirstSeenAdjReasonDesc = Canx.CANCELLED_DESC
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals     
		INNER JOIN	LocalConfig.ltblCANCELLATION Canx 
						ON	Referrals.FirstSeenAdjReasonCode = Canx.CANCELLED_CODE	--links to 2ww cancellation reason description lookup


		-- Update SCR Referrals Work with First Seen Delay Reason
		UPDATE		Referrals
		SET			FirstSeenDelayReasonDesc = DelayReason.CWTValue
		FROM		SCR_Warehouse.SCR_Referrals_Work Referrals
		INNER JOIN	LocalConfig.ltblDELAY_REASON DelayReason
						ON	Referrals.FirstSeenDelayReasonCode = DelayReason.DELAY_CODE


		-- Update SCR Referrals Work with DTT Adjustment Reason
		UPDATE		Referrals
		SET			DTTAdjReasonDesc = adjtx.ADJ_REASON_DESC
		FROM		SCR_Warehouse.SCR_Referrals_Work Referrals
		INNER JOIN	LocalConfig.ltblADJ_TREATMENT adjtx
						ON	Referrals.DTTAdjReasonCode = adjtx.ADJ_REASON_CODE

		-- Keep a record of when the metadata-lookups for SCR Referrals update finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'metadata-lookups for SCR Referrals update'
				

/************************************************************************************************************************************************************************************************************
-- Update metadata-lookups for SCR CWT Work table
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the metadata-lookups for SCR CWT update started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'metadata-lookups for SCR CWT update'
				
		--Update lookup data from definitive treatment (definitive type, treatment setting & treatment event) into SCR CWT Work 
		UPDATE		CWT
		SET			DeftTreatmentEventDesc = Teve.EVENT_DESC
					,DeftTreatmentDesc = Ttype.TREAT_DESC
					,DeftTreatmentSettingDesc = Tset.SET_DESC
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	LocalConfig.ltblDEFINITIVE_TYPE Ttype 
						ON	CWT.DeftTreatmentCode = Ttype.TREAT_CODE				--links treatment table to treatment type lookup
		LEFT JOIN	LocalConfig.ltblTREATMENT_SETTING Tset 
						ON	CWT.DeftTreatmentSettingCode = Tset.SET_CODE			--links to treatment setting description lookup
		LEFT JOIN	LocalConfig.ltblTREATMENT_EVENT Teve 
						ON CWT.DeftTreatmentEventCode = Teve.EVENT_CODE				--links to treatment event description lookup


		--Update DTT Adjustment Reason lookup data from definitive treatment into SCR CWT Work 
		UPDATE		CWT
		SET			DeftDTTAdjReasonDesc = adjtx.ADJ_REASON_DESC
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	LocalConfig.ltblADJ_TREATMENT adjtx 
						ON	CWT.DeftDTTAdjReasonCode = adjtx.ADJ_REASON_CODE
  
  
		--Update Org Code DTT lookup data from definitive treatment into SCR CWT Work
		UPDATE		CWT
		SET			DeftOrgIdDecisionTreat = Sites.ID
					,DeftOrgDescDecisionTreat = Sites.Description
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	(SELECT		*
								,ROW_NUMBER() OVER (PARTITION BY Code ORDER BY IsDeleted ASC, ID ASC) AS Ix 
					FROM		LocalConfig.OrganisationSites
					) Sites
						ON	CWT.DeftOrgCodeDecisionTreat = Sites.Code
						AND	Sites.Ix = 1
  
  
		--Update Org Code Treatment lookup data from definitive treatment into SCR CWT Work
		UPDATE		CWT
		SET			DeftOrgIdTreatment = Sites.ID
					,DeftOrgDescTreatment = Sites.Description
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	(SELECT		*
								,ROW_NUMBER() OVER (PARTITION BY Code ORDER BY IsDeleted ASC, ID ASC) AS Ix 
					FROM		LocalConfig.OrganisationSites
					) Sites
						ON	CWT.DeftOrgCodeTreatment = Sites.Code
						AND	Sites.Ix = 1


		--Update looukup data from Modality treatments (definitive type, treatment setting & treatment event) into SCR CWT Work 
		UPDATE		CWT
		SET			TxModTreatmentEventDesc = Teve.EVENT_DESC
					,TxModTreatmentDesc = Ttype.TREAT_DESC
					,TxModTreatmentSettingDesc = Tset.SET_DESC
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	LocalConfig.ltblDEFINITIVE_TYPE Ttype 
						ON	CWT.TxModTreatmentCode = Ttype.TREAT_CODE				--links treatment table to treatment type lookup
		LEFT JOIN	LocalConfig.ltblTREATMENT_SETTING Tset 
						ON	CWT.TxModTreatmentSettingCode = Tset.SET_CODE			--links to treatment setting description lookup
		LEFT JOIN	LocalConfig.ltblTREATMENT_EVENT Teve 
						ON CWT.TxModTreatmentEventCode = Teve.EVENT_CODE			--links to treatment event description lookup
  
  
		--Update Org Code DTT lookup data from Modality Treatments into SCR CWT Work
		UPDATE		CWT
		SET			TxModOrgIdDecisionTreat = Sites.ID
					,TxModOrgDescDecisionTreat = Sites.Description
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	(SELECT		*
								,ROW_NUMBER() OVER (PARTITION BY Code ORDER BY IsDeleted ASC, ID ASC) AS Ix 
					FROM		LocalConfig.OrganisationSites
					) Sites
						ON	CWT.TxModOrgCodeDecisionTreat = Sites.Code
						AND	Sites.Ix = 1
  
  
		--Update Org Code Treatment lookup data from Modality Treatments into SCR CWT Work
		UPDATE		CWT
		SET			TxModOrgIdTreatment = Sites.ID
					,TxModOrgDescTreatment = Sites.Description
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	(SELECT		*
								,ROW_NUMBER() OVER (PARTITION BY Code ORDER BY IsDeleted ASC, ID ASC) AS Ix 
					FROM		LocalConfig.OrganisationSites
					) Sites
						ON	CWT.TxModOrgCodeTreatment = Sites.Code
						AND	Sites.Ix = 1


		--Update looukup data from ChemRT linked Modality treatments (definitive type, treatment setting & treatment event) into SCR CWT Work 
		UPDATE		CWT
		SET			ChemRTLinkTreatmentEventDesc = Teve.EVENT_DESC
					,ChemRTLinkTreatmentDesc = Ttype.TREAT_DESC
					,ChemRTLinkTreatmentSettingDesc = Tset.SET_DESC
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	LocalConfig.ltblDEFINITIVE_TYPE Ttype 
						ON	CWT.ChemRTLinkTreatmentCode = Ttype.TREAT_CODE				--links treatment table to treatment type lookup
		LEFT JOIN	LocalConfig.ltblTREATMENT_SETTING Tset 
						ON	CWT.ChemRTLinkTreatmentSettingCode = Tset.SET_CODE			--links to treatment setting description lookup
		LEFT JOIN	LocalConfig.ltblTREATMENT_EVENT Teve 
						ON CWT.ChemRTLinkTreatmentEventCode = Teve.EVENT_CODE			--links to treatment event description lookup
  
  
		--Update Org Code DTT lookup data from ChemRT linked Modality Treatments into SCR CWT Work
		UPDATE		CWT
		SET			ChemRTLinkOrgIdDecisionTreat = Sites.ID
					,ChemRTLinkOrgDescDecisionTreat = Sites.Description
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	(SELECT		*
								,ROW_NUMBER() OVER (PARTITION BY Code ORDER BY IsDeleted ASC, ID ASC) AS Ix 
					FROM		LocalConfig.OrganisationSites
					) Sites
						ON	CWT.ChemRTLinkOrgCodeDecisionTreat = Sites.Code
						AND	Sites.Ix = 1
  
  
		--Update Org Code Treatment lookup data from ChemRT linked Modality Treatments into SCR CWT Work
		UPDATE		CWT
		SET			ChemRTLinkOrgIdTreatment = Sites.ID
					,ChemRTLinkOrgDescTreatment = Sites.Description
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	(SELECT		*
								,ROW_NUMBER() OVER (PARTITION BY Code ORDER BY IsDeleted ASC, ID ASC) AS Ix 
					FROM		LocalConfig.OrganisationSites
					) Sites
						ON	CWT.ChemRTLinkOrgCodeTreatment = Sites.Code
						AND	Sites.Ix = 1

		--Update Weighting to indicate shared patients and tertiary referrals
		UPDATE		CWT
		SET			Weighting		=	CASE
										WHEN	LEFT(Ref.OrgCodeFirstSeen, 3) != LocalConfig.fnOdsCode()
										AND		LEFT(CWT.DeftOrgCodeTreatment, 3) != LocalConfig.fnOdsCode()
										THEN	0
										WHEN	LEFT(Ref.OrgCodeFirstSeen, 3) != LocalConfig.fnOdsCode()
										OR		LEFT(CWT.DeftOrgCodeTreatment, 3) != LocalConfig.fnOdsCode()
										THEN	0.5
										ELSE	1.0
										END 
		FROM		SCR_Warehouse.SCR_Referrals_work Ref
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT	ON Ref.CARE_ID	= CWT.CARE_ID

		-- Keep a record of when the metadata-lookups for SCR CWT update finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'metadata-lookups for SCR CWT update'
				
    

/************************************************************************************************************************************************************************************************************
-- Update the Wait table cwtFlags
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the Wait table cwtFlags update started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'Wait table cwtFlags update'
				
		UPDATE		CWT
		SET			cwtReason2WW	=		CASE	/*************** Do Closed Pathway Reasons first ***************/
											-- Transferred Referrals
											WHEN	Referrals.TransferReason = 1				-- Referral has been transferred to a new referral
											OR		(Referrals.InappropriateRef = 1				-- Other Tumour Site - Make New Referral
											AND			(Referrals.TransferReason IS NULL		-- The InappropriateRef flag only applies when there isn't a transfer reason (probably the first iteration of the referral transfer functionality where the TransferReason field didn't exist)
											OR			Referrals.TransferReason = 1)			-- or when the TransferReason is 1, Transferred (probably the second iteration of the referral transfer functionality where it was realised that referral merges were also required)
													)
											THEN	9	-- 0, Closed
											-- Downgraded / Discharged before being seen
											WHEN	(Referrals.DateFirstSeen IS NULL			-- No first appointment date
											AND		Referrals.PatientStatusCode = '03')			-- No new cancer diagnosis identified (needs to be entered to remove the patient from the PTL)
											OR		Referrals.FirstAppointmentTypeCode = 1		-- No first appointment (Em adm, refused, retracted / downgraded, gone private, died or "other")
											THEN	2	-- 0, Closed						
											
													/*************** Do Reportable Pathway Reasons next ***************/					
											-- Seen, No Cancer Diagnosis (Discharged / Declined / Deceased)
											WHEN	Referrals.DateFirstSeen IS NOT NULL			-- Has first appointment date
											AND		Referrals.PatientStatusCode = '03'			-- Has an outcome - No new cancer diagnosis identified
											THEN	3	-- 2, Reportable

											-- Seen, Further Investigation
											WHEN	Referrals.DateFirstSeen IS NOT NULL			-- Has first appointment date
											AND		Referrals.DateFirstSeen <= Referrals.ReportDate	-- Not a future appointment (clock doesn't stop until they have been seen)
											AND		Referrals.PatientStatusCode != '03'			-- Has a Patient Status Code which is not "No new cancer diagnosis identified"
											THEN	4	-- 2, Reportable						
											
													/*************** Do Closed Pathway Reasons (where you only want them closed if there isn't a reportable reason) next ***************/ --!!! NB !!! Add these reasons to DQ query 74: Patients who will appear on the CWT, but won't be on the PTL
											-- "Other" Patient Status inc. Duplicate or "Other Tumour Site" (over-ridden if the patient was seen)
											WHEN	Referrals.PatientStatusCode = '69'			-- Other tumour site (takes patients off the PTL as long as they haven't been seen)
											THEN	10	-- 0, Closed
											-- Diagnosis of new cancer confirmed - no NHS funded treatment planned
											WHEN	Referrals.PatientStatusCode = '07'			-- Diagnosis of new cancer confirmed - no NHS funded treatment planned
											THEN	11	-- 0, Closed
											-- Tumour status of Recurrence or Metastasis
											WHEN	Referrals.TumourStatusCode IN (4, 5)		-- Tumour status of Recurrence or Metastasis
											THEN	12	-- 0, Closed					
											
													/*************** Do Open Pathway Reasons (including subcategories of open pathways) next ***************/
											-- Else Open
											ELSE	1 -- Open
											END
					,cwtType2WW	=	CASE	WHEN ISNULL(Referrals.CancerTypeCode, 0) = 16		-- Breast Symptomatic
											THEN 1												-- Breast Symptomatic
											ELSE 0												-- 2WW
											END
		FROM		SCR_Warehouse.SCR_CWT_Work CWT
		LEFT JOIN	SCR_Warehouse.SCR_Referrals_Work Referrals
						ON	CWT.CARE_ID = Referrals.CARE_ID
		WHERE		(Referrals.PriorityTypeCode = '03'											-- 2WW urgency
		OR			ISNULL(Referrals.CancerTypeCode, 0) = 16)									-- Symptomatic Breast Referral
		--AND			Referrals.DateConsultantUpgrade IS NULL									-- Not an upgrade
		--AND			ISNULL(Referrals.SourceReferralCode,0) != 17							-- Not a screening 2WW referral
		AND			ISNULL(CWT.DeftDefinitiveTreatment, 1) = 1									-- Not Subsequent / Multiple Diagnosis / Incidental Finding


		-- Update 2WW flags from the cwtReasonID, or mark as not applicable is there is no cwtReason
		UPDATE		CWT
		SET			cwtFlag2WW	=	CASE	WHEN Reasons.applicable2ww = 1 -- the cwtReason is applicable to the 2ww flag
											THEN Reasons.cwtFlagID
											WHEN Reasons.applicable2ww = 0 -- the cwtReason is not applicable to the 2ww flag
											THEN 5 -- error!
											WHEN CWT.cwtReason2WW IS NULL
											THEN 4 -- not applicable
											ELSE 5 -- error!
											END
		FROM		SCR_Warehouse.SCR_CWT_Work CWT
		LEFT JOIN	lookup.cwtReasons Reasons
						ON	CWT.cwtReason2WW = Reasons.cwtReasonID

		--update 28 day reason and flags  
		UPDATE		CWT
		SET			cwtReason28	=		CASE	/*************** Do Closed Pathway Reasons first ***************/
											-- Transferred Referrals
											WHEN	Referrals.TransferReason = 1				-- Referral has been transferred to a new referral
											OR		(Referrals.InappropriateRef = 1				-- Other Tumour Site - Make New Referral
											AND			(Referrals.TransferReason IS NULL		-- The InappropriateRef flag only applies when there isn't a transfer reason (probably the first iteration of the referral transfer functionality where the TransferReason field didn't exist)
											OR			Referrals.TransferReason = 1)			-- or when the TransferReason is 1, Transferred (probably the second iteration of the referral transfer functionality where it was realised that referral merges were also required)
													)
											THEN	9	-- 0, Closed

											-- "Other" Patient Status inc. Duplicate or "Other Tumour Site" (over-ridden if the patient was seen)
											WHEN	Referrals.PatientStatusCode = '69'			-- Other tumour site (takes patients off the PTL as long as they haven't been seen)
											THEN	10	-- 0, Closed

											-- Downgraded / Discharged before being seen
											WHEN	(Referrals.DateFirstSeen IS NULL			-- No first appointment date
											AND		Referrals.PatientStatusCode = '03')			-- No new cancer diagnosis identified (needs to be entered to remove the patient from the PTL)
											OR		Referrals.FirstAppointmentTypeCode = 1		-- No first appointment (Em adm, refused, retracted / downgraded, gone private, died or "other")
											THEN	2	-- 0, Closed
											
											-- Diagnosis of new cancer confirmed - no NHS funded treatment planned
											WHEN	Referrals.DateFirstSeen IS NULL				-- No first appointment date
											AND		Referrals.PatientStatusCode = '07'			-- Diagnosis of new cancer confirmed - no NHS funded treatment planned
											THEN	11	-- 0, Closed	
											
											-- Tumour status of Recurrence or Metastasis
											WHEN	Referrals.DateFirstSeen IS NULL				-- No first appointment date
											AND		Referrals.TumourStatusCode IN (4, 5)		-- Tumour status of Recurrence or Metastasis
											THEN	12	-- 0, Closed
											
													/*************** Do Reportable Pathway Reasons next ***************/	
													
											-- Excluded from 28 Day Pathway
											WHEN	Referrals.FastDiagEndReasonID = 3
											THEN	14	-- 2, Reportable
											
											-- Patient Informed - Diagnosis of Cancer
											WHEN	Referrals.FastDiagEndReasonID = 1
											THEN	15	-- 2, Reportable

											-- Patient Informed - Ruling out of Cancer
											WHEN	Referrals.FastDiagEndReasonID = 2
											THEN	16	-- 2, Reportable					
											
													/*************** Do Closed Pathway Reasons (where you only want them closed if there isn't a reportable reason) next ***************/ --!!! NB !!! Add these reasons to DQ query 74: Patients who will appear on the CWT, but won't be on the PTL

													/*************** Do Open Pathway Reasons (including subcategories of open pathways) next ***************/

											-- Else Open
											ELSE	1 -- Open
											END
					,cwtType28	=			2

		FROM		SCR_Warehouse.SCR_CWT_Work CWT
		LEFT JOIN	SCR_Warehouse.SCR_Referrals_Work Referrals
						ON	CWT.CARE_ID = Referrals.CARE_ID
		WHERE		(Referrals.PriorityTypeCode = '03'											-- 2WW urgency
		OR			ISNULL(Referrals.CancerTypeCode, 0) = 16									-- Symptomatic Breast Referral
		OR			(ISNULL(Referrals.SourceReferralCode,0) = 17								-- Urgent Screening Referral
		AND			Referrals.PriorityTypeCode = '02')											-- Urgent Screening Referral
		--AND			Referrals.DateConsultantUpgrade IS NULL										-- Not an upgrade
		AND			ISNULL(CWT.DeftDefinitiveTreatment, 1) = 1									-- Not Subsequent / Multiple Diagnosis / Incidental Finding

		)

		-- Update Faster Diagnosis (28 day) flag from the cwtReasonID, or mark as not applicable is there is no cwtReason
		UPDATE		CWT
		SET			cwtFlag28	=	CASE	WHEN Reasons.applicable28 = 1 -- the cwtReason is applicable to the 2ww flag
											THEN Reasons.cwtFlagID
											WHEN Reasons.applicable28 = 0 -- the cwtReason is not applicable to the 28day flag 
											THEN 5 -- error!
											WHEN CWT.cwtReason28 IS NULL
											THEN 4 -- not applicable
											ELSE 5 -- error!
											END
		FROM		SCR_Warehouse.SCR_CWT_Work CWT
		LEFT JOIN	lookup.cwtReasons Reasons
						ON	CWT.cwtReason28 = Reasons.cwtReasonID

		/*
		UPDATE		SCR_Warehouse.SCR_CWT_work
		SET			cwtFlag28 = NULL
		*/

		-- DTT to FDT (31 day) flag
				/*
				SELECT		CASE	WHEN PatientStatusCode IN ('03','07','15','16','17','18','19','20','69')
							THEN 'A'
							WHEN TumourStatusCode IN (1, 2)  -- Unknown or Primary
							THEN 'B'
							WHEN ((DiagnosisCode >= 'C00' AND DiagnosisCode < 'C98') OR DiagnosisCode = 'D05') 
							AND NOT (DiagnosisCode = 'C44' AND LEFT(Histology,6) IN ('M80903','M80913','M80923','M80933','M80943','M80953','M81103'))
							THEN 'C'
							END
				WHERE = A diagnosis date or decision to treat date is taken as the clock start / indicator of the DTT
				*/
			-- DTT to 2nd surgery flag
			-- DTT to 2nd chemo flag
			-- DTT to 2nd radio flag
		
		/*
		UPDATE		SCR_Warehouse.SCR_CWT_work
		SET			cwtFlag31 = NULL
		*/

		-- Referral to FDT (62 day) flag
		UPDATE		CWT
		SET			cwtReason62	=	CASE	/*************** Do Closed Pathway Reasons first ***************/
											-- Transferred Referrals
											WHEN	Referrals.TransferReason = 1				-- Referral has been transferred to a new referral
											OR		(Referrals.InappropriateRef = 1				-- Other Tumour Site - Make New Referral
											AND			(Referrals.TransferReason IS NULL		-- The InappropriateRef flag only applies when there isn't a transfer reason (probably the first iteration of the referral transfer functionality where the TransferReason field didn't exist)
											OR			Referrals.TransferReason = 1)			-- or when the TransferReason is 1, Transferred (probably the second iteration of the referral transfer functionality where it was realised that referral merges were also required)
													)
											THEN	9	-- 0, Closed
											-- Downgraded / Discharged before being first seen
											WHEN	Referrals.FirstAppointmentTypeCode = 1		-- No first appointment (Em adm, refused, retracted / downgraded, gone private, died or "other")
											AND		ISNULL(Referrals.ReasonNoAppointmentCode, 0) IN (1,2,3,4,5) -- with a reason why there was no appointment that would cause the 62 day period to stop
											THEN	2	-- 0, Closed							
											-- No new cancer (Discharged / Declined / Deceased)
											WHEN	Referrals.PatientStatusCode = '03'			-- Has an outcome - No new cancer diagnosis identified
											THEN	5	-- 0, Closed								
											-- No further treatment planned
											WHEN	Referrals.PatientStatusCode = '07'			-- Has an outcome - Primary - no NHS funded treatment planned
											THEN	11	-- 0, Closed						
											-- Diagnosed as non-CWT type of cancer
											WHEN	Referrals.IsCwtCancerDiagnosis = 0
											THEN	6	-- 0, Closed							
											-- Diagnosed as Recurrence / Metastases
											WHEN	Referrals.TumourStatusCode IN (4, 5)		-- Recurrence / Metastases
											OR		Referrals.PatientStatusCode IN ('15','16','17','18','19','20')	-- Not Recurrence / Subsequent
											THEN	7	-- 0, Closed				
											
													/*************** Do Reportable Pathway Reasons next ***************/
											-- Treated
											WHEN	Referrals.IsCwtCancerDiagnosis = 1			-- Diagnosed
											AND		CWT.DeftDateTreatment IS NOT NULL
											THEN	8 -- 2, Reportable							
											
													/*************** Do Closed Pathway Reasons (where you only want them closed if there isn't a reportable reason) next ***************/ --!!! NB !!! Add these reasons to DQ query 74: Patients who will appear on the CWT, but won't be on the PTL
											-- "Other" Patient Status inc. Duplicate or "Other Tumour Site" (over-ridden if the patient was seen)
											WHEN	Referrals.PatientStatusCode = '69'			-- Other tumour site (takes patients off the PTL as long as they haven't been seen)
											THEN	10	-- 0, Closed			
											
													/*************** Do Open Pathway Reasons (including subcategories of open pathways) next ***************/
											-- Treated Undiagnosed
											WHEN	Referrals.IsCwtCancerDiagnosis = -1			-- Undiagnosed
											AND		CWT.DeftDateTreatment IS NOT NULL			-- Treated
											THEN	13 -- 1, Open							
											-- Else Open
											ELSE	1 -- Open
											END
					,cwtType62	=	CASE	WHEN	ISNULL(Referrals.SourceReferralCode,0) = 17		-- Screening
											THEN	8												-- Screening to FDT flag
											WHEN	Referrals.DateConsultantUpgrade IS NOT NULL		-- Upgrade
											THEN	9												-- Upgrade to FDT flag
											WHEN	Referrals.CancerTypeCode = '02'					-- Childrens Cancer Type
											THEN	10												-- Rare Cancer Ref to FDT flag
											WHEN	Referrals.AgeAtReferral < 16					-- Child at referral
											AND		ISNULL(Referrals.CancerTypeCode, '') != '16'	-- Not Breast Symptomatic
											THEN	10												-- Rare Cancer Ref to FDT flag
											WHEN	Referrals.CancerTypeCode IN ('12','05')			-- Testicular or Acute Leukaemia Cancer Types
											AND		Referrals.DiagnosisSubCode IS NULL				-- Not yet diagnosed as not testicular or acute leukaemia
											THEN	10												-- Rare Cancer Ref to FDT flag
											WHEN	LEFT(Referrals.DiagnosisSubCode, 3) = 'C62'		-- Diagnosed as testicular
											OR		diag.IsLeukaemiaCode = 1						-- Diagnosed as acute leukaemia
											THEN	10												-- Rare Cancer Ref to FDT flag
											ELSE	7												-- Ref to FDT Flag
											END
		FROM		SCR_Warehouse.SCR_CWT_Work CWT
		LEFT JOIN	SCR_Warehouse.SCR_Referrals_Work Referrals
						ON	CWT.CARE_ID = Referrals.CARE_ID
		LEFT JOIN	LocalConfig.ltblDIAGNOSIS diag
						ON	Referrals.DiagnosisSubCode = diag.DIAG_CODE
		WHERE		ISNULL(CWT.DeftDefinitiveTreatment, 0) != 2									-- Not Subsequent / Multiple Diagnosis / Incidental Finding
		AND			(Referrals.PriorityTypeCode = '03'											-- 2WW referrals only
		OR			(ISNULL(Referrals.SourceReferralCode,0) = 17								-- Urgent Screening Referral
		AND			Referrals.PriorityTypeCode = '02')											-- Urgent Screening Referral
		OR			Referrals.DateConsultantUpgrade IS NOT NULL)								-- Upgrade
		AND			CWT.TREATMENT_ID IS NOT NULL												-- Has a Deft record
					

		-- Update 62 day flags from the cwtReasonID, or mark as not applicable is there is no cwtReason
		UPDATE		CWT
		SET			cwtFlag62	=	CASE	WHEN Reasons.applicable62 = 1 -- the cwtReason is applicable to the 62 day flag
											THEN Reasons.cwtFlagID
											WHEN Reasons.applicable62 = 0 -- the cwtReason is not applicable to the 62 day flag 
											THEN 5 -- error!
											WHEN CWT.cwtReason62 IS NULL
											THEN 4 -- not applicable
											ELSE 5 -- error!
											END
		FROM		SCR_Warehouse.SCR_CWT_Work CWT
		LEFT JOIN	lookup.cwtReasons Reasons
						ON	CWT.cwtReason62 = Reasons.cwtReasonID

		
		-- Active Cancer Referral Flag
			-- Transferred Referrals are closed - L_TUMOUR_STATUS = 7 or TRANSFER_REASON IS NOT NULL

		/*
		SELECT * FROM LocalConfig.ltblSTATUS
		SELECT * FROM LocalConfig.ltblCA_STATUS
		SELECT * FROM LocalConfig.ltblPRIORITY_TYPE
		SELECT * FROM Lookup.cwtTypes
		SELECT * FROM Lookup.cwtReasons
		SELECT * FROM LocalConfig.ltblCANCER_TYPE
		SELECT * FROM LocalConfig.ltblSOURCE_REFERRAL
		SELECT * FROM LocalConfig.ltblAPP_TYPE
		SELECT * FROM LocalConfig.ltblOUT_PATIENT_REFERRAL
		SELECT * FROM LocalConfig.ltblNO_APP
		SELECT * FROM LocalConfig.ltblDEFINITIVE_TYPE
		SELECT * FROM LocalConfig.ltblCANCER_SITES
		SELECT * FROM LocalConfig.ltblTRANSFER_REASON
		*/

		-- Keep a record of when the Wait table cwtFlags update started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'Wait table cwtFlags update'
				
		

/************************************************************************************************************************************************************************************************************
-- Update the CWT calculations
************************************************************************************************************************************************************************************************************/

		
		-- Keep a record of when the CWT calculations update started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'CWT calculations update'
				
		-- Update the 2WW & 31 Day Clock Start Dates
		UPDATE		CWT
		SET			ClockStartDate2WW		=	CAST(ISNULL(Referral.DateConsultantUpgrade, Referral.DateReceipt) AS date)
					,ClockStartDate31		=	CASE	
												WHEN	CWT.DeftDateDecisionTreat > CWT.DeftDateTreatment
												THEN	CAST(CWT.DeftDateTreatment AS date)
												ELSE	CAST(CWT.DeftDateDecisionTreat AS date)
												END
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	SCR_Warehouse.SCR_Referrals_work Referral
						ON	CWT.CARE_ID = Referral.CARE_ID
		
		
		-- Update the Faster Diagnosis and 62 Day Clock Start Dates
		UPDATE		CWT
		SET			ClockStartDate28	=	ClockStartDate2WW
					,ClockStartDate62	=	ClockStartDate2WW
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		
		
		-- Update the 2WW & 31 Day AdjTime fields
		UPDATE		CWT
		SET			AdjTime2WW		=	CASE	
										WHEN	Referral.FirstSeenAdjReasonCode = 3		-- DNA First Appt
										THEN	ISNULL(DATEDIFF(dd, CWT.ClockStartDate2WW, CAST(Referral.AppointmentCancelledDate AS date)), 0)
										ELSE	0
										END
					,AdjTime31		=	CASE
										WHEN	CWT.DeftDefinitiveTreatment = 1				-- First Definitive Treatment
										AND		Referral.DTTAdjReasonCode = 8				-- Patient Pause (referral record)
										AND		CWT.DeftTreatmentSettingCode IN ('01','02')	-- Inpatient / Daycase
										THEN	ISNULL(Referral.DTTAdjTime, 0)
										WHEN	ISNULL(CWT.DeftDefinitiveTreatment, 0) != 1	-- Not First Definitive Treatment
										AND		CWT.DeftDTTAdjReasonCode = 8				-- Patient Pause (deft record) - Subsequent treatments adjustments only
										AND		CWT.DeftTreatmentSettingCode IN ('01','02')	-- Inpatient / Daycase
										THEN	ISNULL(CWT.DeftDTTAdjTime, 0)
										ELSE	0
										END
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	SCR_Warehouse.SCR_Referrals_work Referral
						ON	CWT.CARE_ID = Referral.CARE_ID
		
		
		-- Update the Faster Diagnosis and 62 Day AdjTime fields
		UPDATE		CWT
		SET			AdjTime28	=	AdjTime2WW
					,AdjTime62	=	AdjTime2WW + 
									CASE
									WHEN	CWT.DeftDefinitiveTreatment = 1	-- First Definitive Treatment (shouldn't be necessary, as this is compensated for in the previous query, but just in case)
									THEN	AdjTime31
									ELSE	0
									END
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		

		-- Update the TargetDate fields
		UPDATE		CWT
		SET			TargetDate2WW		=	dateadd(dd, wt2WW.WaitTargetDays + CWT.AdjTime2WW, CWT.ClockStartDate2WW)	
					,TargetDate28		=	dateadd(dd, wt28.WaitTargetDays + CWT.AdjTime28, CWT.ClockStartDate28)	
					,TargetDate31		=	dateadd(dd, wt31.WaitTargetDays + CWT.AdjTime31, CWT.ClockStartDate31)
					,TargetDate62		=	dateadd(dd, wt62.WaitTargetDays + CWT.AdjTime62, CWT.ClockStartDate62)
		FROM		SCR_Warehouse.SCR_CWT_Work CWT
		LEFT JOIN	Lookup.cwtTypes cwtType2WW
						ON	CWT.cwtType2WW = cwtType2WW.cwtTypeID
		LEFT JOIN	Lookup.WaitTargets wt2WW
						ON	cwtType2WW.cwtStandard_WaitTargetId = wt2WW.WaitTargetId
		LEFT JOIN	Lookup.cwtTypes cwtType28
						ON	CWT.cwtType28 = cwtType28.cwtTypeID
		LEFT JOIN	Lookup.WaitTargets wt28
						ON	cwtType28.cwtStandard_WaitTargetId = wt28.WaitTargetId
		LEFT JOIN	Lookup.cwtTypes cwtType31
						ON	CWT.cwtType31 = cwtType31.cwtTypeID
		LEFT JOIN	Lookup.WaitTargets wt31
						ON	cwtType31.cwtStandard_WaitTargetId = wt31.WaitTargetId
		LEFT JOIN	Lookup.cwtTypes cwtType62
						ON	CWT.cwtType62 = cwtType62.cwtTypeID
		LEFT JOIN	Lookup.WaitTargets wt62
						ON	cwtType62.cwtStandard_WaitTargetId = wt62.WaitTargetId


		-- Update the Will Be Clock Stop fields
		UPDATE		CWT
		SET			WillBeClockStopDate2WW	=	CAST(Referral.DateFirstSeen AS date)
					,WillBeClockStopDate28	=	CASE 
												WHEN	Referral.FastDiagEndReasonID = 3
												THEN	CAST(Referral.FastDiagExclDate AS date)
												WHEN	EarliestDTT.DecisionDate < Referral.FastDiagInformedDate OR Referral.FastDiagInformedDate IS NULL 
												THEN	CAST(EarliestDTT.DecisionDate AS date)
												ELSE	CAST(Referral.FastDiagInformedDate AS date)
												END
					,WillBeClockStopDate31	=	CAST(CWT.DeftDateTreatment AS date)
					,WillBeClockStopDate62	=	CAST(CWT.DeftDateTreatment AS date)
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		LEFT JOIN	SCR_Warehouse.SCR_Referrals_work Referral
						ON	CWT.CARE_ID = Referral.CARE_ID
		LEFT JOIN	(SELECT		mr.CARE_ID
								,MIN(dt.DECISION_DATE) AS DecisionDate
					FROM		LocalConfig.tblMAIN_REFERRALS mr
					LEFT JOIN	LocalConfig.tblDEFINITIVE_TREATMENT dt
									ON	mr.CARE_ID = dt.CARE_ID
									AND	(dt.DECISION_DATE IS NULL 
									OR	dt.DECISION_DATE >= mr.N2_6_RECEIPT_DATE)
					GROUP BY	mr.CARE_ID) AS EarliestDTT
						ON	Referral.CARE_ID = EarliestDTT.CARE_ID


		-- Update the Clock Stop fields
		UPDATE		CWT
		SET			ClockStopDate2WW		=	CASE
												WHEN	CAST(WillBeClockStopDate2WW AS date) <= CAST(Referral.ReportDate AS date)
												THEN	CAST(WillBeClockStopDate2WW AS date)
												END
					,ClockStopDate28		=	CASE 
												WHEN	CAST(WillBeClockStopDate28 AS date) <= CAST(Referral.ReportDate AS date)
												THEN	CAST(WillBeClockStopDate28 AS date)
												END
					,ClockStopDate31		=	CASE
												WHEN	CAST(WillBeClockStopDate31 AS date) <= CAST(Referral.ReportDate AS date)
												THEN	CAST(WillBeClockStopDate31 AS date)
												END
					,ClockStopDate62		=	CASE
												WHEN	CAST(WillBeClockStopDate62 AS date) <= CAST(Referral.ReportDate AS date)
												THEN	CAST(WillBeClockStopDate62 AS date)
												END
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		LEFT JOIN	SCR_Warehouse.SCR_Referrals_work Referral
						ON	CWT.CARE_ID = Referral.CARE_ID


		-- Update the Waiting Time fields
		UPDATE		CWT
		SET			Waitingtime2WW			=	DATEDIFF(d, CWT.ClockStartDate2WW, ISNULL(CWT.ClockStopDate2WW, CAST(CWT.ReportDate AS date)))
												- AdjTime2WW
					,WillBeWaitingtime2WW	=	DATEDIFF(d, CWT.ClockStartDate2WW, CWT.WillBeClockStopDate2WW)
												- AdjTime2WW
					,Waitingtime28			=	DATEDIFF(d, CWT.ClockStartDate28, ISNULL(CWT.ClockStopDate28, CAST(CWT.ReportDate AS date)))
												- AdjTime28
					,WillBeWaitingtime28	=	DATEDIFF(d, CWT.ClockStartDate28, CWT.WillBeClockStopDate28)
												- AdjTime28
					,Waitingtime31			=	DATEDIFF(d, CWT.ClockStartDate31, ISNULL(CWT.ClockStopDate31, CAST(CWT.ReportDate AS date)))
												- AdjTime31
					,WillBeWaitingtime31	=	DATEDIFF(d, CWT.ClockStartDate31, CWT.WillBeClockStopDate31)
												- AdjTime31
					,Waitingtime62			=	DATEDIFF(d, CWT.ClockStartDate62, ISNULL(CWT.ClockStopDate62, CAST(CWT.ReportDate AS date)))
												- AdjTime62
					,WillBeWaitingtime62	=	DATEDIFF(d, CWT.ClockStartDate62, CWT.WillBeClockStopDate62)
												- AdjTime62
		FROM		SCR_Warehouse.SCR_CWT_work CWT


		-- Update the DaysToBreach fields
		UPDATE		CWT
		SET			DaysTo2WWBreach		=	DATEDIFF(d, ISNULL(CWT.ClockStopDate2WW, CAST(CWT.ReportDate AS date)),TargetDate2WW)
					,DaysTo28DayBreach	=	DATEDIFF(d, ISNULL(CWT.ClockStopDate28, CAST(CWT.ReportDate AS date)),TargetDate28)
					,DaysTo31DayBreach	=	DATEDIFF(d, ISNULL(CWT.ClockStopDate31, CAST(CWT.ReportDate AS date)),TargetDate31)
					,DaysTo62DayBreach	=	DATEDIFF(d, ISNULL(CWT.ClockStopDate62, CAST(CWT.ReportDate AS date)),TargetDate62)
		FROM		SCR_Warehouse.SCR_CWT_work CWT


		-- Update the Breach Flag fields
		UPDATE		CWT
		SET			Breach2WW			=	CASE
											WHEN	CWT.TargetDate2WW >= CAST(CWT.ReportDate AS date) 
											OR		CWT.TargetDate2WW >= CWT.ClockStopDate2WW
											THEN	0
											ELSE	1
											END
					,WillBeBreach2WW	=	CASE
											WHEN	CWT.TargetDate2WW >= CWT.WillBeClockStopDate2WW
											THEN	0
											ELSE	1
											END
					,Breach28			=	CASE
											WHEN	CWT.TargetDate28 >= CAST(CWT.ReportDate AS date) 
											OR		CWT.TargetDate28 >= CWT.ClockStopDate28
											THEN	0
											ELSE	1
											END
					,WillBeBreach28		=	CASE
											WHEN	CWT.TargetDate28 >= CWT.WillBeClockStopDate28
											THEN	0
											ELSE	1
											END
					,Breach31			=	CASE
											WHEN	CWT.TargetDate31 >= CAST(CWT.ReportDate AS date) 
											OR		CWT.TargetDate31 >= CWT.ClockStopDate31
											OR		CWT.ClockStartDate31 IS NULL
											THEN	0
											ELSE	1
											END
					,WillBeBreach31		=	CASE
											WHEN	CWT.TargetDate31 >= CWT.WillBeClockStopDate31
											THEN	0
											ELSE	1
											END
					,Breach62			=	CASE
											WHEN	CWT.TargetDate62 >= CAST(CWT.ReportDate AS date) 
											OR		CWT.TargetDate62 >= CWT.ClockStopDate62
											THEN	0
											ELSE	1
											END
					,WillBeBreach62		=	CASE
											WHEN	CWT.TargetDate62 >= CWT.WillBeClockStopDate62
											THEN	0
											ELSE	1
											END
		FROM		SCR_Warehouse.SCR_CWT_work CWT


		-- Calculate 62 days calculations (1st Pass)
		UPDATE		CWT
		SET			DaysTo62DayBreachNoDTT	=	CASE
												WHEN	CWT.DeftDateDecisionTreat IS NULL 
												AND		CWT.cwtFlag62 IN (0,1,2)
												THEN	CWT.DaysTo62DayBreach
												END
					,Treated7Days			=	CASE
												WHEN	DATEDIFF(d, CWT.ClockStopDate62, CAST(CWT.ReportDate AS date)) BETWEEN 0 AND 6
												THEN	1
												ELSE	0
												END
		FROM		SCR_Warehouse.SCR_CWT_work CWT


		-- Calculate 62 days calculations (2nd Pass)
		UPDATE		CWT
		SET			Treated7Days62Days		=	CASE
												WHEN	CWT.Treated7Days = 1
												AND		ISNULL(CWT.Breach62, 0) = 0 
												AND		CWT.DeftDateTreatment <= CAST(CWT.ReportDate AS date)
												THEN	1
												ELSE	0
												END
					,FutureAchieve62Days	=	CASE
												WHEN	CWT.Treated7Days = 1 
												AND		ISNULL(Breach62, 0) = 0
												AND		CWT.DeftDateTreatment > CAST(CWT.ReportDate AS date)
												THEN	1
												ELSE	0
												END
					,FutureFail62Days		=	CASE
												WHEN	CWT.Treated7Days = 1 
												AND		ISNULL(Breach62, 0) = 0
												AND		CWT.DeftDateTreatment > CAST(CWT.ReportDate AS date)
												THEN	1
												ELSE	0
												END
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		WHERE		CWT.cwtFlag62 IN (0,1,2)


		-- Calculate 31 days calculations (1st Pass)
		UPDATE		CWT
		SET			ActualWaitDTTTreatment	=	CASE
												WHEN	CWT.DeftDateTreatment IS NOT NULL
												AND		CWT.cwtFlag31 IN (0,1,2)
												THEN	DATEDIFF(d, CWT.DeftDateDecisionTreat, CWT.DeftDateTreatment)
												ELSE	0
												END
					,DTTTreated7Days		=	CASE
												WHEN	DATEDIFF(d, CWT.ClockStopDate31, CAST(CWT.ReportDate AS date)) BETWEEN 0 AND 6
												AND		CWT.cwtFlag31 IN (0,1,2)
												THEN	1
												ELSE	0
												END
					,FutureDTT				=	CASE
												WHEN	CWT.DeftDateDecisionTreat > CAST(CWT.ReportDate AS date)
												THEN	1
												ELSE	0
												END
		FROM		SCR_Warehouse.SCR_CWT_work CWT


		-- Calculate 31 days calculations (2nd Pass)
		UPDATE		CWT
		SET			Treated7Days31Days			=	CASE
													WHEN	CWT.DTTTreated7Days = 1
													AND		ISNULL(CWT.Breach31, 0) = 0 
													AND		CWT.DeftDateTreatment <= CAST(CWT.ReportDate AS date)
													THEN	DATEDIFF(d, CWT.DeftDateDecisionTreat, CWT.DeftDateTreatment)
													ELSE	0
													END
					,Treated7DaysBreach31Days	=	CASE
													WHEN	CWT.DTTTreated7Days = 1
													AND		ISNULL(CWT.Breach31, 0) = 0 
													AND		CWT.DeftDateTreatment <= CAST(CWT.ReportDate AS date)
													THEN	DATEDIFF(d, CWT.DeftDateDecisionTreat, CWT.DeftDateTreatment)
													ELSE	0
													END
					,FutureAchieve62Days		=	CASE
													WHEN	CWT.DTTTreated7Days = 1 
													AND		ISNULL(Breach31, 0) = 0
													AND		CWT.DeftDateTreatment > CAST(CWT.ReportDate AS date)
													THEN	1
													ELSE	0
													END
					,FutureFail62Days			=	CASE
													WHEN	CWT.DTTTreated7Days = 1 
													AND		ISNULL(Breach31, 0) = 0
													AND		CWT.DeftDateTreatment > CAST(CWT.ReportDate AS date)
													THEN	1
													ELSE	0
													END
					,NoDTTDate					=	CASE
													WHEN	CWT.DeftDateDecisionTreat IS NULL
													THEN	1
													ELSE	0
													END
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		WHERE		CWT.cwtFlag31 IN (0,1,2)

		-- Keep a record of when the CWT calculations update finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'CWT calculations update'


/************************************************************************************************************************************************************************************************************
-- Update dominant colour values and prioritise the CWT targets
************************************************************************************************************************************************************************************************************/
		
		-- Keep a record of when calculation for the RAG colour and priority for each waiting time standard has started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'CWT priority and RAG'

		-- Create a table that determines the report row RAG colour for each waiting time standard
		IF OBJECT_ID('SCR_Reporting.RAG_work') IS NOT NULL
			DROP TABLE SCR_Reporting.RAG_work
					
		SELECT		CWTi.CWT_ID
					--,MIN(wtrc.WaitTargetRagColourPriority) AS DominantPriority -- MB 22/04/2020 Change the dominant priority so that it only uses 2WW and 62 day priorities (at least, for now)
					,MIN(CASE WHEN (cwtTypes.cwtTypeID = CWTi.cwtType2WW AND (CWTi.cwtFlag2WW & 1) = 1 AND CWTi.Waitingtime2WW > wtrt.WaitTargetRagThresholdGreaterThanValue)
								OR (cwtTypes.cwtTypeID = CWTi.cwtType62 AND (CWTi.cwtFlag62 & 1) = 1 AND CWTi.Waitingtime62 > wtrt.WaitTargetRagThresholdGreaterThanValue) THEN wtrc.WaitTargetRagColourPriority END) AS DominantPriority
					,MIN(CASE WHEN (cwtTypes.cwtTypeID = CWTi.cwtType2WW AND (CWTi.cwtFlag2WW & 1) = 1 AND CWTi.Waitingtime2WW > wtrt.WaitTargetRagThresholdGreaterThanValue) THEN wtrc.WaitTargetRagColourPriority END) AS Priority2WW
					,MIN(CASE WHEN (cwtTypes.cwtTypeID = CWTi.cwtType28 AND (CWTi.cwtFlag28 & 1) = 1 AND CWTi.Waitingtime28 > wtrt.WaitTargetRagThresholdGreaterThanValue) THEN wtrc.WaitTargetRagColourPriority END) AS Priority28
					,MIN(CASE WHEN (cwtTypes.cwtTypeID = CWTi.cwtType31 AND (CWTi.cwtFlag31 & 1) = 1 AND CWTi.Waitingtime31 > wtrt.WaitTargetRagThresholdGreaterThanValue) THEN wtrc.WaitTargetRagColourPriority END) AS Priority31
					,MIN(CASE WHEN (cwtTypes.cwtTypeID = CWTi.cwtType62 AND (CWTi.cwtFlag62 & 1) = 1 AND CWTi.Waitingtime62 > wtrt.WaitTargetRagThresholdGreaterThanValue) THEN wtrc.WaitTargetRagColourPriority END) AS Priority62
		INTO		SCR_Reporting.RAG_work
		FROM		SCR_Warehouse.SCR_CWT_work CWTi
		INNER JOIN	Lookup.cwtTypes cwtTypes
						ON	CWTi.cwtType2WW = cwtTypes.cwtTypeID
						OR	CWTi.cwtType28 = cwtTypes.cwtTypeID
						OR	CWTi.cwtType31 = cwtTypes.cwtTypeID
						OR	CWTi.cwtType62 = cwtTypes.cwtTypeID
		INNER JOIN	LocalConfig.WaitTargetRagThresholds wtrt
						ON	cwtTypes.cwtStandard_WaitTargetId = wtrt.WaitTargetId
		INNER JOIN	Lookup.WaitTargetRagColours wtrc
						ON	wtrt.WaitTargetRagColourId = wtrc.WaitTargetRagColourId
		WHERE		(
					(cwtTypes.cwtTypeID = CWTi.cwtType2WW AND (CWTi.cwtFlag2WW & 1) = 1 AND CWTi.Waitingtime2WW > wtrt.WaitTargetRagThresholdGreaterThanValue)
		OR			(cwtTypes.cwtTypeID = CWTi.cwtType28 AND (CWTi.cwtFlag28 & 1) = 1 AND CWTi.Waitingtime28 > wtrt.WaitTargetRagThresholdGreaterThanValue)
		OR			(cwtTypes.cwtTypeID = CWTi.cwtType31 AND (CWTi.cwtFlag31 & 1) = 1 AND CWTi.Waitingtime31 > wtrt.WaitTargetRagThresholdGreaterThanValue)
		OR			(cwtTypes.cwtTypeID = CWTi.cwtType62 AND (CWTi.cwtFlag62 & 1) = 1 AND CWTi.Waitingtime62 > wtrt.WaitTargetRagThresholdGreaterThanValue)
					)
		GROUP BY	CWTi.CWT_ID

		ALTER TABLE SCR_Reporting.RAG_work
		ADD CONSTRAINT PK_RAG_work PRIMARY KEY (
				CWT_ID ASC
				)

		-- Update the RAG colours
		UPDATE		CWT
		SET			DominantColourValue				=	ISNULL(wtrcd.WaitTargetRagColourValue, 'No Color') 
					,ColourValue2WW 				=	ISNULL(wtrc2WW.WaitTargetRagColourValue, 'No Color')
					,ColourValue28Day				=	ISNULL(wtrc28.WaitTargetRagColourValue, 'No Color') 
					,ColourValue31Day				=	ISNULL(wtrc31.WaitTargetRagColourValue, 'No Color') 
					,ColourValue62Day				=	ISNULL(wtrc62.WaitTargetRagColourValue, 'No Color') 
					,DominantColourDesc 			=	ISNULL(wtrcd.WaitTargetRagColourDesc, 'No Colour') 
					,ColourDesc2WW 					=	ISNULL(wtrc2WW.WaitTargetRagColourDesc, 'No Colour')
					,ColourDesc28Day 				=	ISNULL(wtrc28.WaitTargetRagColourDesc, 'No Colour')
					,ColourDesc31Day 				=	ISNULL(wtrc31.WaitTargetRagColourDesc, 'No Colour')
					,ColourDesc62Day 				=	ISNULL(wtrc62.WaitTargetRagColourDesc, 'No Colour')
					,DominantPriority				=	RAG.DominantPriority
					,Priority2WW					=	RAG.Priority2WW
					,Priority28 					=	RAG.Priority28
					,Priority31 					=	RAG.Priority31
					,Priority62 					=	RAG.Priority62
					
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	SCR_Reporting.RAG_work RAG               --should this link to Ref or CWT
						ON	CWT.CWT_ID = RAG.CWT_ID
		LEFT JOIN	Lookup.WaitTargetRagColours wtrcd
						ON	RAG.DominantPriority = wtrcd.WaitTargetRagColourPriority
		LEFT JOIN	Lookup.WaitTargetRagColours wtrc2WW
						ON	RAG.Priority2WW = wtrc2WW.WaitTargetRagColourPriority
		LEFT JOIN	Lookup.WaitTargetRagColours wtrc28
						ON	RAG.Priority28 = wtrc28.WaitTargetRagColourPriority
		LEFT JOIN	Lookup.WaitTargetRagColours wtrc31
						ON	RAG.Priority31 = wtrc31.WaitTargetRagColourPriority
		LEFT JOIN	Lookup.WaitTargetRagColours wtrc62
						ON	RAG.Priority62 = wtrc62.WaitTargetRagColourPriority

		-- Keep a record of when calculation for the RAG colour and priority for each waiting time standard has finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'CWT priority and RAG'

/************************************************************************************************************************************************************************************************************
-- Update the CWT Status and PathwayType
************************************************************************************************************************************************************************************************************/

		
		-- Keep a record of when the CWT Status and Pathway update started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'CWT Status and pathway update'
				
		-- Update the DominantCWT Status
		UPDATE		CWT
		SET			CWTStatusCode2ww	=	cwts_2WW.cwtStatusId
					,CwtStatusCode28	=	cwts_28.cwtStatusId
					,CWTStatusCode62	=	cwts_62.cwtStatusId

		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	SCR_Warehouse.SCR_Referrals_work Ref
						ON	CWT.CARE_ID = Ref.CARE_ID
		LEFT JOIN	LocalConfig.ReportingCwtStatus cwts_2WW_checkValidity
						ON	LocalConfig.fnCWTStatusCode2WW (
								Ref.OrgCodeFirstSeen
								,CWT.cwtFlag2WW
								,Ref.DateFirstSeen
								,CWT.ReportDate
								,Ref.FirstAppointmentTypeCode
								,Ref.ReasonNoAppointmentCode) = cwts_2WW_checkValidity.cwtStatusId
						AND	cwts_2WW_checkValidity.applicable2WW = 1 -- so that we only return values that are valid for a 2WW pathway
						AND	cwts_2WW_checkValidity.IsDeleted = 0
		LEFT JOIN	LocalConfig.ReportingCwtStatus cwts_2WW
						ON	ISNULL(cwts_2WW_checkValidity.cwtStatusId, SCR_Warehouse.fnInvalidCWTStatusCode(CWT.cwtFlag2WW)) = cwts_2WW.cwtStatusId
		LEFT JOIN	LocalConfig.ReportingCwtStatus cwts_28_checkValidity
						ON	LocalConfig.fnCWTStatusCode28 (
								CWT.cwtFlag28
								,Ref.DateReceipt
								,Ref.OrgCodeDiagnosis
								,Ref.DateDiagnosis
								,CWT.Breach28
								,Ref.IsCwtCancerDiagnosis
								,Ref.DateFirstSeen
								,CWT.ReportDate) = cwts_28_checkValidity.cwtStatusId
						AND	cwts_28_checkValidity.applicable28 = 1 -- so that we only return values that are valid for a 28 day pathway
						AND	cwts_28_checkValidity.IsDeleted = 0
		LEFT JOIN	LocalConfig.ReportingCwtStatus cwts_28
						ON	ISNULL(cwts_28_checkValidity.cwtStatusId, SCR_Warehouse.fnInvalidCWTStatusCode(CWT.cwtFlag28)) = cwts_28.cwtStatusId
		LEFT JOIN	LocalConfig.ReportingCwtStatus cwts_62_checkValidity
						ON	LocalConfig.fnCWTStatusCode62 (
								Ref.OrgCodeFirstSeen
								,CWT.DeftOrgCodeTreatment
								,Ref.PatientStatusCode
								,Ref.DateDiagnosis
								,CWT.DeftDateTreatment
								,Ref.DateFirstSeen
								,CWT.cwtFlag2WW
								,CWT.cwtFlag62
								,Ref.IsCwtCancerDiagnosis
								,CWT.TargetDate62
								,CWT.ReportDate
								,Ref.FirstAppointmentTypeCode
								,Ref.DateReceipt
								,Ref.CancerSite) = cwts_62_checkValidity.cwtStatusId
						AND	cwts_62_checkValidity.applicable62 = 1 -- so that we only return values that are valid for a 62 day pathway
						AND	cwts_62_checkValidity.IsDeleted = 0
		LEFT JOIN	LocalConfig.ReportingCwtStatus cwts_62
						ON	ISNULL(cwts_62_checkValidity.cwtStatusId, SCR_Warehouse.fnInvalidCWTStatusCode(CWT.cwtFlag62)) = cwts_62.cwtStatusId
		

		--Update CWTStatus descriptions
		UPDATE		CWT
		SET			DominantCWTStatusdesc					=	stat_Dom.cwtStatus
					,CWTStatusDesc2WW						=	stat_2WW.cwtStatus
					,CWTStatusDesc28						=	stat_28.cwtStatus
					,CWTStatusDesc31						=	stat_31.cwtStatus
					,CWTStatusDesc62						=	stat_62.cwtStatus
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	LocalConfig.ReportingCwtStatus stat_Dom
						ON	CWT.DominantCWTStatusCode	=	stat_Dom.cwtStatusId
						AND stat_Dom.IsDeleted = 0
		LEFT JOIN	LocalConfig.ReportingCwtStatus stat_2WW
						ON	CWT.CWTStatusCode2WW	=	stat_2WW.cwtStatusId
						AND stat_2WW.IsDeleted = 0
		LEFT JOIN	LocalConfig.ReportingCwtStatus stat_28
						ON	CWT.CWTStatusCode28	=	stat_28.cwtStatusId
						AND stat_28.IsDeleted = 0
		LEFT JOIN	LocalConfig.ReportingCwtStatus stat_31
						ON	CWT.CWTStatusCode31	=	stat_31.cwtStatusId
						AND stat_31.IsDeleted = 0
		LEFT JOIN	LocalConfig.ReportingCwtStatus stat_62
						ON	CWT.CWTStatusCode62	=	stat_62.cwtStatusId
						AND stat_62.IsDeleted = 0
	
		
		--Update Pathway Indicator (bracket item on PTL)
		UPDATE		CWT
		SET			Pathway						=	ISNULL(ctype62.cwtTypeDesc, ctype2WW.cwtTypeDesc)	--
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	Lookup.cwtTypes ctype2WW
						ON	CWT.cwtType2WW = ctype2WW.cwtTypeID
		LEFT JOIN	Lookup.cwtTypes ctype62
						ON	CWT.cwtType62 = ctype62.cwtTypeID

		--Update Reporting Pathway Length
		UPDATE		CWT
		SET			ReportingPathwayLength		=	CASE	WHEN	CWT.cwtFlag2WW = 1
													THEN	ISNULL(CWT.WillBeWaitingtime2WW, CWT.Waitingtime2WW)
													ELSE	CWT.Waitingtime62
													END 
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
	
	
		-- Keep a record of when the CWT Status and Pathway update finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'CWT Status and pathway update'				

/************************************************************************************************************************************************************************************************************
-- Nullify data items that are not applicable to the cwtFlags
************************************************************************************************************************************************************************************************************/

-- i.e. TargetDate62Days if cwtFlag62 = 4
-- should we do this where the cwtFlag = 0?

--NB The following are nullified in the subsequent PTL - these should be nullified where cwtFlag62 = 4
--TreatmentCode --TreatmentSettingCode -- TargetDate62Days -- DaysTo62DayBreach -- WaitingTimeRefTreatment -- DaysTo62DayBreachNoDTT -- Treated62Days -- Treated7Days62Days -- ActualWaitDTTTreatment
-- not sure why ActualWaitDTTTreatment is nullified???

		---- Nullify fields where the 62 day flag is not applicable
		--UPDATE		CWT
		--SET			Waitingtime62			=	NULL
		--			,TargetDate62			=	NULL
		--			,DaysTo62DayBreach		=	NULL
		--			,DaysTo62DayBreachNoDTT	=	NULL
		--			,Breach62				=	NULL
		--FROM		SCR_Warehouse.SCR_CWT_work CWT
		--WHERE		CWT.cwtFlag62 = 4

		---- Nullify fields where the 62 day flag is closed
		--UPDATE		CWT
		--SET			Waitingtime62 = NULL
		--			,Breach62 = NULL
		--FROM		SCR_Warehouse.SCR_CWT_work CWT
		--WHERE		CWT.cwtFlag62 = 0


/************************************************************************************************************************************************************************************************************
-- Create the comments / tracking notes dataset
************************************************************************************************************************************************************************************************************/


		-- Keep a record of when the comments / tracking notes dataset started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'comments / tracking notes dataset'
				
		declare @commenttypeID_PTL int = (Select commenttypeID from lookup.commentTypes where commentTypeDesc = 'PTL / Tracking')
		declare @commenttypeID_MDT int = (Select commenttypeID from lookup.commentTypes where commentTypeDesc = 'MDT')
		declare @commenttypeID_Treat int = (Select commenttypeID from lookup.commentTypes where commentTypeDesc = 'Treatment')

		-- DROP table of comments if it exists
		if object_ID('SCR_Warehouse.SCR_Comments_work') is not null 
		   DROP TABLE SCR_Warehouse.SCR_Comments_work
		 
		-- Creates the table of comments
		CREATE TABLE SCR_Warehouse.SCR_Comments_work (
					SourceRecordId varchar(255) NOT NULL
					,SourceTableName varchar(255) NOT NULL
					,SourceColumnName varchar(255) NOT NULL
					,CARE_ID int NOT NULL
					,Comment varchar(MAX) NULL
					,CommentUser varchar(50) NULL
					,CommentDate datetime NULL
					,CommentType int NULL
					,CareIdIx int NULL
					,CareIdRevIx int NULL
					,CommentTypeCareIdIx int NULL
					,CommentTypeCareIdRevIx int NULL
					-- Provenance
					,ReportDate datetime NULL								-- The runtime date when the last reporting data update was performed
					)

		-- Insert tracking comments to the table of comments
		INSERT INTO	SCR_Warehouse.SCR_Comments_work (
					SourceRecordId
					,SourceTableName
					,SourceColumnName
					,CARE_ID
					,Comment
					,CommentUser
					,CommentDate
					,CommentType
					,ReportDate
					)
		SELECT		SourceRecordId		=	tc.COM_ID
					,SourceTableName	=	'tblTRACKING_COMMENTS'
					,SourceColumnName	=	'COMMENTS'
					,CARE_ID			=	tc.CARE_ID
					,Comment			=	tc.COMMENTS
					,CommentUser		=	userprofile.FULL_NAME + ' {.' + users.LoweredUserName + '.}'
					,CommentDate		=	tc.DATE_TIME
					,CommentType		=	@commenttypeID_PTL
					,ReportDate			=	@ReportDate

		FROM		LocalConfig.tblTRACKING_COMMENTS tc
		LEFT JOIN	#Incremental Inc
						ON	tc.CARE_ID = Inc.CARE_ID
		LEFT JOIN	LocalConfig.aspnet_Users users
						ON	LOWER(tc.USER_ID) = users.LoweredUserName
		LEFT JOIN	LocalConfig.tblUSER_PROFILE userprofile
						ON	users.UserId = userprofile.USER_ID
		WHERE		Inc.CARE_ID IS NOT NULL			-- The record is in the incremental dataset
		OR			tc.CARE_ID IS NULL				-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0			-- We are doing a bulk load (in which case we should ignore the incremental dataset)


		-- Insert mdt discussion comments to the table of comments
		INSERT INTO	SCR_Warehouse.SCR_Comments_work (
					SourceRecordId
					,SourceTableName
					,SourceColumnName
					,CARE_ID
					,Comment
					,CommentUser
					,CommentDate
					,CommentType
					,ReportDate
					)
		SELECT		SourceRecordId		=	mcp.PLAN_ID
					,SourceTableName	=	'tblMAIN_CARE_PLAN'
					,SourceColumnName	=	'L_MDT_COMMENTS'
					,CARE_ID			=	mcp.CARE_ID
					,Comment			=	cast(mcp.L_MDT_COMMENTS as varchar (max))
					,CommentUser		=	userprofile.FULL_NAME + ' {.' + users.LoweredUserName + '.}'
					,CommentDate		=	AU.ACTION_DATE
					,CommentType		=	@commenttypeID_MDT
					,ReportDate			=	@ReportDate
		FROM		LocalConfig.tblMAIN_CARE_PLAN mcp
		LEFT JOIN	LocalConfig.tblAUDIT AU 
						ON	MCP.ACTION_ID = AU.ACTION_ID -- link Action ID to Audit table to update Comment user
		LEFT JOIN	#Incremental Inc
						ON	mcp.CARE_ID = Inc.CARE_ID
		LEFT JOIN	LocalConfig.aspnet_Users users
						ON	LOWER(AU.USER_ID) = users.LoweredUserName
		LEFT JOIN	LocalConfig.tblUSER_PROFILE userprofile
						ON	users.UserId = userprofile.USER_ID
		WHERE		ISNULL(cast(mcp.L_MDT_COMMENTS as varchar (max)),'') != ''
		AND			(Inc.CARE_ID IS NOT NULL			-- The record is in the incremental dataset
		OR			mcp.CARE_ID IS NULL			-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0			-- We are doing a bulk load (in which case we should ignore the incremental dataset)
					)


	-- Insert "not discussed at MDT comments" to the table of comments
		INSERT INTO	SCR_Warehouse.SCR_Comments_work (
					SourceRecordId
					,SourceTableName
					,SourceColumnName
					,CARE_ID
					,Comment
					,CommentUser
					,CommentDate
					,CommentType
					,ReportDate
					)
		SELECT		SourceRecordId		=	mcp.PLAN_ID
					,SourceTableName	=	'tblMAIN_CARE_PLAN'
					,SourceColumnName	=	'R_NOT_DISCUSSED_COMMENTS'
					,CARE_ID			=	mcp.CARE_ID
					,Comment			=	cast(mcp.R_NOT_DISCUSSED_COMMENTS as varchar (max))
					,CommentUser		=	userprofile.FULL_NAME + ' {.' + users.LoweredUserName + '.}'
					,CommentDate		=	AU.ACTION_DATE
					,CommentType		=	@commenttypeID_MDT
					,ReportDate			=	@ReportDate
		FROM		LocalConfig.tblMAIN_CARE_PLAN mcp
		LEFT JOIN	LocalConfig.tblAUDIT AU
						ON	MCP.ACTION_ID = AU.ACTION_ID
		LEFT JOIN	#Incremental Inc
						ON	mcp.CARE_ID = Inc.CARE_ID
		LEFT JOIN	LocalConfig.aspnet_Users users
						ON	LOWER(AU.USER_ID) = users.LoweredUserName
		LEFT JOIN	LocalConfig.tblUSER_PROFILE userprofile
						ON	users.UserId = userprofile.USER_ID
		WHERE		ISNULL(cast(mcp.R_NOT_DISCUSSED_COMMENTS as varchar (max)),'') != ''
		AND			(Inc.CARE_ID IS NOT NULL			-- The record is in the incremental dataset
		OR			mcp.CARE_ID IS NULL			-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0			-- We are doing a bulk load (in which case we should ignore the incremental dataset)
					)

		-- Inserts row number per Care ID
		UPDATE		SCR_Warehouse.SCR_Comments_work
		SET			CareIdIx				=	IX.CareIdIx
					,CareIdRevIx 			=	IX.CareIdRevIx 			
					,CommentTypeCareIdIx 	=	IX.CommentTypeCareIdIx 	
					,CommentTypeCareIdRevIx	=	IX.CommentTypeCareIdRevIx
		FROM	    SCR_Warehouse.SCR_Comments_work SCR
		INNER JOIN
					(SELECT		SourceRecordId
								,SourceTableName
								,SourceColumnName
								,CareIdIx				=	ROW_NUMBER() OVER (PARTITION BY CARE_ID ORDER BY CommentDate ASC ) 
								,CareIdRevIx 			=	ROW_NUMBER() OVER (PARTITION BY CARE_ID ORDER BY CommentDate DESC )
								,CommentTypeCareIdIx 	=	ROW_NUMBER() OVER (PARTITION BY CARE_ID,COMMENTTYPE ORDER BY CommentDate ASC ) 
								,CommentTypeCareIdRevIx	=	ROW_NUMBER() OVER (PARTITION BY CARE_ID,COMMENTTYPE ORDER BY CommentDate DESC )
					FROM		SCR_Warehouse.SCR_Comments_work) IX
						ON SCR.SourceRecordId		=	IX.SourceRecordId 
							AND SCR.SourceTableName	=	IX.SourceTableName
							AND SCR.SourceColumnName	=	IX.SourceColumnName

 		-- Keep a record of when the comments / tracking notes finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'comments / tracking notes dataset'
				
           
/************************************************************************************************************************************************************************************************************
-- Update SCR_Referrals_work with TrackingDates
************************************************************************************************************************************************************************************************************/				
 	
		-- Keep a record of when the last tracking date for SCR Referrals update started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'latest tracking date for SCR Referrals update'
	
		-- Update SCR Referrals Work with date of most recent next action or tracking updates.  Update both sequentially
		UPDATE		Referrals
		SET			DateLastTracked		=	COALESCE(	CASE	WHEN comm.CommentDate > lna.MaxUpdate	--clock starts if tracking note added after next action added
																THEN comm.CommentDate
																ELSE lna.MaxUpdate						--else uses when last Next Action added after trackingnote (or tracking note or action is null)
																END
																,comm.CommentDate						--else date last tracked
																,CASE	WHEN CWT.DeftDefinitiveTreatment = 1
																		THEN CWT.ClockStartDate62		--else when 62day clock starts
																		ELSE CWT.ClockStartDate31		
																END
																,Referrals.DateReceipt						--else days since last referred
																) 
		
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals	
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	Referrals.CARE_ID = CWT.CARE_ID
		LEFT JOIN	SCR_Warehouse.SCR_Comments comm--_work comm
						ON	Referrals.CARE_ID = comm.CARE_ID
						AND	comm.CommentType = 1 -- Tracking Notes
						AND	comm.CommentTypeCareIdRevIx = 1 -- the most recent tracking note
		LEFT JOIN	(SELECT 
						CareID
						,MAX(LastUpdated) AS MaxUpdate
						FROM SCR_Warehouse.SCR_NextActions
						WHERE ActionComplete = 0						
						GROUP BY 
						CareID) lna
						ON	Referrals.CARE_ID = lna.CareID				

		-- Update SCR Referrals Work with days since date of most recent next action or tracking updates.  Update both sequentially
		UPDATE		Referrals
		Set			DaysSinceLastTracked	=	DATEDIFF(d,Referrals.DateLastTracked, Referrals.ReportDate) 		
		FROM		SCR_Warehouse.SCR_Referrals_work Referrals							


		-- Keep a record of when the last tracking date for SCR Referrals update finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'latest tracking date for SCR Referrals update'


/************************************************************************************************************************************************************************************************************
-- Create the IPT dataset
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the IPT dataset started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'IPT dataset'
				
		-- DROP SCR_InterProviderTransfersWork table if it exists
		if object_ID('SCR_Warehouse.SCR_InterProviderTransfers_Work') is not null 
			DROP TABLE SCR_Warehouse.SCR_InterProviderTransfers_Work

		CREATE TABLE SCR_Warehouse.SCR_InterProviderTransfers_Work(
				TertiaryReferralID int NOT NULL,
				CareID int NULL,
				ACTION_ID int NULL,
				IPTTypeCode int NULL,
				IPTTypeDesc varchar(100) NULL,
				IPTDate datetime NULL,
				IPTReferralReasonCode int NULL,
				IPTReferralReasonDesc varchar(100) NULL,
				IPTReceiptReasonCode int NULL,
				IPTReceiptReasonDesc varchar(100) NULL,
				ReferringOrgID int NULL,
				ReferringOrgCode varchar(5) NULL,
				ReferringOrgName varchar(100) NULL,					
				TertiaryReferralOutComments varchar(max) NULL,		
				ReceivingOrgID int NULL,
				ReceivingOrgCode varchar(5) NULL,
				ReceivingOrgName varchar(100) NULL,				
				--DateReceived datetime NULL,
				--DateReturned datetime NULL,
				--ReceivingReasonID int NULL,
				--ReceivingReason varchar(100) NULL,
				TertiaryReferralInComments varchar(max) NULL,
				--ReasonDatesDifferent varchar(200) NULL,
				--RootCauseSentComments text NULL,
				--RootCauseReceivedComments text NULL,
				--RootCauseReturnedComments text NULL,	
				IptReasonTypeCareIdIx int NULL,
				LastUpdatedBy varchar(50) NULL
				
				)

		INSERT INTO	SCR_Warehouse.SCR_InterProviderTransfers_Work(
					TertiaryReferralID
					,CareID
					,ReferringOrgID
					,ReceivingOrgID
					,IPTReferralReasonCode
					,TertiaryReferralOutComments
					,ACTION_ID
					,LastUpdatedBy 
					)
		SELECT
					TertiaryReferralID				=		TRef.TertiaryReferralID
					,CareID							=		TRef.CareID			
					,ReferringOrgID					= 		TRef.ReferringOrgID	
					,ReceivingOrgID					= 		TRef.ReceivingOrgID	
					,IPTReasonCode					= 		TRef.ReasonID			
					,TertiaryReferralOutComments	= 		TRef.Comments			
					,ACTION_ID						= 		TRef.ACTION_ID	
					,LastUpdatedBy					=		userprofile.FULL_NAME + ' {.' + users.LoweredUserName + '.}'	
		FROM		 LocalConfig.tblTERTIARY_REFERRALS TRef
		LEFT JOIN	#Incremental Inc
						ON	TRef.CareID = Inc.CARE_ID
		LEFT JOIN	LocalConfig.tblAUDIT AU
						ON	TRef.ACTION_ID = AU.ACTION_ID
		LEFT JOIN	LocalConfig.aspnet_Users users
						ON	LOWER(AU.USER_ID) = users.LoweredUserName
		LEFT JOIN	LocalConfig.tblUSER_PROFILE userprofile
						ON	users.UserId = userprofile.USER_ID

		WHERE		(Inc.CARE_ID IS NOT NULL		-- The record is in the incremental dataset
		OR			TRef.CareID IS NULL				-- We are unable to determine whether the record is in the incremental dataset
		OR			@IncrementalUpdate = 0			-- We are doing a bulk load (in which case we should ignore the incremental dataset)
					)

		/*links to Tertiary Sent table which contains referral out date*/
		UPDATE		IPTW
		SET			IPTDate							=		TSen.DateSent			
		FROM 		SCR_Warehouse.SCR_InterProviderTransfers_Work IPTW
		LEFT JOIN	LocalConfig.tblTERTIARY_REFERRALS_SENT TSen 
						ON  IPTW.TertiaryReferralID = TSen.TertiaryReferralID
	

		/*links to Tertiary Received table which contains referral recieved date and reasons for referral in*/
		UPDATE		IPTW
		SET			IPTDate							=		TRec.DateReceived				
					,TertiaryReferralInComments		=		TRec.ReturnedComments			
					--,RootCauseReceivedComments	=		TRec.RootCauseReceivedComments	
					--,RootCauseReturnedComments	=		TRec.RootCauseReturnedComments
					--,RequestReceivedDate			=		TRec.RequestReceivedDate		
					--,ReasonDatesDifferent			=		TRec.ReasonDatesDifferent		
					,IPTReceiptReasonCode			=		TRec.ReceivingReasonID					
		FROM 		SCR_Warehouse.SCR_InterProviderTransfers_Work IPTW
		LEFT JOIN	LocalConfig.tblTERTIARY_REFERRALS_RECEIVED TRec 
						ON IPTW.TertiaryReferralID = TRec.TertiaryReferralID

		/*links to Referring organisation lookup description*/
		UPDATE		IPTW
		SET			ReferringOrgCode				=		Sites.Code
					,ReferringOrgName 				=		Sites.Description
		FROM 		SCR_Warehouse.SCR_InterProviderTransfers_Work IPTW
		INNER JOIN	LocalConfig.OrganisationSites Sites
						ON	IPTW.ReferringOrgID = Sites.ID

	 
		/*links to Receiving Organisation lookup description*/
		UPDATE		IPTW
		SET			ReceivingOrgCode				=		Sites.Code
					,ReceivingOrgName				=		Sites.Description
		FROM 		SCR_Warehouse.SCR_InterProviderTransfers_Work IPTW
		INNER JOIN	LocalConfig.OrganisationSites Sites
						ON	IPTW.ReceivingOrgID = Sites.ID
	
		/*links to referring reason lookup description*/
		UPDATE		IPTW
		SET			IPTReferralReasonDesc					=		refTR.REASON_DESC
					,IPTReceiptReasonDesc					=		recTR.REASON_DESC
		FROM 		SCR_Warehouse.SCR_InterProviderTransfers_Work IPTW
		LEFT JOIN	LocalConfig.ltblTERTIARY_REASON refTR 
						ON IPTW.IPTReferralReasonCode = refTR.REASON_CODE
		LEFT JOIN	LocalConfig.ltblTERTIARY_REASON recTR 
						ON IPTW.IPTReceiptReasonCode = recTR.REASON_CODE


		/*Updates IPT Type*/
		UPDATE		IPTW
		SET			IPTTypeCode						=		CASE	WHEN LEFT(ReceivingOrgCode,3) = LocalConfig.fnOdsCode() AND LEFT(ReferringOrgCode,3) = LocalConfig.fnOdsCode() THEN 3
																	WHEN LEFT(ReceivingOrgCode,3) = LocalConfig.fnOdsCode() THEN 1
																	WHEN LEFT(ReferringOrgCode,3) = LocalConfig.fnOdsCode() THEN 2														 
																	END
		FROM 		SCR_Warehouse.SCR_InterProviderTransfers_Work IPTW


		/*Updates IPT Type description*/
		UPDATE		IPTW
		SET			IPTTypeDesc						=		LIPT.IPTTypeDesc
		FROM 		SCR_Warehouse.SCR_InterProviderTransfers_Work IPTW
		LEFT JOIN	Lookup.IPTType LIPT 
						ON IPTW.IPTTypeCode = LIPT.IPTTypeID

		-- Update IptReasonTypeCareIdIx
		UPDATE		IPTW
		SET			IptReasonTypeCareIdIx			=		ISNULL(IPTW_Ix.IptReasonTypeCareIdIx, 0)
		FROM 		SCR_Warehouse.SCR_InterProviderTransfers_work IPTW
		LEFT JOIN	(SELECT		TertiaryReferralID
								,ROW_NUMBER() OVER (PARTITION BY CareId, IPTTypeCode, CASE WHEN IPTReferralReasonCode = 9 OR IPTReceiptReasonCode = 9 THEN 1 ELSE 0 END ORDER BY IPTDate DESC) AS IptReasonTypeCareIdIx
					FROM		SCR_Warehouse.SCR_InterProviderTransfers_work
					WHERE		IPTTypeCode = 1 -- Inbound
					AND			(IPTReferralReasonCode = 9 -- Primary Treatment (referral)
					OR			IPTReceiptReasonCode = 9) -- Primary Treatment (receipt)
					) IPTW_Ix
						ON IPTW.TertiaryReferralID = IPTW_Ix.TertiaryReferralID
					
		-- Keep a record of when the IPT dataset finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'IPT dataset'
				

/************************************************************************************************************************************************************************************************************
-- Create the OpenTargetDates_work table
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the OpenTargetDates_work dataset started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'OpenTargetDates_work dataset'
				
		-- Create a table that orders the target dates so we can find the next target
		IF OBJECT_ID('SCR_Warehouse.OpenTargetDates_work') IS NOT NULL
			DROP TABLE SCR_Warehouse.OpenTargetDates_work
					
		CREATE TABLE SCR_Warehouse.OpenTargetDates_work (
					OpenTargetDatesId int NOT NULL IDENTITY(1,1)
					,CARE_ID int NOT NULL
					,CWT_ID varchar(255) NOT NULL
					,DaysToTarget int
					,TargetDate datetime
					,DaysToBreach int
					,BreachDate datetime
					,TargetType varchar(255)
					,WaitTargetGroupDesc varchar(255)
					,WaitTargetPriority int
					,ReportDate datetime
					-- Target Dates
					,IxFirstOpenTargetDate int
					,IxLastOpenTargetDate int
					,IxNextFutureOpenTargetDate int
					,IxLastFutureOpenTargetDate int
					,IxFirstOpenGroupTargetDate int
					,IxLastOpenGroupTargetDate int
					,IxNextFutureOpenGroupTargetDate int
					,IxLastFutureOpenGroupTargetDate int
					-- Breach Dates
					,IxFirstOpenBreachDate int
					,IxLastOpenBreachDate int
					,IxNextFutureOpenBreachDate int
					,IxLastFutureOpenBreachDate int
					,IxFirstOpenGroupBreachDate int
					,IxLastOpenGroupBreachDate int
					,IxNextFutureOpenGroupBreachDate int
					,IxLastFutureOpenGroupBreachDate int
					)
				
		-- Create a Primary Key for OpenTargetDates_work
		ALTER TABLE SCR_Warehouse.OpenTargetDates_work 
		ADD CONSTRAINT PK_OpenTargetDates_work PRIMARY KEY (
				OpenTargetDatesId ASC
				)

		-- Create an Index for CWT_ID in OpenTargetDates_work
		CREATE NONCLUSTERED INDEX Ix_CWT_ID_Work ON SCR_Warehouse.OpenTargetDates_work (
				CWT_ID ASC
				)

		-- Create an Index for CARE_ID in OpenTargetDates_work
		CREATE NONCLUSTERED INDEX Ix_CARE_ID_Work ON SCR_Warehouse.OpenTargetDates_work (
				CARE_ID ASC
				)
		
		-- Insert 2WW targets
		INSERT INTO SCR_Warehouse.OpenTargetDates_work (
					CWT_ID
					,CARE_ID
					,DaysToTarget
					,TargetDate
					,DaysToBreach
					,BreachDate
					,TargetType
					,WaitTargetGroupDesc
					,WaitTargetPriority
					,ReportDate
					)
		SELECT		CWT.CWT_ID
					,CWT.CARE_ID
					,CWT.DaysTo2WWBreach
					,CWT.TargetDate2WW
					,CWT.DaysTo2WWBreach + 1
					,DATEADD(dd, 1, CWT.TargetDate2WW)
					,wt.WaitTargetDesc
					,wtg.WaitTargetGroupDesc
					,wt.WaitTargetPriority
					,CWT.ReportDate
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		LEFT JOIN	Lookup.cwtTypes cwtTypes
						ON	CWT.cwtType2WW = cwtTypes.cwtTypeID
		LEFT JOIN	Lookup.WaitTargets wt
						ON	cwtTypes.cwtStandard_WaitTargetId = wt.WaitTargetId
		LEFT JOIN	lookup.WaitTargetGroups wtg
						ON	wt.WaitTargetGroupId = wtg.WaitTargetGroupId
		LEFT JOIN	lookup.WaitTargetsOpenCwtMapping wtocm
						ON	wt.WaitTargetId = wtocm.WaitTargetId
		WHERE		(CWT.cwtFlag2WW & 1) = 1		-- 2WW flag is open
		AND			wtocm.cwtStandardId = 1			-- The wait target maps to an open 2WW pathway

		-- Insert 28 day targets
		INSERT INTO SCR_Warehouse.OpenTargetDates_work (
					CWT_ID
					,CARE_ID
					,DaysToTarget
					,TargetDate
					,DaysToBreach
					,BreachDate
					,TargetType
					,WaitTargetGroupDesc
					,WaitTargetPriority
					,ReportDate
					)
		SELECT		CWT.CWT_ID
					,CWT.CARE_ID
					,CWT.DaysTo28DayBreach
					,CWT.TargetDate28
					,CWT.DaysTo28DayBreach + 1
					,DATEADD(dd, 1, CWT.TargetDate28)
					,wt.WaitTargetDesc
					,wtg.WaitTargetGroupDesc
					,wt.WaitTargetPriority
					,CWT.ReportDate
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		LEFT JOIN	Lookup.cwtTypes cwtTypes
						ON	CWT.cwtType28 = cwtTypes.cwtTypeID
		LEFT JOIN	Lookup.WaitTargets wt
						ON	cwtTypes.cwtStandard_WaitTargetId = wt.WaitTargetId
		LEFT JOIN	lookup.WaitTargetGroups wtg
						ON	wt.WaitTargetGroupId = wtg.WaitTargetGroupId
		LEFT JOIN	lookup.WaitTargetsOpenCwtMapping wtocm
						ON	wt.WaitTargetId = wtocm.WaitTargetId
		WHERE		(CWT.cwtFlag28 & 1) = 1			-- 28 day / FDS flag is open
		AND			wtocm.cwtStandardId = 2			-- The wait target maps to an open 28 day / FDS pathway

		-- Insert 31 day targets
		INSERT INTO SCR_Warehouse.OpenTargetDates_work (
					CWT_ID
					,CARE_ID
					,DaysToTarget
					,TargetDate
					,DaysToBreach
					,BreachDate
					,TargetType
					,WaitTargetGroupDesc
					,WaitTargetPriority
					,ReportDate
					)
		SELECT		CWT.CWT_ID
					,CWT.CARE_ID
					,CWT.DaysTo31DayBreach
					,CWT.TargetDate31
					,CWT.DaysTo31DayBreach + 1
					,DATEADD(d, 1, CWT.TargetDate31)
					,wt.WaitTargetDesc
					,wtg.WaitTargetGroupDesc
					,wt.WaitTargetPriority
					,CWT.ReportDate
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		LEFT JOIN	Lookup.cwtTypes cwtTypes
						ON	CWT.cwtType31 = cwtTypes.cwtTypeID
		LEFT JOIN	Lookup.WaitTargets wt
						ON	cwtTypes.cwtStandard_WaitTargetId = wt.WaitTargetId
		LEFT JOIN	lookup.WaitTargetGroups wtg
						ON	wt.WaitTargetGroupId = wtg.WaitTargetGroupId
		LEFT JOIN	lookup.WaitTargetsOpenCwtMapping wtocm
						ON	wt.WaitTargetId = wtocm.WaitTargetId
		WHERE		(CWT.cwtFlag31 & 1) = 1			-- 31 day flag is open
		AND			wtocm.cwtStandardId = 3			-- The wait target maps to an open 31 day pathway

		-- Insert 62 day targets (inc 31 Day Rare)
		INSERT INTO SCR_Warehouse.OpenTargetDates_work (
					CWT_ID
					,CARE_ID
					,DaysToTarget
					,TargetDate
					,DaysToBreach
					,BreachDate
					,TargetType
					,WaitTargetGroupDesc
					,WaitTargetPriority
					,ReportDate
					)
		SELECT		CWT.CWT_ID
					,CWT.CARE_ID
					,CWT.DaysTo62DayBreach
					,CWT.TargetDate62
					,CWT.DaysTo62DayBreach + 1
					,DATEADD(dd, 1, CWT.TargetDate62)
					,wt.WaitTargetDesc
					,wtg.WaitTargetGroupDesc
					,wt.WaitTargetPriority
					,CWT.ReportDate
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		LEFT JOIN	Lookup.cwtTypes cwtTypes
						ON	CWT.cwtType62 = cwtTypes.cwtTypeID
		LEFT JOIN	Lookup.WaitTargets wt
						ON	cwtTypes.cwtStandard_WaitTargetId = wt.WaitTargetId
		LEFT JOIN	lookup.WaitTargetGroups wtg
						ON	wt.WaitTargetGroupId = wtg.WaitTargetGroupId
		LEFT JOIN	lookup.WaitTargetsOpenCwtMapping wtocm
						ON	wt.WaitTargetId = wtocm.WaitTargetId
		WHERE		(CWT.cwtFlag62 & 1) = 1			-- 62 day flag is open
		AND			wtocm.cwtStandardId = 4			-- The wait target maps to an open 62 day pathway

		-- Targets not derived from the relationship between cwtTypes and WaitTargets: Insert IPT+24
		INSERT INTO SCR_Warehouse.OpenTargetDates_work (
					CWT_ID
					,CARE_ID
					,DaysToTarget
					,TargetDate
					,DaysToBreach
					,BreachDate
					,TargetType
					,WaitTargetGroupDesc
					,WaitTargetPriority
					,ReportDate
					)
		SELECT		CWT.CWT_ID
					,CWT.CARE_ID
					,DATEDIFF(dd, CWT.ReportDate, DATEADD(dd, wt.WaitTargetDays, ipt.IPTDate))
					,DATEADD(dd, wt.WaitTargetDays, ipt.IPTDate)
					,DATEDIFF(dd, CWT.ReportDate, DATEADD(dd, wt.WaitTargetDays + 1, ipt.IPTDate))
					,DATEADD(dd, wt.WaitTargetDays + 1, ipt.IPTDate)
					,wt.WaitTargetDesc
					,wtg.WaitTargetGroupDesc
					,wt.WaitTargetPriority
					,CWT.ReportDate
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		INNER JOIN	SCR_Warehouse.SCR_InterProviderTransfers_Work ipt
						ON	CWT.CARE_ID = ipt.CareID
						AND	ipt.IptReasonTypeCareIdIx = 1
		LEFT JOIN	Lookup.cwtTypes cwtTypes2WW
						ON	CWT.cwtType2WW = cwtTypes2WW.cwtTypeID
		LEFT JOIN	Lookup.cwtTypes cwtTypes28
						ON	CWT.cwtType28 = cwtTypes28.cwtTypeID
		LEFT JOIN	Lookup.cwtTypes cwtTypes31
						ON	CWT.cwtType31 = cwtTypes31.cwtTypeID
		LEFT JOIN	Lookup.cwtTypes cwtTypes62
						ON	CWT.cwtType62 = cwtTypes62.cwtTypeID
		CROSS JOIN	Lookup.WaitTargets wt
		LEFT JOIN	lookup.WaitTargetGroups wtg
						ON	wt.WaitTargetGroupId = wtg.WaitTargetGroupId
		LEFT JOIN	lookup.WaitTargetsOpenCwtMapping wtocm
						ON	wt.WaitTargetId = wtocm.WaitTargetId
		WHERE		(	
						(	(CWT.cwtFlag2WW & 1) = 1									-- The 2WW flag is open
						AND	cwtTypes2WW.cwtStandardId = wtocm.cwtStandardId				-- and the 2WW cwtType cwtStandardId maps to WaitTarget cwtStandardId
						AND	cwtTypes2WW.cwtStandard_WaitTargetId != wt.WaitTargetId)	-- and there is no direct relationship between the cwtType and the WaitTarget
					OR	(	(CWT.cwtFlag28 & 1) = 1										-- Or the 28 day flag is open
						AND	cwtTypes28.cwtStandardId = wtocm.cwtStandardId				-- and the 28 day cwtType cwtStandardId maps to WaitTarget cwtStandardId
						AND	cwtTypes28.cwtStandard_WaitTargetId != wt.WaitTargetId)		-- and there is no direct relationship between the cwtType and the WaitTarget
					OR	(	(CWT.cwtFlag31 & 1) = 1										-- Or the 31 day flag is open
						AND	cwtTypes31.cwtStandardId = wtocm.cwtStandardId				-- and the 31 day cwtType cwtStandardId maps to WaitTarget cwtStandardId
						AND	cwtTypes31.cwtStandard_WaitTargetId != wt.WaitTargetId)		-- and there is no direct relationship between the cwtType and the WaitTarget
					OR	(	(CWT.cwtFlag62 & 1) = 1										-- Or the 62 day flag is open
						AND	cwtTypes62.cwtStandardId = wtocm.cwtStandardId				-- and the 62 day cwtType cwtStandardId maps to WaitTarget cwtStandardId
						AND	cwtTypes62.cwtStandard_WaitTargetId != wt.WaitTargetId)		-- and there is no direct relationship between the cwtType and the WaitTarget
					)
		AND			wt.WaitTargetId = 6											-- IPT+24 target
		AND			DATEADD(dd, wt.WaitTargetDays + 1, ipt.IPTDate) > DATEADD(dd, 1, CWT.TargetDate62)    -- target will only show if breach date greater than 62 day breach

		-- Targets not derived from the relationship between cwtTypes and WaitTargets: Insert 104 Day
		INSERT INTO SCR_Warehouse.OpenTargetDates_work (
					CWT_ID
					,CARE_ID
					,DaysToTarget
					,TargetDate
					,DaysToBreach
					,BreachDate
					,TargetType
					,WaitTargetGroupDesc
					,WaitTargetPriority
					,ReportDate
					)
		SELECT		CWT.CWT_ID
					,CWT.CARE_ID
					,CASE	WHEN cwtTypes2WW.cwtStandardId = wtocm.cwtStandardId
							THEN DATEDIFF(dd, CWT.ReportDate, DATEADD(dd, wt.WaitTargetDays + CWT.AdjTime2WW, CWT.ClockStartDate2WW))
							WHEN cwtTypes28.cwtStandardId = wtocm.cwtStandardId
							THEN DATEDIFF(dd, CWT.ReportDate, DATEADD(dd, wt.WaitTargetDays + CWT.AdjTime28, CWT.ClockStartDate28))
							WHEN cwtTypes31.cwtStandardId = wtocm.cwtStandardId
							THEN DATEDIFF(dd, CWT.ReportDate, DATEADD(dd, wt.WaitTargetDays + CWT.AdjTime31, CWT.ClockStartDate31))
							WHEN cwtTypes62.cwtStandardId = wtocm.cwtStandardId
							THEN DATEDIFF(dd, CWT.ReportDate, DATEADD(dd, wt.WaitTargetDays + CWT.AdjTime62, CWT.ClockStartDate62))
							END
					,CASE	WHEN cwtTypes2WW.cwtStandardId = wtocm.cwtStandardId
							THEN DATEADD(dd, wt.WaitTargetDays + CWT.AdjTime2WW, CWT.ClockStartDate2WW)
							WHEN cwtTypes28.cwtStandardId = wtocm.cwtStandardId
							THEN DATEADD(dd, wt.WaitTargetDays + CWT.AdjTime28, CWT.ClockStartDate28)
							WHEN cwtTypes31.cwtStandardId = wtocm.cwtStandardId
							THEN DATEADD(dd, wt.WaitTargetDays + CWT.AdjTime31, CWT.ClockStartDate31)
							WHEN cwtTypes62.cwtStandardId = wtocm.cwtStandardId
							THEN DATEADD(dd, wt.WaitTargetDays + CWT.AdjTime62, CWT.ClockStartDate62)
							END
					,CASE	WHEN cwtTypes2WW.cwtStandardId = wtocm.cwtStandardId
							THEN DATEDIFF(dd, CWT.ReportDate, DATEADD(dd, wt.WaitTargetDays + 1 + CWT.AdjTime2WW, CWT.ClockStartDate2WW))
							WHEN cwtTypes28.cwtStandardId = wtocm.cwtStandardId
							THEN DATEDIFF(dd, CWT.ReportDate, DATEADD(dd, wt.WaitTargetDays + 1 + CWT.AdjTime28, CWT.ClockStartDate28))
							WHEN cwtTypes31.cwtStandardId = wtocm.cwtStandardId
							THEN DATEDIFF(dd, CWT.ReportDate, DATEADD(dd, wt.WaitTargetDays + 1 + CWT.AdjTime31, CWT.ClockStartDate31))
							WHEN cwtTypes62.cwtStandardId = wtocm.cwtStandardId
							THEN DATEDIFF(dd, CWT.ReportDate, DATEADD(dd, wt.WaitTargetDays + 1 + CWT.AdjTime62, CWT.ClockStartDate62))
							END
					,CASE	WHEN cwtTypes2WW.cwtStandardId = wtocm.cwtStandardId
							THEN DATEADD(dd, wt.WaitTargetDays + 1 + CWT.AdjTime2WW, CWT.ClockStartDate2WW)
							WHEN cwtTypes28.cwtStandardId = wtocm.cwtStandardId
							THEN DATEADD(dd, wt.WaitTargetDays + 1 + CWT.AdjTime28, CWT.ClockStartDate28)
							WHEN cwtTypes31.cwtStandardId = wtocm.cwtStandardId
							THEN DATEADD(dd, wt.WaitTargetDays + 1 + CWT.AdjTime31, CWT.ClockStartDate31)
							WHEN cwtTypes62.cwtStandardId = wtocm.cwtStandardId
							THEN DATEADD(dd, wt.WaitTargetDays + 1 + CWT.AdjTime62, CWT.ClockStartDate62)
							END
					,wt.WaitTargetDesc
					,wtg.WaitTargetGroupDesc
					,wt.WaitTargetPriority
					,CWT.ReportDate
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		LEFT JOIN	Lookup.cwtTypes cwtTypes2WW
						ON	CWT.cwtType2WW = cwtTypes2WW.cwtTypeID
		LEFT JOIN	Lookup.cwtTypes cwtTypes28
						ON	CWT.cwtType28 = cwtTypes28.cwtTypeID
		LEFT JOIN	Lookup.cwtTypes cwtTypes31
						ON	CWT.cwtType31 = cwtTypes31.cwtTypeID
		LEFT JOIN	Lookup.cwtTypes cwtTypes62
						ON	CWT.cwtType62 = cwtTypes62.cwtTypeID
		CROSS JOIN	Lookup.WaitTargets wt
		LEFT JOIN	lookup.WaitTargetGroups wtg
						ON	wt.WaitTargetGroupId = wtg.WaitTargetGroupId
		LEFT JOIN	lookup.WaitTargetsOpenCwtMapping wtocm
						ON	wt.WaitTargetId = wtocm.WaitTargetId
		WHERE		(	
						(	(CWT.cwtFlag2WW & 1) = 1									-- The 2WW flag is open
						AND	cwtTypes2WW.cwtStandardId = wtocm.cwtStandardId				-- and the 2WW cwtType cwtStandardId maps to WaitTarget cwtStandardId
						AND	cwtTypes2WW.cwtStandard_WaitTargetId != wt.WaitTargetId)	-- and there is no direct relationship between the cwtType and the WaitTarget
					OR	(	(CWT.cwtFlag28 & 1) = 1										-- Or the 28 day flag is open
						AND	cwtTypes28.cwtStandardId = wtocm.cwtStandardId				-- and the 28 day cwtType cwtStandardId maps to WaitTarget cwtStandardId
						AND	cwtTypes28.cwtStandard_WaitTargetId != wt.WaitTargetId)		-- and there is no direct relationship between the cwtType and the WaitTarget
					OR	(	(CWT.cwtFlag31 & 1) = 1										-- Or the 31 day flag is open
						AND	cwtTypes31.cwtStandardId = wtocm.cwtStandardId				-- and the 31 day cwtType cwtStandardId maps to WaitTarget cwtStandardId
						AND	cwtTypes31.cwtStandard_WaitTargetId != wt.WaitTargetId)		-- and there is no direct relationship between the cwtType and the WaitTarget
					OR	(	(CWT.cwtFlag62 & 1) = 1										-- Or the 62 day flag is open
						AND	cwtTypes62.cwtStandardId = wtocm.cwtStandardId				-- and the 62 day cwtType cwtStandardId maps to WaitTarget cwtStandardId
						AND	cwtTypes62.cwtStandard_WaitTargetId != wt.WaitTargetId)		-- and there is no direct relationship between the cwtType and the WaitTarget
					)
		AND			wt.WaitTargetId = 7											-- 104 day target
		AND			cwt.Waitingtime62 >62										-- target will only show if already breached 62 days

		-- Update the Ix numbers in the OpenTargetDates table
		UPDATE		SCR_Warehouse.OpenTargetDates_work
		SET			-- Target Dates
					IxFirstOpenTargetDate				=	OTDrn.IxFirstOpenTargetDate
					,IxLastOpenTargetDate				=	OTDrn.IxLastOpenTargetDate
					,IxNextFutureOpenTargetDate			=	OTDrn.IxNextFutureOpenTargetDate
					,IxLastFutureOpenTargetDate			=	OTDrn.IxLastFutureOpenTargetDate
					,IxFirstOpenGroupTargetDate			=	OTDrn.IxFirstOpenGroupTargetDate		
					,IxLastOpenGroupTargetDate			=	OTDrn.IxLastOpenGroupTargetDate		
					,IxNextFutureOpenGroupTargetDate	=	OTDrn.IxNextFutureOpenGroupTargetDate
					,IxLastFutureOpenGroupTargetDate	=	OTDrn.IxLastFutureOpenGroupTargetDate
					-- Breach Dates
					,IxFirstOpenBreachDate				=	OTDrn.IxFirstOpenBreachDate
					,IxLastOpenBreachDate				=	OTDrn.IxLastOpenBreachDate
					,IxNextFutureOpenBreachDate			=	OTDrn.IxNextFutureOpenBreachDate
					,IxLastFutureOpenBreachDate			=	OTDrn.IxLastFutureOpenBreachDate
					,IxFirstOpenGroupBreachDate			=	OTDrn.IxFirstOpenGroupBreachDate		
					,IxLastOpenGroupBreachDate			=	OTDrn.IxLastOpenGroupBreachDate		
					,IxNextFutureOpenGroupBreachDate	=	OTDrn.IxNextFutureOpenGroupBreachDate
					,IxLastFutureOpenGroupBreachDate	=	OTDrn.IxLastFutureOpenGroupBreachDate
		FROM		SCR_Warehouse.OpenTargetDates_work OTD
		INNER JOIN	(
					SELECT		OpenTargetDatesId
								-- Target Dates
								,IxFirstOpenTargetDate				=	ROW_NUMBER() OVER (PARTITION BY CWT_ID ORDER BY TargetDate ASC, WaitTargetPriority ASC)
								,IxLastOpenTargetDate				=	ROW_NUMBER() OVER (PARTITION BY CWT_ID ORDER BY TargetDate DESC, WaitTargetPriority ASC)
								,IxNextFutureOpenTargetDate			=	ROW_NUMBER() OVER (PARTITION BY CWT_ID ORDER BY CASE WHEN TargetDate >= ReportDate THEN TargetDate ELSE CAST('31 Dec 2999' AS datetime) END ASC, WaitTargetPriority ASC)
								,IxLastFutureOpenTargetDate			=	ROW_NUMBER() OVER (PARTITION BY CWT_ID ORDER BY CASE WHEN TargetDate >= ReportDate THEN TargetDate ELSE ReportDate END DESC, WaitTargetPriority ASC)
								,IxFirstOpenGroupTargetDate			=	ROW_NUMBER() OVER (PARTITION BY CWT_ID, WaitTargetGroupDesc ORDER BY TargetDate ASC, WaitTargetPriority ASC)
								,IxLastOpenGroupTargetDate			=	ROW_NUMBER() OVER (PARTITION BY CWT_ID, WaitTargetGroupDesc ORDER BY TargetDate DESC, WaitTargetPriority ASC)
								,IxNextFutureOpenGroupTargetDate	=	ROW_NUMBER() OVER (PARTITION BY CWT_ID, WaitTargetGroupDesc ORDER BY CASE WHEN TargetDate >= ReportDate THEN TargetDate ELSE CAST('31 Dec 2999' AS datetime) END ASC, WaitTargetPriority ASC)
								,IxLastFutureOpenGroupTargetDate	=	ROW_NUMBER() OVER (PARTITION BY CWT_ID, WaitTargetGroupDesc ORDER BY CASE WHEN TargetDate >= ReportDate THEN TargetDate ELSE ReportDate END DESC, WaitTargetPriority ASC)
								-- Breach Dates
								,IxFirstOpenBreachDate				=	ROW_NUMBER() OVER (PARTITION BY CWT_ID ORDER BY BreachDate ASC, WaitTargetPriority ASC)
								,IxLastOpenBreachDate				=	ROW_NUMBER() OVER (PARTITION BY CWT_ID ORDER BY BreachDate DESC, WaitTargetPriority ASC)
								,IxNextFutureOpenBreachDate			=	ROW_NUMBER() OVER (PARTITION BY CWT_ID ORDER BY CASE WHEN BreachDate >= ReportDate THEN BreachDate ELSE CAST('31 Dec 2999' AS datetime) END ASC, WaitTargetPriority ASC)
								,IxLastFutureOpenBreachDate			=	ROW_NUMBER() OVER (PARTITION BY CWT_ID ORDER BY CASE WHEN BreachDate >= ReportDate THEN BreachDate ELSE ReportDate END DESC, WaitTargetPriority ASC)
								,IxFirstOpenGroupBreachDate			=	ROW_NUMBER() OVER (PARTITION BY CWT_ID, WaitTargetGroupDesc ORDER BY BreachDate ASC, WaitTargetPriority ASC)
								,IxLastOpenGroupBreachDate			=	ROW_NUMBER() OVER (PARTITION BY CWT_ID, WaitTargetGroupDesc ORDER BY BreachDate DESC, WaitTargetPriority ASC)
								,IxNextFutureOpenGroupBreachDate	=	ROW_NUMBER() OVER (PARTITION BY CWT_ID, WaitTargetGroupDesc ORDER BY CASE WHEN BreachDate >= ReportDate THEN BreachDate ELSE CAST('31 Dec 2999' AS datetime) END ASC, WaitTargetPriority ASC)
								,IxLastFutureOpenGroupBreachDate	=	ROW_NUMBER() OVER (PARTITION BY CWT_ID, WaitTargetGroupDesc ORDER BY CASE WHEN BreachDate >= ReportDate THEN BreachDate ELSE ReportDate END DESC, WaitTargetPriority ASC)
					FROM		SCR_Warehouse.OpenTargetDates_work
					) OTDrn
						ON	OTD.OpenTargetDatesId = OTDrn.OpenTargetDatesId
		
		-- Keep a record of when the OpenTargetDates_work dataset finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'OpenTargetDates_work dataset'

		
/************************************************************************************************************************************************************************************************************
-- Create the Workflow_work table
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the Workflow_work dataset started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'Workflow_work dataset'
				
		-- Create a table that identifies the workflows associated with each pathway
		IF OBJECT_ID('SCR_Warehouse.Workflow_work') IS NOT NULL
			DROP TABLE SCR_Warehouse.Workflow_work
					
		CREATE TABLE SCR_Warehouse.Workflow_work (
					CWT_ID varchar(255) NOT NULL
					,WorkflowID int NOT NULL
					)
				
		-- Create a Primary Key for Workflow_work
		ALTER TABLE SCR_Warehouse.Workflow_work 
		ADD CONSTRAINT PK_Workflow_work PRIMARY KEY (
				CWT_ID ASC
				,WorkflowID ASC
				)
		
		-- Insert 2ww: Undated
		INSERT INTO	SCR_Warehouse.Workflow_work (
					CWT_ID
					,WorkflowID)
		SELECT		CWT.CWT_ID
					,1 as WorkflowID
		FROM		SCR_Warehouse.SCR_Referrals_work Ref 
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	Ref.CARE_ID = CWT.CARE_ID		
		WHERE		CWT.cwtFlag2WW = 1 
		AND			Ref.DateFirstSeen is null 

		-- Insert 2ww: Undated > 5 Days
		INSERT INTO	SCR_Warehouse.Workflow_work (
					CWT_ID
					,WorkflowID)
		SELECT		CWT.CWT_ID
					,2 as WorkflowID
		FROM		SCR_Warehouse.SCR_Referrals_work Ref 
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	Ref.CARE_ID = CWT.CARE_ID		
		WHERE		CWT.cwtFlag2WW = 1 
		AND			Ref.DateFirstSeen is null
		AND			CWT.Waitingtime2WW > 5

		-- Insert 2ww: Pending
		INSERT INTO	SCR_Warehouse.Workflow_work (
					CWT_ID
					,WorkflowID)
		SELECT		CWT.CWT_ID
					,3 as WorkflowID
		FROM		SCR_Warehouse.SCR_Referrals_work Ref 
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	Ref.CARE_ID = CWT.CARE_ID		
		WHERE		CWT.cwtFlag2WW = 1 
		AND			Ref.DateFirstSeen is not null 

		-- Insert 2ww: Pending > 14 Days
		INSERT INTO	SCR_Warehouse.Workflow_work (
					CWT_ID
					,WorkflowID)
		SELECT		CWT.CWT_ID
					,4 as WorkflowID
		FROM		SCR_Warehouse.SCR_Referrals_work Ref 
		LEFT JOIN	SCR_Warehouse.SCR_CWT_work CWT
						ON	Ref.CARE_ID = CWT.CARE_ID		
		WHERE		CWT.cwtFlag2WW = 1 
		AND			Ref.DateFirstSeen is not null
		AND			CWT.WillBeWaitingtime2WW > 14	

		-- Insert 62 Day: > 104 Days
		INSERT INTO	SCR_Warehouse.Workflow_work	(
					CWT_ID
					,WorkflowID)
		SELECT		CWT.CWT_ID
					,5 as WorkflowID
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		WHERE		CWT.cwtFlag62 = 1
		AND			CWT.Waitingtime62 >104	

		-- Insert 62 Day: >= 62 Days
		INSERT INTO	SCR_Warehouse.Workflow_work (
					CWT_ID
					,WorkflowID)
		SELECT		CWT.CWT_ID
					,6 as WorkflowID
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		WHERE		CWT.cwtFlag62 = 1
		AND			CWT.Waitingtime62 > 62

		-- Insert 62 Day: 28-62 Days
		INSERT INTO	SCR_Warehouse.Workflow_work (
					CWT_ID
					,WorkflowID)
		SELECT		CWT.CWT_ID
					,7 as WorkflowID
		FROM		SCR_Warehouse.SCR_CWT_work CWT
		WHERE		CWT.cwtFlag62 = 1
		AND			(Waitingtime62 >=28 AND Waitingtime62 <=62)	

		-- Insert Next Action Date in Past or a NA is Undated
		INSERT INTO	SCR_Warehouse.Workflow_work (
					CWT_ID
					,WorkflowID)
		SELECT		CWT.CWT_ID
					,8 as WorkflowID
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	SCR_Warehouse.SCR_NextActions NA
						ON	CWT.CARE_ID = NA.CareID 
						AND	NA.CareIdIncompleteIx = 1
		WHERE		NA.TargetDate < NA.ReportDate
		OR			(NA.TargetDate IS NULL 
					AND NA.CareID IS NOT NULL)

		-- Insert Next Action Date > 10 days away
		INSERT INTO	SCR_Warehouse.Workflow_work (
					CWT_ID
					,WorkflowID)
		SELECT		CWT.CWT_ID
					,9 as WorkflowID
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	SCR_Warehouse.SCR_NextActions NA
						ON	CWT.CARE_ID = NA.CareID 
						AND	NA.CareIdIncompleteIx = 1
		WHERE		DATEDIFF(dd,NA.ReportDate,NA.TargetDate) >=10

		-- Insert No Next Action
		INSERT INTO	SCR_Warehouse.Workflow_work (
					CWT_ID
					,WorkflowID)
		SELECT		CWT.CWT_ID
					,10 as WorkflowID
		FROM		SCR_Warehouse.SCR_CWT_work CWT 
		LEFT JOIN	SCR_Warehouse.SCR_NextActions NA
						ON	CWT.CARE_ID = NA.CareID 
						AND	NA.CareIdIncompleteIx = 1
		WHERE		NA.CareID IS NULL
		
		-- Insert Ptl Meeting Workflow
		INSERT INTO	SCR_Warehouse.Workflow_work (
					CWT_ID
					,WorkflowID)
		SELECT		wf.CWT_ID
					,11 as WorkflowID
		FROM		SCR_Warehouse.Workflow_work wf
		WHERE		wf.WorkflowID IN (8,9,10)
		GROUP BY	wf.CWT_ID


		-- Keep a record of when the Workflow_work dataset finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'Workflow_work dataset'


/************************************************************************************************************************************************************************************************************
-- Create Primary Keys to make table updates more efficient
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when the efficiency queries started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'efficiency PKs'
				
		-- Create a Primary Key for SCR_Referrals_Work
		ALTER TABLE SCR_Warehouse.SCR_Referrals_Work 
		ADD CONSTRAINT PK_SCR_Referrals_Work PRIMARY KEY (
				CARE_ID ASC
				)
		
		-- Create a Primary Key for SCR_Comments_Work
		ALTER TABLE SCR_Warehouse.SCR_Comments_Work 
		ADD CONSTRAINT PK_SCR_Comments_Work PRIMARY KEY (
				SourceRecordId ASC
				,SourceTableName ASC
				,SourceColumnName ASC
				)
		
		-- Create a Primary Key for SCR_InterProviderTransfers_Work
		ALTER TABLE SCR_Warehouse.SCR_InterProviderTransfers_Work 
		ADD CONSTRAINT PK_InterProviderTransfers_Work PRIMARY KEY (
				TertiaryReferralId ASC
				)
		
		-- Keep a record of when the efficiency queries finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'efficiency PKs'
				

/************************************************************************************************************************************************************************************************************
-- Create the "Final" warehouse datasets by inserting the records not updated by the incremental process (if doing an incremental update)
************************************************************************************************************************************************************************************************************/

		-- Find the current CARE_IDs in tblMainReferrals so that any deleted referrals can be propogated to
		-- the final tables when doing an incremental update
		IF @IncrementalUpdate = 1 OR @UpdatePtlSnapshots & 1 = 1
		BEGIN
				-- Drop #MainRefCareIds if it exists
				IF OBJECT_ID('tempdb.dbo.#MainRefCareIds') IS NOT NULL
					DROP TABLE #MainRefCareIds
				
				-- Create a temporary table with all the CARE_IDs in tblMainReferrals
				SELECT		CARE_ID
				INTO		#MainRefCareIds
				FROM		LocalConfig.tblMAIN_REFERRALS

				-- Create an Index for CARE_ID in #MainRefCareIds
				CREATE CLUSTERED INDEX Ix_CARE_ID ON #MainRefCareIds (
						CARE_ID ASC
						)
				
		END
		
		IF @IncrementalUpdate = 1
		BEGIN
			BEGIN TRY
				PRINT 'Begin Incremental Transaction'

				BEGIN TRANSACTION
		
				-- Keep a record of when the "Final" incremental referral dataset started
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" incremental referral dataset'
				
				-- Delete any records that are no longer in tblMainReferrals
				DELETE
				FROM		r
				FROM		SCR_Warehouse.SCR_Referrals r
				LEFT JOIN	#MainRefCareIds mainref
								ON	r.CARE_ID = mainref.CARE_ID						-- to ensure we exclude records that have been deleted (we can only identify these by their absence from tblMAIN_REFERRALS)
				WHERE		mainref.CARE_ID IS NULL
				
				-- Delete any records that have been reprocessed by the incremental load
				DELETE
				FROM		r
				FROM		SCR_Warehouse.SCR_Referrals r
				INNER JOIN	#Incremental inc
								ON	r.CARE_ID = inc.CARE_ID
				
				-- Insert SCR_Referral records updated by the incremental process
				INSERT INTO SCR_Warehouse.SCR_Referrals
							(CARE_ID
							,PatientPathwayID
							,PatientPathwayIdIssuer
							,PATIENT_ID
							,MainRefActionId
							,DiagnosisActionId
							,DemographicsActionId
							,Forename
							,Surname
							,DateBirth
							,HospitalNumber
							,NHSNumber
							,NHSNumberStatusCode
							,NstsStatus
							,IsTemporaryNhsNumber
							,DeathStatus
							,DateDeath
							,PctCode
							,PctDesc
							,CcgCode
							,CcgDesc
							,CancerSite
							,CancerSiteBS
							,CancerSubSiteCode
							,CancerSubSiteDesc
							,ReferralCancerSiteCode
							,ReferralCancerSiteDesc
							,ReferralCancerSiteBS
							,CancerTypeCode
							,CancerTypeDesc
							,PriorityTypeCode
							,PriorityTypeDesc
							,SourceReferralCode
							,SourceReferralDesc
							,ReferralMethodCode
							,DecisionToReferDate
							,TumourStatusCode
							,TumourStatusDesc
							,PatientStatusCode
							,PatientStatusDesc
							,PatientStatusCodeCwt
							,PatientStatusDescCwt
							,ConsultantCode
							,ConsultantName
							,InappropriateRef
							,TransferReason
							,TransferNewRefDate
							,TransferTumourSiteCode
							,TransferTumourSiteDesc
							,TransferActionedDate
							,TransferSourceCareId
							,TransferOrigSourceCareId
							,FastDiagInformedDate
							,FastDiagExclDate
							,FastDiagCancerSiteID
							,FastDiagCancerSiteOverrideID
							,FastDiagCancerSiteCode
							,FastDiagCancerSiteDesc
							,FastDiagEndReasonID
							,FastDiagEndReasonCode
							,FastDiagEndReasonDesc
							,FastDiagDelayReasonID
							,FastDiagDelayReasonCode
							,FastDiagDelayReasonDesc
							,FastDiagDelayReasonComments
							,FastDiagExclReasonID
							,FastDiagExclReasonCode
							,FastDiagExclReasonDesc
							,FastDiagOrgID
							,FastDiagOrgCode
							,FastDiagOrgDesc
							,FastDiagCommMethodID
							,FastDiagCommMethodCode
							,FastDiagCommMethodDesc
							,FastDiagOtherCommMethod
							,FastDiagInformingCareProfID
							,FastDiagInformingCareProfCode
							,FastDiagInformingCareProfDesc
							,FastDiagOtherCareProf
							,DateDiagnosis
							,AgeAtDiagnosis
							,DiagnosisCode
							,DiagnosisSubCode
							,DiagnosisDesc
							,DiagnosisSubDesc
							,OrgIdDiagnosis
							,OrgCodeDiagnosis
							,OrgDescDiagnosis
							,SnomedCT_ID
							,SnomedCT_MCode
							,SnomedCT_ConceptID
							,SnomedCT_Desc
							,Histology
							,DateReceipt
							,AgeAtReferral
							,AppointmentCancelledDate
							,DateConsultantUpgrade
							,DateFirstSeen
							,OrgIdUpgrade
							,OrgCodeUpgrade
							,OrgDescUpgrade
							,OrgIdFirstSeen
							,OrgCodeFirstSeen
							,OrgDescFirstSeen
							,FirstAppointmentTypeCode
							,FirstAppointmentTypeDesc
							,FirstAppointmentOffered
							,ReasonNoAppointmentCode
							,ReasonNoAppointmentDesc
							,FirstSeenAdjTime
							,FirstSeenAdjReasonCode
							,FirstSeenAdjReasonDesc
							,FirstSeenDelayReasonCode
							,FirstSeenDelayReasonDesc
							,FirstSeenDelayReasonComment
							,DTTAdjTime
							,DTTAdjReasonCode
							,DTTAdjReasonDesc
							,IsBCC
							,IsCwtCancerDiagnosis
							,UnderCancerCareFlag
							,RefreshMaxActionDate
							,ReportDate
							,DateLastTracked
							,DaysSinceLastTracked )

				SELECT		rw.CARE_ID
							,rw.PatientPathwayID
							,rw.PatientPathwayIdIssuer
							,rw.PATIENT_ID
							,rw.MainRefActionId
							,rw.DiagnosisActionId
							,rw.DemographicsActionId
							,rw.Forename
							,rw.Surname
							,rw.DateBirth
							,rw.HospitalNumber
							,rw.NHSNumber
							,rw.NHSNumberStatusCode
							,rw.NstsStatus
							,rw.IsTemporaryNhsNumber
							,rw.DeathStatus
							,rw.DateDeath
							,rw.PctCode
							,rw.PctDesc
							,rw.CcgCode
							,rw.CcgDesc
							,rw.CancerSite
							,rw.CancerSiteBS
							,rw.CancerSubSiteCode
							,rw.CancerSubSiteDesc
							,rw.ReferralCancerSiteCode
							,rw.ReferralCancerSiteDesc
							,rw.ReferralCancerSiteBS
							,rw.CancerTypeCode
							,rw.CancerTypeDesc
							,rw.PriorityTypeCode
							,rw.PriorityTypeDesc
							,rw.SourceReferralCode
							,rw.SourceReferralDesc
							,rw.ReferralMethodCode
							,rw.DecisionToReferDate
							,rw.TumourStatusCode
							,rw.TumourStatusDesc
							,rw.PatientStatusCode
							,rw.PatientStatusDesc
							,rw.PatientStatusCodeCwt
							,rw.PatientStatusDescCwt
							,rw.ConsultantCode
							,rw.ConsultantName
							,rw.InappropriateRef
							,rw.TransferReason
							,rw.TransferNewRefDate
							,rw.TransferTumourSiteCode
							,rw.TransferTumourSiteDesc
							,rw.TransferActionedDate
							,rw.TransferSourceCareId
							,rw.TransferOrigSourceCareId
							,rw.FastDiagInformedDate
							,rw.FastDiagExclDate
							,rw.FastDiagCancerSiteID
							,rw.FastDiagCancerSiteOverrideID
							,rw.FastDiagCancerSiteCode
							,rw.FastDiagCancerSiteDesc
							,rw.FastDiagEndReasonID
							,rw.FastDiagEndReasonCode
							,rw.FastDiagEndReasonDesc
							,rw.FastDiagDelayReasonID
							,rw.FastDiagDelayReasonCode
							,rw.FastDiagDelayReasonDesc
							,rw.FastDiagDelayReasonComments
							,rw.FastDiagExclReasonID
							,rw.FastDiagExclReasonCode
							,rw.FastDiagExclReasonDesc
							,rw.FastDiagOrgID
							,rw.FastDiagOrgCode
							,rw.FastDiagOrgDesc
							,rw.FastDiagCommMethodID
							,rw.FastDiagCommMethodCode
							,rw.FastDiagCommMethodDesc
							,rw.FastDiagOtherCommMethod
							,rw.FastDiagInformingCareProfID
							,rw.FastDiagInformingCareProfCode
							,rw.FastDiagInformingCareProfDesc
							,rw.FastDiagOtherCareProf
							,rw.DateDiagnosis
							,rw.AgeAtDiagnosis
							,rw.DiagnosisCode
							,rw.DiagnosisSubCode
							,rw.DiagnosisDesc
							,rw.DiagnosisSubDesc
							,rw.OrgIdDiagnosis
							,rw.OrgCodeDiagnosis
							,rw.OrgDescDiagnosis
							,rw.SnomedCT_ID
							,rw.SnomedCT_MCode
							,rw.SnomedCT_ConceptID
							,rw.SnomedCT_Desc
							,rw.Histology
							,rw.DateReceipt
							,rw.AgeAtReferral
							,rw.AppointmentCancelledDate
							,rw.DateConsultantUpgrade
							,rw.DateFirstSeen
							,rw.OrgIdUpgrade
							,rw.OrgCodeUpgrade
							,rw.OrgDescUpgrade
							,rw.OrgIdFirstSeen
							,rw.OrgCodeFirstSeen
							,rw.OrgDescFirstSeen
							,rw.FirstAppointmentTypeCode
							,rw.FirstAppointmentTypeDesc
							,rw.FirstAppointmentOffered
							,rw.ReasonNoAppointmentCode
							,rw.ReasonNoAppointmentDesc
							,rw.FirstSeenAdjTime
							,rw.FirstSeenAdjReasonCode
							,rw.FirstSeenAdjReasonDesc
							,rw.FirstSeenDelayReasonCode
							,rw.FirstSeenDelayReasonDesc
							,rw.FirstSeenDelayReasonComment
							,rw.DTTAdjTime
							,rw.DTTAdjReasonCode
							,rw.DTTAdjReasonDesc
							,rw.IsBCC
							,rw.IsCwtCancerDiagnosis
							,rw.UnderCancerCareFlag
							,rw.RefreshMaxActionDate
							,rw.ReportDate
							,rw.DateLastTracked
							,rw.DaysSinceLastTracked

				FROM		SCR_Warehouse.SCR_Referrals_work rw

				-- Keep a record of when the "Final" incremental referral dataset finished
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" incremental referral dataset'
				
				-- Keep a record of when the "Final" incremental CWT dataset started
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" incremental CWT dataset'
				
				-- Update the OriginalCWTInsertIx in SCR_CWT_work from CWTInsertIx for the incremental (or bulk) records processed in this execution
				UPDATE		SCR_Warehouse.SCR_CWT_work
				SET			OriginalCWTInsertIx = CWTInsertIx
				
				-- Delete any records that are no longer in tblMainReferrals
				DELETE
				FROM		c
				FROM		SCR_Warehouse.SCR_CWT c
				LEFT JOIN	#MainRefCareIds mainref
								ON	c.CARE_ID = mainref.CARE_ID						-- to ensure we exclude records that have been deleted (we can only identify these by their absence from tblMAIN_REFERRALS)
				WHERE		mainref.CARE_ID IS NULL
				
				-- Delete any records that have been reprocessed by the incremental load
				DELETE
				FROM		c
				FROM		SCR_Warehouse.SCR_CWT c
				INNER JOIN	#Incremental inc
								ON	c.CARE_ID = inc.CARE_ID
				

				-- Insert SCR_CWT records updated by the incremental process
				INSERT INTO SCR_Warehouse.SCR_CWT
							(OriginalCWTInsertIx
							,CARE_ID
							,CWT_ID
							,Tx_ID
							,TREATMENT_ID
							,TREAT_ID
							,CHEMO_ID
							,TELE_ID
							,PALL_ID
							,BRACHY_ID
							,OTHER_ID
							,SURGERY_ID
							,MONITOR_ID
							,ChemoActionId
							,TeleActionId
							,PallActionId
							,BrachyActionId
							,OtherActionId
							,SurgeryActionId
							,MonitorActionId
							,DeftTreatmentEventCode
							,DeftTreatmentEventDesc
							,DeftTreatmentCode
							,DeftTreatmentDesc
							,DeftTreatmentSettingCode
							,DeftTreatmentSettingDesc
							,DeftDateDecisionTreat
							,DeftDateTreatment
							,DeftDTTAdjTime
							,DeftDTTAdjReasonCode
							,DeftDTTAdjReasonDesc
							,DeftOrgIdDecisionTreat
							,DeftOrgCodeDecisionTreat
							,DeftOrgDescDecisionTreat
							,DeftOrgIdTreatment
							,DeftOrgCodeTreatment
							,DeftOrgDescTreatment
							,DeftDefinitiveTreatment
							,DeftChemoRT
							,TxModTreatmentEventCode
							,TxModTreatmentEventDesc
							,TxModTreatmentCode
							,TxModTreatmentDesc
							,TxModTreatmentSettingCode
							,TxModTreatmentSettingDesc
							,TxModDateDecisionTreat
							,TxModDateTreatment
							,TxModOrgIdDecisionTreat
							,TxModOrgCodeDecisionTreat
							,TxModOrgDescDecisionTreat
							,TxModOrgIdTreatment
							,TxModOrgCodeTreatment
							,TxModOrgDescTreatment
							,TxModDefinitiveTreatment
							,TxModChemoRadio
							,TxModChemoRT
							,TxModModalitySubCode
							,TxModRadioSurgery
							,ChemRtLinkTreatmentEventCode
							,ChemRtLinkTreatmentEventDesc
							,ChemRtLinkTreatmentCode
							,ChemRtLinkTreatmentDesc
							,ChemRtLinkTreatmentSettingCode
							,ChemRtLinkTreatmentSettingDesc
							,ChemRtLinkDateDecisionTreat
							,ChemRtLinkDateTreatment
							,ChemRtLinkOrgIdDecisionTreat
							,ChemRtLinkOrgCodeDecisionTreat
							,ChemRtLinkOrgDescDecisionTreat
							,ChemRtLinkOrgIdTreatment
							,ChemRtLinkOrgCodeTreatment
							,ChemRtLinkOrgDescTreatment
							,ChemRtLinkDefinitiveTreatment
							,ChemRtLinkChemoRadio
							,ChemRtLinkModalitySubCode
							,ChemRtLinkRadioSurgery
							,cwtFlag2WW
							,cwtFlag28
							,cwtFlag31
							,cwtFlag62
							,cwtType2WW
							,cwtType28
							,cwtType31
							,cwtType62
							,cwtReason2WW
							,cwtReason28
							,cwtReason31
							,cwtReason62
							,HasTxMod
							,HasChemRtLink
							,ClockStartDate2WW
							,ClockStartDate28
							,ClockStartDate31
							,ClockStartDate62
							,AdjTime2WW
							,AdjTime28
							,AdjTime31
							,AdjTime62
							,TargetDate2WW
							,TargetDate28
							,TargetDate31
							,TargetDate62
							,DaysTo2WWBreach
							,DaysTo28DayBreach
							,DaysTo31DayBreach
							,DaysTo62DayBreach
							,ClockStopDate2WW
							,ClockStopDate28
							,ClockStopDate31
							,ClockStopDate62
							,Waitingtime2WW
							,Waitingtime28
							,Waitingtime31
							,Waitingtime62
							,Breach2WW
							,Breach28
							,Breach31
							,Breach62
							,WillBeClockStopDate2WW
							,WillBeClockStopDate28 
							,WillBeClockStopDate31 
							,WillBeClockStopDate62 
							,WillBeWaitingtime2WW
							,WillBeWaitingtime28 
							,WillBeWaitingtime31 
							,WillBeWaitingtime62 
							,WillBeBreach2WW
							,WillBeBreach28 
							,WillBeBreach31 
							,WillBeBreach62 
							,DaysTo62DayBreachNoDTT
							,Treated7Days
							,Treated7Days62Days
							,FutureAchieve62Days
							,FutureFail62Days
							,ActualWaitDTTTreatment
							,DTTTreated7Days
							,Treated7Days31Days
							,Treated7DaysBreach31Days
							,FutureAchieve31Days
							,FutureFail31Days
							,FutureDTT
							,NoDTTDate
							,LastCommentUser
							,LastCommentDate
							,ReportDate
							,DominantCWTStatusCode
							,DominantCWTStatusDesc
							,CWTStatusCode2WW
							,CWTStatusDesc2WW
							,CWTStatusCode28 
							,CWTStatusDesc28 
							,CWTStatusCode31 
							,CWTStatusDesc31 
							,CWTStatusCode62 
							,CWTStatusDesc62 
							,Pathway 
							,ReportingPathwayLength
							,Weighting 
							,DominantColourValue
							,ColourValue2WW 
							,ColourValue28Day 
							,ColourValue31Day 
							,ColourValue62Day 
							,DominantColourDesc
							,ColourDesc2WW 
							,ColourDesc28Day
							,ColourDesc31Day
							,ColourDesc62Day
							,DominantPriority
							,Priority2WW
							,Priority28 
							,Priority31 
							,Priority62 
							)
				SELECT		cw.OriginalCWTInsertIx
							,cw.CARE_ID
							,cw.CWT_ID
							,cw.Tx_ID
							,cw.TREATMENT_ID
							,cw.TREAT_ID
							,cw.CHEMO_ID
							,cw.TELE_ID
							,cw.PALL_ID
							,cw.BRACHY_ID
							,cw.OTHER_ID
							,cw.SURGERY_ID
							,cw.MONITOR_ID
							,cw.ChemoActionId
							,cw.TeleActionId
							,cw.PallActionId
							,cw.BrachyActionId
							,cw.OtherActionId
							,cw.SurgeryActionId
							,cw.MonitorActionId
							,cw.DeftTreatmentEventCode
							,cw.DeftTreatmentEventDesc
							,cw.DeftTreatmentCode
							,cw.DeftTreatmentDesc
							,cw.DeftTreatmentSettingCode
							,cw.DeftTreatmentSettingDesc
							,cw.DeftDateDecisionTreat
							,cw.DeftDateTreatment
							,cw.DeftDTTAdjTime
							,cw.DeftDTTAdjReasonCode
							,cw.DeftDTTAdjReasonDesc
							,cw.DeftOrgIdDecisionTreat
							,cw.DeftOrgCodeDecisionTreat
							,cw.DeftOrgDescDecisionTreat
							,cw.DeftOrgIdTreatment
							,cw.DeftOrgCodeTreatment
							,cw.DeftOrgDescTreatment
							,cw.DeftDefinitiveTreatment
							,cw.DeftChemoRT
							,cw.TxModTreatmentEventCode
							,cw.TxModTreatmentEventDesc
							,cw.TxModTreatmentCode
							,cw.TxModTreatmentDesc
							,cw.TxModTreatmentSettingCode
							,cw.TxModTreatmentSettingDesc
							,cw.TxModDateDecisionTreat
							,cw.TxModDateTreatment
							,cw.TxModOrgIdDecisionTreat
							,cw.TxModOrgCodeDecisionTreat
							,cw.TxModOrgDescDecisionTreat
							,cw.TxModOrgIdTreatment
							,cw.TxModOrgCodeTreatment
							,cw.TxModOrgDescTreatment
							,cw.TxModDefinitiveTreatment
							,cw.TxModChemoRadio
							,cw.TxModChemoRT
							,cw.TxModModalitySubCode
							,cw.TxModRadioSurgery
							,cw.ChemRtLinkTreatmentEventCode
							,cw.ChemRtLinkTreatmentEventDesc
							,cw.ChemRtLinkTreatmentCode
							,cw.ChemRtLinkTreatmentDesc
							,cw.ChemRtLinkTreatmentSettingCode
							,cw.ChemRtLinkTreatmentSettingDesc
							,cw.ChemRtLinkDateDecisionTreat
							,cw.ChemRtLinkDateTreatment
							,cw.ChemRtLinkOrgIdDecisionTreat
							,cw.ChemRtLinkOrgCodeDecisionTreat
							,cw.ChemRtLinkOrgDescDecisionTreat
							,cw.ChemRtLinkOrgIdTreatment
							,cw.ChemRtLinkOrgCodeTreatment
							,cw.ChemRtLinkOrgDescTreatment
							,cw.ChemRtLinkDefinitiveTreatment
							,cw.ChemRtLinkChemoRadio
							,cw.ChemRtLinkModalitySubCode
							,cw.ChemRtLinkRadioSurgery
							,cw.cwtFlag2WW
							,cw.cwtFlag28
							,cw.cwtFlag31
							,cw.cwtFlag62
							,cw.cwtType2WW
							,cw.cwtType28
							,cw.cwtType31
							,cw.cwtType62
							,cw.cwtReason2WW
							,cw.cwtReason28
							,cw.cwtReason31
							,cw.cwtReason62
							,cw.HasTxMod
							,cw.HasChemRtLink
							,cw.ClockStartDate2WW
							,cw.ClockStartDate28
							,cw.ClockStartDate31
							,cw.ClockStartDate62
							,cw.AdjTime2WW
							,cw.AdjTime28
							,cw.AdjTime31
							,cw.AdjTime62
							,cw.TargetDate2WW
							,cw.TargetDate28
							,cw.TargetDate31
							,cw.TargetDate62
							,cw.DaysTo2WWBreach
							,cw.DaysTo28DayBreach
							,cw.DaysTo31DayBreach
							,cw.DaysTo62DayBreach
							,cw.ClockStopDate2WW
							,cw.ClockStopDate28
							,cw.ClockStopDate31
							,cw.ClockStopDate62
							,cw.Waitingtime2WW
							,cw.Waitingtime28
							,cw.Waitingtime31
							,cw.Waitingtime62
							,cw.Breach2WW
							,cw.Breach28
							,cw.Breach31
							,cw.Breach62
							,cw.WillBeClockStopDate2WW
							,cw.WillBeClockStopDate28 
							,cw.WillBeClockStopDate31 
							,cw.WillBeClockStopDate62 
							,cw.WillBeWaitingtime2WW
							,cw.WillBeWaitingtime28 
							,cw.WillBeWaitingtime31 
							,cw.WillBeWaitingtime62 
							,cw.WillBeBreach2WW
							,cw.WillBeBreach28 
							,cw.WillBeBreach31 
							,cw.WillBeBreach62
							,cw.DaysTo62DayBreachNoDTT
							,cw.Treated7Days
							,cw.Treated7Days62Days
							,cw.FutureAchieve62Days
							,cw.FutureFail62Days
							,cw.ActualWaitDTTTreatment
							,cw.DTTTreated7Days
							,cw.Treated7Days31Days
							,cw.Treated7DaysBreach31Days
							,cw.FutureAchieve31Days
							,cw.FutureFail31Days
							,cw.FutureDTT
							,cw.NoDTTDate
							,cw.LastCommentUser
							,cw.LastCommentDate
							,cw.ReportDate
							,cw.DominantCWTStatusCode
							,cw.DominantCWTStatusDesc
							,cw.CWTStatusCode2WW
							,cw.CWTStatusDesc2WW
							,cw.CWTStatusCode28 
							,cw.CWTStatusDesc28 
							,cw.CWTStatusCode31 
							,cw.CWTStatusDesc31 
							,cw.CWTStatusCode62 
							,cw.CWTStatusDesc62
							,cw.Pathway 
							,cw.ReportingPathwayLength
							,cw.Weighting 
							,cw.DominantColourValue
							,cw.ColourValue2WW 
							,cw.ColourValue28Day 
							,cw.ColourValue31Day 
							,cw.ColourValue62Day 
							,cw.DominantColourDesc
							,cw.ColourDesc2WW 
							,cw.ColourDesc28Day
							,cw.ColourDesc31Day
							,cw.ColourDesc62Day
							,cw.DominantPriority
							,cw.Priority2WW
							,cw.Priority28 
							,cw.Priority31 
							,cw.Priority62 

				FROM		SCR_Warehouse.SCR_CWT_Work cw

				-- Keep a record of when the "Final" incremental CWT dataset finished
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" incremental CWT dataset'
				
				-- Keep a record of when the "Final" incremental comments dataset started
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" incremental comments dataset'
				
				-- Delete any records that are no longer in tblMainReferrals
				DELETE
				FROM		c
				FROM		SCR_Warehouse.SCR_Comments c
				LEFT JOIN	#MainRefCareIds mainref
								ON	c.CARE_ID = mainref.CARE_ID						-- to ensure we exclude records that have been deleted (we can only identify these by their absence from tblMAIN_REFERRALS)
				WHERE		mainref.CARE_ID IS NULL
				
				-- Delete any records that have been reprocessed by the incremental load
				DELETE
				FROM		c
				FROM		SCR_Warehouse.SCR_Comments c
				INNER JOIN	#Incremental inc
								ON	c.CARE_ID = inc.CARE_ID
	
				-- Insert SCR_Comments records updated by the incremental process
				INSERT INTO SCR_Warehouse.SCR_Comments
							(SourceRecordId
							,SourceTableName
							,SourceColumnName
							,CARE_ID
							,Comment
							,CommentUser
							,CommentDate
							,CommentType
							,CareIdIx
							,CareIdRevIx
							,CommentTypeCareIdIx
							,CommentTypeCareIdRevIx
							,ReportDate)
				SELECT		cw.SourceRecordId
							,cw.SourceTableName
							,cw.SourceColumnName
							,cw.CARE_ID
							,cw.Comment
							,cw.CommentUser
							,cw.CommentDate
							,cw.CommentType
							,cw.CareIdIx
							,cw.CareIdRevIx
							,cw.CommentTypeCareIdIx
							,cw.CommentTypeCareIdRevIx
							,cw.ReportDate
				FROM		SCR_Warehouse.SCR_Comments_work cw

				-- Keep a record of when the "Final" incremental comments dataset finished
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" incremental comments dataset'
				
				-- Keep a record of when the "Final" incremental IPT dataset started
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" incremental IPT dataset'
				
				-- Delete any records that are no longer in tblMainReferrals
				DELETE
				FROM		ipt
				FROM		SCR_Warehouse.SCR_InterProviderTransfers ipt
				LEFT JOIN	#MainRefCareIds mainref
								ON	ipt.CareId = mainref.CARE_ID						-- to ensure we exclude records that have been deleted (we can only identify these by their absence from tblMAIN_REFERRALS)
				WHERE		mainref.CARE_ID IS NULL
				
				-- Delete any records that have been reprocessed by the incremental load
				DELETE
				FROM		ipt
				FROM		SCR_Warehouse.SCR_InterProviderTransfers ipt
				INNER JOIN	SCR_Warehouse.SCR_InterProviderTransfers_Work iptw
								ON	ipt.TertiaryReferralID = iptw.TertiaryReferralID
	
				-- Insert SCR_InterProviderTransfers records updated by the incremental process
				INSERT INTO	SCR_Warehouse.SCR_InterProviderTransfers
							(TertiaryReferralID
							,CareID
							,ACTION_ID
							,IPTTypeCode
							,IPTTypeDesc
							,IPTDate
							,IPTReferralReasonCode
							,IPTReferralReasonDesc
							,IPTReceiptReasonCode 
							,IPTReceiptReasonDesc 
							,ReferringOrgID
							,ReferringOrgCode
							,ReferringOrgName
							,TertiaryReferralOutComments
							,ReceivingOrgID
							,ReceivingOrgCode
							,ReceivingOrgName
							,TertiaryReferralInComments
							,IptReasonTypeCareIdIx
							,LastUpdatedBy)
				SELECT		iptw.TertiaryReferralID
							,iptw.CareID
							,iptw.ACTION_ID
							,iptw.IPTTypeCode
							,iptw.IPTTypeDesc
							,iptw.IPTDate
							,iptw.IPTReferralReasonCode
							,iptw.IPTReferralReasonDesc
							,iptw.IPTReceiptReasonCode 
							,iptw.IPTReceiptReasonDesc 
							,iptw.ReferringOrgID
							,iptw.ReferringOrgCode
							,iptw.ReferringOrgName
							,iptw.TertiaryReferralOutComments
							,iptw.ReceivingOrgID
							,iptw.ReceivingOrgCode
							,iptw.ReceivingOrgName
							,iptw.TertiaryReferralInComments
							,iptw.IptReasonTypeCareIdIx
							,iptw.LastUpdatedBy
				FROM		SCR_Warehouse.SCR_InterProviderTransfers_Work iptw

				-- Keep a record of when the "Final" incremental IPT dataset finished
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" incremental IPT dataset'

				-- Keep a record of when the "Final" OpenTargetDates dataset started
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" OpenTargetDates dataset'
				
				-- Delete any records that are no longer in tblMainReferrals
				DELETE
				FROM		OTD
				FROM		SCR_Warehouse.OpenTargetDates OTD
				LEFT JOIN	#MainRefCareIds mainref
								ON	OTD.CARE_ID = mainref.CARE_ID						-- to ensure we exclude records that have been deleted (we can only identify these by their absence from tblMAIN_REFERRALS)
				WHERE		mainref.CARE_ID IS NULL
				
				-- Delete any records that have been reprocessed by the incremental load
				DELETE
				FROM		OTD
				FROM		SCR_Warehouse.OpenTargetDates OTD
				INNER JOIN	#Incremental inc
								ON	OTD.CARE_ID = inc.CARE_ID
	
				-- Insert the records updated by the incremental process 
				INSERT INTO	SCR_Warehouse.OpenTargetDates
							(CWT_ID
							,CARE_ID
							,DaysToTarget
							,TargetDate
							,DaysToBreach
							,BreachDate
							,TargetType
							,WaitTargetGroupDesc
							,WaitTargetPriority
							,ReportDate
							,IxFirstOpenTargetDate
							,IxLastOpenTargetDate
							,IxNextFutureOpenTargetDate
							,IxLastFutureOpenTargetDate
							,IxFirstOpenGroupTargetDate
							,IxLastOpenGroupTargetDate
							,IxNextFutureOpenGroupTargetDate
							,IxLastFutureOpenGroupTargetDate
							,IxFirstOpenBreachDate
							,IxLastOpenBreachDate
							,IxNextFutureOpenBreachDate
							,IxLastFutureOpenBreachDate
							,IxFirstOpenGroupBreachDate
							,IxLastOpenGroupBreachDate
							,IxNextFutureOpenGroupBreachDate
							,IxLastFutureOpenGroupBreachDate)
				SELECT		OTDw.CWT_ID
							,OTDw.CARE_ID
							,OTDw.DaysToTarget
							,OTDw.TargetDate
							,OTDw.DaysToBreach
							,OTDw.BreachDate
							,OTDw.TargetType
							,OTDw.WaitTargetGroupDesc
							,OTDw.WaitTargetPriority
							,OTDw.ReportDate
							,OTDw.IxFirstOpenTargetDate
							,OTDw.IxLastOpenTargetDate
							,OTDw.IxNextFutureOpenTargetDate
							,OTDw.IxLastFutureOpenTargetDate
							,OTDw.IxFirstOpenGroupTargetDate
							,OTDw.IxLastOpenGroupTargetDate
							,OTDw.IxNextFutureOpenGroupTargetDate
							,OTDw.IxLastFutureOpenGroupTargetDate
							,OTDw.IxFirstOpenBreachDate
							,OTDw.IxLastOpenBreachDate
							,OTDw.IxNextFutureOpenBreachDate
							,OTDw.IxLastFutureOpenBreachDate
							,OTDw.IxFirstOpenGroupBreachDate
							,OTDw.IxLastOpenGroupBreachDate
							,OTDw.IxNextFutureOpenGroupBreachDate
							,OTDw.IxLastFutureOpenGroupBreachDate
				FROM		SCR_Warehouse.OpenTargetDates_work OTDw

				-- Keep a record of when the "Final" PTL_Live dataset finished
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" OpenTargetDates dataset'


				-- Keep a record of when the "Final" incremental Workflow dataset started
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" incremental Workflow dataset'
				
				-- Delete any records that are no longer in tblMainReferrals
				DELETE
				FROM		wf
				FROM		SCR_Warehouse.Workflow wf
				LEFT JOIN	#MainRefCareIds mainref
								ON	LEFT(wf.CWT_ID, CHARINDEX('|',wf.CWT_ID)-1) = mainref.CARE_ID						-- to ensure we exclude records that have been deleted (we can only identify these by their absence from tblMAIN_REFERRALS)
				WHERE		mainref.CARE_ID IS NULL
				
				-- Delete any records that have been reprocessed by the incremental load
				DELETE
				FROM		wf
				FROM		SCR_Warehouse.Workflow wf
				INNER JOIN	#Incremental inc
								ON	LEFT(wf.CWT_ID, CHARINDEX('|',wf.CWT_ID)-1) = inc.CARE_ID
	
				-- Insert Workflow records updated by the incremental process
				INSERT INTO	SCR_Warehouse.Workflow
							(CWT_ID
							,WorkflowID)
				SELECT		wfw.CWT_ID
							,wfw.WorkflowID
				FROM		SCR_Warehouse.Workflow_work wfw

				-- Keep a record of when the "Final" incremental Workflow dataset finished
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" incremental Workflow dataset'
				
				PRINT 'Incremental Transaction successful'
				
				-- Keep a record of when the Incremental Transaction started
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'Incremental Transaction'
				
				COMMIT TRANSACTION
				
				-- Keep a record of when the Incremental Transaction finished
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'Incremental Transaction'

			END TRY

			BEGIN CATCH

				IF @@TRANCOUNT > 0
					PRINT 'Rolling back because of error in Incremental Transaction'
					ROLLBACK TRANSACTION
 
				SELECT ERROR_NUMBER() AS ErrorNumber
				SELECT ERROR_MESSAGE() AS ErrorMessage
 
			END CATCH
				
		END

/************************************************************************************************************************************************************************************************************
-- Create Indexes to make reporting queries more efficient
************************************************************************************************************************************************************************************************************/

		IF @IncrementalUpdate = 0
		BEGIN
		
				-- Keep a record of when the efficiency queries started
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'efficiency Indexes'
				
		
				-- Create an Index for CARE_ID in SCR_CWT_Work
				CREATE NONCLUSTERED INDEX Ix_CARE_ID_Work ON SCR_Warehouse.SCR_CWT_work (
						CARE_ID ASC
						)
		
				-- Create an Index for cwtFlag2WW in SCR_CWT_Work
				CREATE NONCLUSTERED INDEX Ix_cwtFlag2WW_Work ON SCR_Warehouse.SCR_CWT_work (
						cwtFlag2WW ASC
						)

				-- Create an Index for cwtFlag28 in SCR_CWT_Work
				CREATE NONCLUSTERED INDEX Ix_cwtFlag28_Work ON SCR_Warehouse.SCR_CWT_work (
						cwtFlag28 ASC
						)

				-- Create an Index for cwtFlag31 in SCR_CWT_Work
				CREATE NONCLUSTERED INDEX Ix_cwtFlag31_Work ON SCR_Warehouse.SCR_CWT_work (
						cwtFlag31 ASC
						)

				-- Create an Index for cwtFlag62 in SCR_CWT_Work
				CREATE NONCLUSTERED INDEX Ix_cwtFlag62_Work ON SCR_Warehouse.SCR_CWT_work (
						cwtFlag62 ASC
						)
		
		
				-- Create an Index for CARE_ID in SCR_Comments_Work
				CREATE NONCLUSTERED INDEX Ix_CARE_ID_Work ON SCR_Warehouse.SCR_Comments_Work (
						CARE_ID ASC
						)

				-- Create an Index for CommentTypeCareIdIx in SCR_Comments_Work
				CREATE NONCLUSTERED INDEX Ix_CommentTypeCareIdIx_Work ON SCR_Warehouse.SCR_Comments_Work (
						CARE_ID ASC
						,CommentTypeCareIdIx ASC
						,CommentType
						)
						INCLUDE (
						Comment
						,CommentDate
						) 

				-- Create an Index for the PTL_Live in SCR_Comments_Work
				CREATE NONCLUSTERED INDEX Ix_PTL_Live_Work ON SCR_Warehouse.SCR_Comments_Work (
						CommentType
						,CommentTypeCareIdRevIx
						,CARE_ID
						)
						INCLUDE (
						Comment
						,CommentUser
						) 
		
		
				-- Create an Index for CARE_ID in SCR_InterProviderTransfers_Work
				CREATE NONCLUSTERED INDEX Ix_CARE_ID_Work ON SCR_Warehouse.SCR_InterProviderTransfers_Work (
						CareID ASC
						)
		
				-- Keep a record of when the efficiency queries finished
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = 'efficiency Indexes'
				

/************************************************************************************************************************************************************************************************************
-- Switch out the working tables with the live warehouse tables
************************************************************************************************************************************************************************************************************/
	
				------------------------ RAG_work ------------------------
				---------------------------------------------------------------
				-- DROP RAG table if it exists
				if object_ID('SCR_Reporting.RAG') is not null 
				   DROP TABLE SCR_Reporting.RAG

				-- Rename the RAG_work table as RAG
				EXEC sp_rename 'SCR_Reporting.RAG_work', 'RAG'

				-- Rename the Primary Key on RAG
				EXEC sp_rename 'SCR_Reporting.RAG.PK_RAG_work', 'PK_RAG'

				------------------------ SCR_CWT ------------------------
				---------------------------------------------------------------
				-- DROP SCR_CWT table if it exists
				if object_ID('SCR_Warehouse.SCR_CWT') is not null 
				   DROP TABLE SCR_Warehouse.SCR_CWT

				-- Rename the SCR_CWT_Work table as SCR_CWT
				EXEC sp_rename 'SCR_Warehouse.SCR_CWT_Work', 'SCR_CWT'

				-- Rename the Primary Key on SCR_CWT
				EXEC sp_rename 'SCR_Warehouse.SCR_CWT.PK_SCR_CWT_work', 'PK_SCR_CWT'

				-- Rename the Ix_CARE_ID index on SCR_CWT
				EXEC sp_rename 'SCR_Warehouse.SCR_CWT.Ix_CARE_ID_Work', 'Ix_CARE_ID'

				-- Rename the Ix_CARE_ID index on SCR_CWT
				EXEC sp_rename 'SCR_Warehouse.SCR_CWT.Ix_cwtFlag28_Work', 'Ix_cwtFlag28'

				-- Rename the Ix_CARE_ID index on SCR_CWT
				EXEC sp_rename 'SCR_Warehouse.SCR_CWT.Ix_cwtFlag2WW_Work', 'Ix_cwtFlag2WW'

				-- Rename the Ix_CARE_ID index on SCR_CWT
				EXEC sp_rename 'SCR_Warehouse.SCR_CWT.Ix_cwtFlag31_Work', 'Ix_cwtFlag31'

				-- Rename the Ix_CARE_ID index on SCR_CWT
				EXEC sp_rename 'SCR_Warehouse.SCR_CWT.Ix_cwtFlag62_Work', 'Ix_cwtFlag62'

				-- Rename the Ix_CARE_ID index on SCR_CWT
				EXEC sp_rename 'SCR_Warehouse.SCR_CWT.Ix_TxMod_Work', 'Ix_TxMod'

				------------------------ SCR_Comments ------------------------
				---------------------------------------------------------------
				-- DROP SCR_Comments table if it exists
				if object_ID('SCR_Warehouse.SCR_Comments') is not null 
				   DROP TABLE SCR_Warehouse.SCR_Comments

				-- Rename the SCR_Comments_Work table as SCR_Comments
				EXEC sp_rename 'SCR_Warehouse.SCR_Comments_work', 'SCR_Comments'

				-- Rename the Primary Key on SCR_Comments
				EXEC sp_rename 'SCR_Warehouse.SCR_Comments.PK_SCR_Comments_work', 'PK_SCR_Comments'

				-- Rename the Ix_CARE_ID index on SCR_Comments
				EXEC sp_rename 'SCR_Warehouse.SCR_Comments.Ix_CARE_ID_Work', 'Ix_CARE_ID'

				-- Rename the Ix_CommentTypeCareIdIx index on SCR_Comments
				EXEC sp_rename 'SCR_Warehouse.SCR_Comments.Ix_CommentTypeCareIdIx_Work', 'Ix_CommentTypeCareIdIx'

				-- Rename the Ix_PTL_Live index on SCR_Comments
				EXEC sp_rename 'SCR_Warehouse.SCR_Comments.Ix_PTL_Live_Work', 'Ix_PTL_Live'

				------------------------ SCR_InterProviderTransfers ------------------------
				---------------------------------------------------------------
				-- DROP SCR_InterProviderTransfers table if it exists
				if object_ID('SCR_Warehouse.SCR_InterProviderTransfers') is not null 
				   DROP TABLE SCR_Warehouse.SCR_InterProviderTransfers

				-- Rename the SCR_InterProviderTransfers_Work table as SCR_InterProviderTransfers
				EXEC sp_rename 'SCR_Warehouse.SCR_InterProviderTransfers_Work', 'SCR_InterProviderTransfers'

				-- Rename the Primary Key on SCR_InterProviderTransfers
				EXEC sp_rename 'SCR_Warehouse.SCR_InterProviderTransfers.PK_InterProviderTransfers_work', 'PK_InterProviderTransfers'

				-- Rename the Ix_CARE_ID index on SCR_InterProviderTransfers
				EXEC sp_rename 'SCR_Warehouse.SCR_InterProviderTransfers.Ix_CARE_ID_Work', 'Ix_CARE_ID'
		
				------------------------ OpenTargetDates_work ------------------------
				---------------------------------------------------------------
				-- DROP OpenTargetDates table if it exists
				if object_ID('SCR_Warehouse.OpenTargetDates') is not null 
				   DROP TABLE SCR_Warehouse.OpenTargetDates

				-- Rename the OpenTargetDates_work table as OpenTargetDates
				EXEC sp_rename 'SCR_Warehouse.OpenTargetDates_work', 'OpenTargetDates'

				-- Rename the Primary Key on OpenTargetDates
				EXEC sp_rename 'SCR_Warehouse.OpenTargetDates.PK_OpenTargetDates_work', 'PK_OpenTargetDates'

				------------------------ Workflow_work ------------------------
				---------------------------------------------------------------
				-- DROP Workflow table if it exists
				if object_ID('SCR_Warehouse.Workflow') is not null 
				   DROP TABLE SCR_Warehouse.Workflow

				-- Rename the Workflow_work table as Workflow
				EXEC sp_rename 'SCR_Warehouse.Workflow_work', 'Workflow'

				-- Rename the Primary Key on RAG
				EXEC sp_rename 'SCR_Warehouse.Workflow.PK_Workflow_work', 'PK_Workflow'
		
				------------------------ SCR_Referrals ------------------------
				-- Do this table last - the incremental load will work from the
				-- previous version of this table if this fails which will 
				-- ensure that no incremental updates are missed on the other
				-- tables!
				---------------------------------------------------------------
				-- DROP SCR_Referrals table if it exists
				if object_ID('SCR_Warehouse.SCR_Referrals') is not null 
				   DROP TABLE SCR_Warehouse.SCR_Referrals

				-- Rename the SCR_Referrals_Work table as SCR_Referrals
				EXEC sp_rename 'SCR_Warehouse.SCR_Referrals_Work', 'SCR_Referrals'

				-- Rename the Primary Key on SCR_CWT
				EXEC sp_rename 'SCR_Warehouse.SCR_Referrals.PK_SCR_Referrals_Work', 'PK_SCR_Referrals'

		END


/************************************************************************************************************************************************************************************************************
-- Copying the records from PTL_Live to PTL_Daily and / or PTL_Weekly (if we are refreshing the daily or weekly snapshot to match live)
************************************************************************************************************************************************************************************************************/

		-- Create the "Final" reporting PTL_Daily dataset by copying the records from PTL_Live_work (if we are refreshing the daily snapshot to match live)
		IF @UpdatePtlSnapshots & 2 = 2
		BEGIN

				-- Keep a record of when the "Final" PTL_Daily dataset started
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" PTL_Daily dataset'
				
				-- DROP PTL_Daily_Work table if it exists
				if object_ID('SCR_Reporting.PTL_Daily_Work') is not null 
				   DROP TABLE SCR_Reporting.PTL_Daily_Work

				-- Create the PTL_Daily_work table from the PTL_Live View
				SELECT		*
				INTO		SCR_Reporting.PTL_Daily_Work
				FROM		SCR_Reporting.PTL_Live

				--Make CWT_ID not null
				ALTER TABLE SCR_Reporting.PTL_Daily_work
				ALTER COLUMN CWT_ID varchar(255) NOT NULL

				-- Create a Primary Key for the PTL_Daily_work table
				ALTER TABLE SCR_Reporting.PTL_Daily_work		-- sets CWT_ID as Primary key
				ADD CONSTRAINT PK_PTL_Daily_work PRIMARY KEY (
						CWT_ID ASC 
						)

				-- DROP PTL_Daily table if it exists
				if object_ID('SCR_Reporting.PTL_Daily') is not null 
				   DROP TABLE SCR_Reporting.PTL_Daily

				-- Rename the SCR_Referrals_Work table as SCR_Referrals
				EXEC sp_rename 'SCR_Reporting.PTL_Daily_Work', 'PTL_Daily'

				-- Rename the Primary Key on SCR_CWT
				EXEC sp_rename 'SCR_Reporting.PTL_Daily.PK_PTL_Daily_work', 'PK_PTL_Daily'

				-- Keep a record of when the "Final" PTL_Daily dataset finished
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" PTL_Daily dataset'
				
			

		END

		-- Create the "Final" reporting PTL_Weekly dataset by copying the records from PTL_Live_work (if we are refreshing the weekly snapshot to match live)
		IF @UpdatePtlSnapshots & 4 = 4
		BEGIN

				-- Keep a record of when the "Final" PTL_Weekly dataset started
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" PTL_Weekly dataset'
				
				-- DROP PTL_Weekly_Work table if it exists
				if object_ID('SCR_Reporting.PTL_Weekly_Work') is not null 
				   DROP TABLE SCR_Reporting.PTL_Weekly_Work

				-- Create the PTL_Weekly_work table from the PTL_Live View
				SELECT		*
				INTO		SCR_Reporting.PTL_Weekly_Work
				FROM		SCR_Reporting.PTL_Live

				--Make CWT_ID not null
				ALTER TABLE SCR_Reporting.PTL_Weekly_work
				ALTER COLUMN CWT_ID varchar(255) NOT NULL

				-- Create a Primary Key for the PTL_Weekly_work table
				ALTER TABLE SCR_Reporting.PTL_Weekly_work		-- sets CWT_ID as Primary key
				ADD CONSTRAINT PK_PTL_Weekly_work PRIMARY KEY (
						CWT_ID ASC 
						)

				-- DROP PTL_Weekly table if it exists
				if object_ID('SCR_Reporting.PTL_Weekly') is not null 
				   DROP TABLE SCR_Reporting.PTL_Weekly

				-- Rename the SCR_Referrals_Work table as SCR_Referrals
				EXEC sp_rename 'SCR_Reporting.PTL_Weekly_Work', 'PTL_Weekly'

				-- Rename the Primary Key on SCR_CWT
				EXEC sp_rename 'SCR_Reporting.PTL_Weekly.PK_PTL_Weekly_work', 'PK_PTL_Weekly'

				-- Keep a record of when the "Final" PTL_Daily dataset finished
				EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Warehouse.uspCreateSomersetReportingData', @Step = '"Final" PTL_Weekly dataset'
				
		END


/************************************************************************************************************************************************************************************************************
-- End
************************************************************************************************************************************************************************************************************/

GO
