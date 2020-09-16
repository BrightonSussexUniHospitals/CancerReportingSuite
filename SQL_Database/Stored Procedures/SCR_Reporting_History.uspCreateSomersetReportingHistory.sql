USE [CancerReporting]
GO
/****** Object:  StoredProcedure [SCR_Reporting_History].[uspCreateSomersetReportingHistory]    Script Date: 03/09/2020 23:43:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 CREATE PROCEDURE [SCR_Reporting_History].[uspCreateSomersetReportingHistory] 
 AS

/******************************************************** © Copyright & Licensing ****************************************************************
© 2020 Perspicacity Ltd & Brighton & Sussex University Hospitals

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

Original Work Created Date:	19/05/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Create and update the archive datasets for all SCR / Somerset reporting
**************************************************************************************************************************************************/


		-- Set up internal variables for use by the procedure
		DECLARE @PtlSnapshotId TABLE (PtlSnapshotId int)

/************************************************************************************************************************************************************************************************************
-- Create the SCR_Reporting_History tables (if they don't already exist)
************************************************************************************************************************************************************************************************************/

		
		-- Create SCR_PTL_SnapshotDates table if it doesn't exist
		IF OBJECT_ID('SCR_Reporting_History.SCR_PTL_SnapshotDates') IS NULL
		BEGIN 
			
			-- Create SCR_PTL_SnapshotDates table
			CREATE TABLE SCR_Reporting_History.SCR_PTL_SnapshotDates(
					PtlSnapshotId int NOT NULL IDENTITY(1,1)
					,PtlSnapshotDate datetime NOT NULL DEFAULT GETDATE()
					,LoadedIntoLTChangeHistory bit NOT NULL DEFAULT 0
					,LoadedIntoStatistics bit NOT NULL DEFAULT 0
					,LoadedIntoLastPtlRecord bit NOT NULL DEFAULT 0
					)

			-- Add a primary key to the SCR_PTL_SnapshotDates table
				ALTER TABLE SCR_Reporting_History.SCR_PTL_SnapshotDates ADD CONSTRAINT PK_SCR_PTL_SnapshotDates PRIMARY KEY CLUSTERED 
					(PtlSnapshotId DESC
					)

				-- Add a unique key for the PtlSnapshotDate
			CREATE UNIQUE NONCLUSTERED INDEX UK_SCR_PTL_SnapshotDates ON SCR_Reporting_History.SCR_PTL_SnapshotDates(
					PtlSnapshotDate ASC
					)

		END

		
		-- Create SCR_PTL_History table if it doesn't exist
		IF OBJECT_ID('SCR_Reporting_History.SCR_PTL_History') IS NULL
		BEGIN 
		
				-- Create SCR_PTL_History table
				CREATE TABLE SCR_Reporting_History.SCR_PTL_History(
					-- Pathway Based ID's
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
					FastDiagOrgDesc varchar(100) NULL,			-- OrganisationSites.Description
					FastDiagCommMethodID int NULL,				-- tblMAIN_REFERRALS.FasterDiagnosisCommunicationMethodID
					FastDiagCommMethodCode varchar(2) NULL,		-- ltblFasterDiagnosisCommunicationMethod.CWTCode
					FastDiagCommMethodDesc varchar(30) NULL,	-- ltblFasterDiagnosisCommunicationMethod.Description
					FastDiagOtherCommMethod varchar(50) NULL,	-- tblMAIN_REFERRALS.FasterDiagnosisOtherCommunicationMethod
					FastDiagInformingCareProfID int NULL,		-- tblMAIN_REFERRALS.FasterDiagnosisInformingCareProfessionalID
					FastDiagInformingCareProfCode varchar(3) NULL,	-- ltblCareProfessional.DataDictionaryCode
					FastDiagInformingCareProfDesc varchar(70) NULL,	-- ltblCareProfessional.Description
					FastDiagOtherCareProf varchar(50) NULL,		-- tblMAIN_REFERRALS.FasterDiagnosisOtherCareProfessional
					-- Referral Diagnoses
					DateDiagnosis smalldatetime NULL,			-- N4_1_DIAGNOSIS_DATE
					AgeAtDiagnosis int NULL,
					DiagnosisCode varchar(5) NULL,				-- L_Diagnosis
					DiagnosisSubCode varchar(5) NULL,			-- N4_2_DIAGNOSIS_CODE
					DiagnosisDesc varchar(150) NULL,
					DiagnosisSubDesc varchar(150) NULL,
					OrgIdDiagnosis int NULL,					-- OrganisationSites.Id
					OrgCodeDiagnosis varchar(5) NULL,			-- L_ORG_CODE_DIAGNOSIS
					OrgDescDiagnosis varchar(250) NULL,			-- OrganisationSites.Description
					SnomedCT_ID int NULL,							-- SNOMed_CT
					SnomedCT_MCode varchar(10),						-- ltblSNOMedCT.Code - derived from tblMAIN_REFERRALS.SNOMed_CT = ltblSNOMedCT.CT_Snomed_ID
					SnomedCT_ConceptID bigint NULL,					-- ltblSNOMedCT.CT_Concept_ID - derived from tblMAIN_REFERRALS.SNOMed_CT = ltblSNOMedCT.CT_Snomed_ID
					SnomedCT_Desc varchar(100) NULL,				-- ltblSNOMedCT.CT_Description - derived from tblMAIN_REFERRALS.SNOMed_CT = ltblSNOMedCT.CT_Snomed_ID
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
					FirstSeenAdjTime int NULL,
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
					-- Pathway Based Provenance
					RefreshMaxActionDate datetime NULL,			-- The date of the last action in the tblAUDIT table when the last reporting data update was performed
					ReferralReportDate datetime NULL,			-- The runtime date when the last reporting data update was performed
					-- CWT Based ID's
					CWTInsertIx int NOT NULL,					-- An identity field to provide us with an initial primary key and provide a reference to the order records were inserted
					OriginalCWTInsertIx int NULL,				-- A record of the CWTInsertIx used in processing incremental records before we append to the SCR_CWT table
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
					-- CWT Based Definitive Treatments (treatments, or potential to treat, with CWT flags)
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
					-- CWT Based Treatment Modality Treatments 
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
					-- CWT Based ChemoRT Treatment Modality Treatments 
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
					-- CWT Based Data Flags
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
					HasTxMod int NULL DEFAULT 0,
					HasChemRtLink int NULL DEFAULT 0,	
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
					-- CWT Based Provenance
					LastCommentUser varchar(50) NULL,
					LastCommentDate datetime NULL,
					CwtReportDate datetime NULL,							-- The runtime date when the last reporting data update was performed
					PtlSnapshotId int NOT NULL,
					-- PTL_Live Snapshot data (that isn't already in CWT or Referrals)
					Pathway varchar(255) NULL,
					TrackingNotes varchar(max) NULL,
					DateLastTracked datetime NULL,
					CommentUser varchar(50) NOT NULL,
					DaysSinceLastTracked int NULL,
					Weighting numeric(2, 1) NOT NULL,
					DaysToNextBreach int NULL,
					NextBreachTarget varchar(17) NOT NULL,
					NextBreachDate smalldatetime NULL,
					DominantColourValue varchar(255) NOT NULL,
					ColourValue2WW varchar(255) NOT NULL,
					ColourValue28Day varchar(255) NOT NULL,
					ColourValue31Day varchar(255) NOT NULL,
					ColourValue62Day varchar(255) NOT NULL,
					DominantColourDesc varchar(255) NOT NULL,
					ColourDesc2WW varchar(255) NOT NULL,
					ColourDesc28Day varchar(255) NOT NULL,
					ColourDesc31Day varchar(255) NOT NULL,
					ColourDesc62Day varchar(255) NOT NULL,
					DominantPriority int NULL,
					Priority2WW int NULL,
					Priority28 int NULL,
					Priority31 int NULL,
					Priority62 int NULL,
					PathwayUpdateEventID int NULL,
					NextActionDesc varchar(75) NULL,
					NextActionSpecificDesc varchar(50) NULL,
					NextActionTargetDate date NULL,
					DaysToNextAction int NULL,
					OwnerDesc varchar(50) NULL,
					AdditionalDetails varchar(55) NULL,
					Escalated int NULL,
					-- TECHNICAL DEBT -- PTL Status
					ReportingPathwayLength int NULL,
					-- TECHNICAL DEBT --CWT Status
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
					SSRS_PTLFlag62 int NULL
				)

				-- Add a primary key to the SCR_PTL_History table
				ALTER TABLE SCR_Reporting_History.SCR_PTL_History ADD  CONSTRAINT PK_SCR_PTL_History PRIMARY KEY CLUSTERED 
				(
					PtlSnapshotId DESC
					,CWT_ID DESC
				)

				-- Add an index for CARE_ID to the SCR_PTL_History table
				CREATE NONCLUSTERED INDEX Ix_CARE_ID ON SCR_Reporting_History.SCR_PTL_History
				(
					CARE_ID DESC
				)

		END


/************************************************************************************************************************************************************************************************************
-- Create / identify the snapshot ID
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when creating a SCR_PTL_History snapshot started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspCreateSomersetReportingHistory', @Step = 'Insert PTL History'
				
		-- Find the snapshot if from the SCR_PTL_SnapshotDates table, if one exists
		DECLARE @LastRefSnapshotDate datetime = (SELECT MAX(ReportDate) FROM SCR_Warehouse.SCR_Referrals)
		DECLARE @ExistingHistorySnapshotId int = (SELECT PtlSnapshotId FROM SCR_Reporting_History.SCR_PTL_SnapshotDates WHERE PtlSnapshotDate = @LastRefSnapshotDate)

		-- If the snapshote date in SCR_CWT already exists in SCR_PTL_SnapshotDates then set the
		-- PtlSnapshotId into the @PtlSnapshotId table ready for processing
		IF @ExistingHistorySnapshotId IS NOT NULL
		BEGIN
			-- Establish a new PtlSnapshotId before the earliest existing snapshot
			INSERT INTO	@PtlSnapshotId (PtlSnapshotId) VALUES (@ExistingHistorySnapshotId)
		END

		
		-- If the snapshot date in SCR_CWT doesn't exist in the SCR_PTL_SnapshotDates table, then
		-- insert the snapshot date into the SCR_PTL_SnapshotDates table and acquire the PtlSnapshotId
		IF @ExistingHistorySnapshotId IS NULL
		BEGIN
			INSERT INTO	SCR_Reporting_History.SCR_PTL_SnapshotDates (PtlSnapshotDate)
			OUTPUT		inserted.PtlSnapshotId INTO @PtlSnapshotId (PtlSnapshotId)
			VALUES		(@LastRefSnapshotDate)
		END
		
/************************************************************************************************************************************************************************************************************
-- Take the snapshot of the final PTL datasets
************************************************************************************************************************************************************************************************************/

		-- Begin a try-catch just to ensure that the transaction is rolled back in the case that the SCR_PTL_History transaction fails
		BEGIN TRY
			
			-- Begin a transaction to process the SCR_PTL_History table in case data needs to be initially deleted because the snapshot date in SCR_CWT already exists 
			-- (to ensure that the deleted data is replaced before the transaction is committed)
			BEGIN TRANSACTION
		
				-- If the snapshot date in SCR_CWT already exists then delete the existing snapshot data
				IF @ExistingHistorySnapshotId IS NOT NULL
				DELETE
				FROM		SCR_Reporting_History.SCR_PTL_History
				WHERE		PtlSnapshotId = @ExistingHistorySnapshotId

				-- Insert PTL History
				INSERT INTO	SCR_Reporting_History.SCR_PTL_History
							(CARE_ID
							,PatientPathwayID
							,PatientPathwayIdIssuer
							,PATIENT_ID
							,MainRefActionId
							,DiagnosisActionId
							,DemographicsActionId
							-- Demographics
							,Forename
							,Surname
							,DateBirth
							,HospitalNumber
							,NHSNumber
							,NHSNumberStatusCode
							,NstsStatus
							,IsTemporaryNHSNumber
							,DeathStatus
							,DateDeath
							,PctCode
							,PctDesc
							,CcgCode
							,CcgDesc
							-- Referral Pathway data
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
							-- Referral Transfer data
							,TransferReason
							,TransferNewRefDate
							,TransferTumourSiteCode
							,TransferTumourSiteDesc
							,TransferActionedDate
							,TransferSourceCareId
							,TransferOrigSourceCareId
							-- Faster Diagnosis
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
							-- Referral Diagnoses
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
							-- Referral Waits data
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
							-- Referral data flags
							,IsBCC
							,IsCwtCancerDiagnosis
							,UnderCancerCareFlag
							-- Pathway Based Provenance
							,RefreshMaxActionDate
							,ReferralReportDate
							-- CWT Based ID's
							,CWTInsertIx
							,OriginalCWTInsertIx
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
							-- CWT Based Definitive Treatments (Treatments, or potential to treat, with CWT flags)
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
							-- CWT Based Treatment modality Treatments
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
							-- CWT Based ChemoRT Treatment modality Treatments
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
							-- CWT Based data flags
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
							-- CWT Wait Calculations
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
							-- CWT Based Provenance
							,LastCommentUser
							,LastCommentDate
							,CwtReportDate
							,PtlSnapshotId
							-- PTL_Live Snapshot data (that isn't already in CWT or Referrals)
							,Pathway
							,TrackingNotes
							,DateLastTracked
							,CommentUser
							,DaysSinceLastTracked
							,Weighting
							,DaysToNextBreach
							,NextBreachTarget
							,NextBreachDate
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
							,PathwayUpdateEventID
							,NextActionDesc
							,NextActionSpecificDesc
							,NextActionTargetDate
							,DaysToNextAction
							,OwnerDesc
							,AdditionalDetails
							,Escalated
							-- TECHNICAL DEBT -- PTL Status
							,ReportingPathwayLength
							-- TECHNICAL DEBT --CWT Status
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
							,SSRS_PTLFlag62)

				SELECT		CARE_ID							=	Referrals.CARE_ID
							,PatientPathwayID				=	Referrals.PatientPathwayID
							,PatientPathwayIdIssuer			=	Referrals.PatientPathwayIdIssuer
							,PATIENT_ID						=	Referrals.PATIENT_ID
							,MainRefActionId				=	Referrals.MainRefActionId
							,DiagnosisActionId				=	Referrals.DiagnosisActionId
							,DemographicsActionId			=	Referrals.DemographicsActionId
							-- Demographics
							,Forename						=	Referrals.Forename
							,Surname						=	Referrals.Surname
							,DateBirth						=	Referrals.DateBirth
							,HospitalNumber					=	Referrals.HospitalNumber
							,NHSNumber						=	Referrals.NHSNumber
							,NHSNumberStatusCode			=	Referrals.NHSNumberStatusCode
							,NstsStatus						=	Referrals.NstsStatus
							,IsTemporaryNHSNumber			=	Referrals.IsTemporaryNHSNumber
							,DeathStatus					=	Referrals.DeathStatus
							,DateDeath						=	Referrals.DateDeath
							,PctCode						=	Referrals.PctCode
							,PctDesc						=	Referrals.PctDesc
							,CcgCode						=	Referrals.CcgCode
							,CcgDesc						=	Referrals.CcgDesc
							-- Referral Pathway data
							,CancerSite						=	Referrals.CancerSite
							,CancerSiteBS					=	Referrals.CancerSiteBS
							,CancerSubSiteCode				=	Referrals.CancerSubSiteCode
							,CancerSubSiteDesc				=	Referrals.CancerSubSiteDesc
							,ReferralCancerSiteCode			=	Referrals.ReferralCancerSiteCode
							,ReferralCancerSiteDesc			=	Referrals.ReferralCancerSiteDesc
							,ReferralCancerSiteBS			=	Referrals.ReferralCancerSiteBS
							,CancerTypeCode					=	Referrals.CancerTypeCode
							,CancerTypeDesc					=	Referrals.CancerTypeDesc
							,PriorityTypeCode				=	Referrals.PriorityTypeCode
							,PriorityTypeDesc				=	Referrals.PriorityTypeDesc
							,SourceReferralCode				=	Referrals.SourceReferralCode
							,SourceReferralDesc				=	Referrals.SourceReferralDesc
							,ReferralMethodCode				=	Referrals.ReferralMethodCode
							,DecisionToReferDate			=	Referrals.DecisionToReferDate
							,TumourStatusCode				=	Referrals.TumourStatusCode
							,TumourStatusDesc				=	Referrals.TumourStatusDesc
							,PatientStatusCode				=	Referrals.PatientStatusCode
							,PatientStatusDesc				=	Referrals.PatientStatusDesc
							,PatientStatusCodeCwt			=	Referrals.PatientStatusCodeCwt
							,PatientStatusDescCwt			=	Referrals.PatientStatusDescCwt
							,ConsultantCode					=	Referrals.ConsultantCode
							,ConsultantName					=	Referrals.ConsultantName
							,InappropriateRef				=	Referrals.InappropriateRef
							-- Referral Transfer data
							,TransferReason					=	Referrals.TransferReason
							,TransferNewRefDate				=	Referrals.TransferNewRefDate
							,TransferTumourSiteCode			=	Referrals.TransferTumourSiteCode
							,TransferTumourSiteDesc			=	Referrals.TransferTumourSiteDesc
							,TransferActionedDate			=	Referrals.TransferActionedDate
							,TransferSourceCareId			=	Referrals.TransferSourceCareId
							,TransferOrigSourceCareId		=	Referrals.TransferOrigSourceCareId
							-- Faster Diagnosis
							,FastDiagInformedDate			=	Referrals.FastDiagInformedDate
							,FastDiagExclDate				=	Referrals.FastDiagExclDate
							,FastDiagCancerSiteID			=	Referrals.FastDiagCancerSiteID
							,FastDiagCancerSiteOverrideID	=	Referrals.FastDiagCancerSiteOverrideID
							,FastDiagCancerSiteCode			=	Referrals.FastDiagCancerSiteCode
							,FastDiagCancerSiteDesc			=	Referrals.FastDiagCancerSiteDesc
							,FastDiagEndReasonID			=	Referrals.FastDiagEndReasonID
							,FastDiagEndReasonCode			=	Referrals.FastDiagEndReasonCode
							,FastDiagEndReasonDesc			=	Referrals.FastDiagEndReasonDesc
							,FastDiagDelayReasonID			=	Referrals.FastDiagDelayReasonID
							,FastDiagDelayReasonCode		=	Referrals.FastDiagDelayReasonCode
							,FastDiagDelayReasonDesc		=	Referrals.FastDiagDelayReasonDesc
							,FastDiagDelayReasonComments	=	Referrals.FastDiagDelayReasonComments
							,FastDiagExclReasonID			=	Referrals.FastDiagExclReasonID
							,FastDiagExclReasonCode			=	Referrals.FastDiagExclReasonCode
							,FastDiagExclReasonDesc			=	Referrals.FastDiagExclReasonDesc
							,FastDiagOrgID					=	Referrals.FastDiagOrgID
							,FastDiagOrgCode				=	Referrals.FastDiagOrgCode
							,FastDiagOrgDesc				=	Referrals.FastDiagOrgDesc
							,FastDiagCommMethodID			=	Referrals.FastDiagCommMethodID
							,FastDiagCommMethodCode			=	Referrals.FastDiagCommMethodCode
							,FastDiagCommMethodDesc			=	Referrals.FastDiagCommMethodDesc
							,FastDiagOtherCommMethod		=	Referrals.FastDiagOtherCommMethod
							,FastDiagInformingCareProfID	=	Referrals.FastDiagInformingCareProfID
							,FastDiagInformingCareProfCode	=	Referrals.FastDiagInformingCareProfCode
							,FastDiagInformingCareProfDesc	=	Referrals.FastDiagInformingCareProfDesc
							,FastDiagOtherCareProf			=	Referrals.FastDiagOtherCareProf
							-- Referral Diagnoses
							,DateDiagnosis					=	Referrals.DateDiagnosis
							,AgeAtDiagnosis					=	Referrals.AgeAtDiagnosis
							,DiagnosisCode					=	Referrals.DiagnosisCode
							,DiagnosisSubCode				=	Referrals.DiagnosisSubCode
							,DiagnosisDesc					=	Referrals.DiagnosisDesc
							,DiagnosisSubDesc				=	Referrals.DiagnosisSubDesc
							,OrgIdDiagnosis					=	Referrals.OrgIdDiagnosis	
							,OrgCodeDiagnosis				=	Referrals.OrgCodeDiagnosis
							,OrgDescDiagnosis				=	Referrals.OrgDescDiagnosis
							,SnomedCT_ID					=	Referrals.SnomedCT_ID
							,SnomedCT_MCode					=	Referrals.SnomedCT_MCode
							,SnomedCT_ConceptID				=	Referrals.SnomedCT_ConceptID
							,SnomedCT_Desc					=	Referrals.SnomedCT_Desc
							,Histology						=	Referrals.Histology
							-- Referral Waits data
							,DateReceipt					=	Referrals.DateReceipt
							,AgeAtReferral					=	Referrals.AgeAtReferral
							,AppointmentCancelledDate		=	Referrals.AppointmentCancelledDate
							,DateConsultantUpgrade			=	Referrals.DateConsultantUpgrade
							,DateFirstSeen					=	Referrals.DateFirstSeen
							,OrgIdUpgrade					=	Referrals.OrgIdUpgrade
							,OrgCodeUpgrade					=	Referrals.OrgCodeUpgrade
							,OrgDescUpgrade					=	Referrals.OrgDescUpgrade
							,OrgIdFirstSeen					=	Referrals.OrgIdFirstSeen
							,OrgCodeFirstSeen				=	Referrals.OrgCodeFirstSeen
							,OrgDescFirstSeen				=	Referrals.OrgDescFirstSeen
							,FirstAppointmentTypeCode		=	Referrals.FirstAppointmentTypeCode
							,FirstAppointmentTypeDesc		=	Referrals.FirstAppointmentTypeDesc
							,FirstAppointmentOffered		=	Referrals.FirstAppointmentOffered
							,ReasonNoAppointmentCode		=	Referrals.ReasonNoAppointmentCode
							,ReasonNoAppointmentDesc		=	Referrals.ReasonNoAppointmentDesc
							,FirstSeenAdjTime				=	Referrals.FirstSeenAdjTime
							,FirstSeenAdjReasonCode			=	Referrals.FirstSeenAdjReasonCode
							,FirstSeenAdjReasonDesc			=	Referrals.FirstSeenAdjReasonDesc
							,FirstSeenDelayReasonCode		=	Referrals.FirstSeenDelayReasonCode
							,FirstSeenDelayReasonDesc		=	Referrals.FirstSeenDelayReasonDesc
							,FirstSeenDelayReasonComment	=	Referrals.FirstSeenDelayReasonComment
							,DTTAdjTime						=	Referrals.DTTAdjTime
							,DTTAdjReasonCode				=	Referrals.DTTAdjReasonCode
							,DTTAdjReasonDesc				=	Referrals.DTTAdjReasonDesc
							-- Referral data flags
							,IsBCC							=	Referrals.IsBCC
							,IsCwtCancerDiagnosis			=	Referrals.IsCwtCancerDiagnosis
							,UnderCancerCareFlag			=	Referrals.UnderCancerCareFlag
							-- Pathway Based Provenance
							,RefreshMaxActionDate			=	Referrals.RefreshMaxActionDate
							,ReferralReportDate				=	Referrals.ReportDate
							-- CWT Based ID's
							,CWTInsertIx					=	CWT.CWTInsertIx
							,OriginalCWTInsertIx			=	CWT.OriginalCWTInsertIx
							,CWT_ID							=	CWT.CWT_ID
							,Tx_ID							=	CWT.Tx_ID
							,TREATMENT_ID					=	CWT.TREATMENT_ID
							,TREAT_ID						=	CWT.TREAT_ID
							,CHEMO_ID						=	CWT.CHEMO_ID
							,TELE_ID						=	CWT.TELE_ID
							,PALL_ID						=	CWT.PALL_ID
							,BRACHY_ID						=	CWT.BRACHY_ID
							,OTHER_ID						=	CWT.OTHER_ID
							,SURGERY_ID						=	CWT.SURGERY_ID
							,MONITOR_ID						=	CWT.MONITOR_ID
							,ChemoActionId					=	CWT.ChemoActionId
							,TeleActionId					=	CWT.TeleActionId
							,PallActionId					=	CWT.PallActionId
							,BrachyActionId					=	CWT.BrachyActionId
							,OtherActionId					=	CWT.OtherActionId
							,SurgeryActionId				=	CWT.SurgeryActionId
							,MonitorActionId				=	CWT.MonitorActionId
							-- CWT Based Definitive Treatments (Treatments, or potential to treat, with CWT flags)
							,DeftTreatmentEventCode			=	CWT.DeftTreatmentEventCode
							,DeftTreatmentEventDesc			=	CWT.DeftTreatmentEventDesc
							,DeftTreatmentCode				=	CWT.DeftTreatmentCode
							,DeftTreatmentDesc				=	CWT.DeftTreatmentDesc
							,DeftTreatmentSettingCode		=	CWT.DeftTreatmentSettingCode
							,DeftTreatmentSettingDesc		=	CWT.DeftTreatmentSettingDesc
							,DeftDateDecisionTreat			=	CWT.DeftDateDecisionTreat
							,DeftDateTreatment				=	CWT.DeftDateTreatment
							,DeftDTTAdjTime					=	CWT.DeftDTTAdjTime
							,DeftDTTAdjReasonCode			=	CWT.DeftDTTAdjReasonCode
							,DeftDTTAdjReasonDesc			=	CWT.DeftDTTAdjReasonDesc
							,DeftOrgIdDecisionTreat			=	CWT.DeftOrgIdDecisionTreat
							,DeftOrgCodeDecisionTreat		=	CWT.DeftOrgCodeDecisionTreat
							,DeftOrgDescDecisionTreat		=	CWT.DeftOrgDescDecisionTreat
							,DeftOrgIdTreatment				=	CWT.DeftOrgIdTreatment
							,DeftOrgCodeTreatment			=	CWT.DeftOrgCodeTreatment
							,DeftOrgDescTreatment			=	CWT.DeftOrgDescTreatment
							,DeftDefinitiveTreatment		=	CWT.DeftDefinitiveTreatment
							,DeftChemoRT					=	CWT.DeftChemoRT
							-- CWT Based Treatment modality Treatments
							,TxModTreatmentEventCode		=	CWT.TxModTreatmentEventCode
							,TxModTreatmentEventDesc		=	CWT.TxModTreatmentEventDesc
							,TxModTreatmentCode				=	CWT.TxModTreatmentCode
							,TxModTreatmentDesc				=	CWT.TxModTreatmentDesc
							,TxModTreatmentSettingCode		=	CWT.TxModTreatmentSettingCode
							,TxModTreatmentSettingDesc		=	CWT.TxModTreatmentSettingDesc
							,TxModDateDecisionTreat			=	CWT.TxModDateDecisionTreat
							,TxModDateTreatment				=	CWT.TxModDateTreatment
							,TxModOrgIdDecisionTreat		=	CWT.TxModOrgIdDecisionTreat
							,TxModOrgCodeDecisionTreat		=	CWT.TxModOrgCodeDecisionTreat
							,TxModOrgDescDecisionTreat		=	CWT.TxModOrgDescDecisionTreat
							,TxModOrgIdTreatment			=	CWT.TxModOrgIdTreatment
							,TxModOrgCodeTreatment			=	CWT.TxModOrgCodeTreatment
							,TxModOrgDescTreatment			=	CWT.TxModOrgDescTreatment
							,TxModDefinitiveTreatment		=	CWT.TxModDefinitiveTreatment
							,TxModChemoRadio				=	CWT.TxModChemoRadio
							,TxModChemoRT					=	CWT.TxModChemoRT
							,TxModModalitySubCode			=	CWT.TxModModalitySubCode
							,TxModRadioSurgery				=	CWT.TxModRadioSurgery
							-- CWT Based ChemoRT Treatment modality Treatments
							,ChemRtLinkTreatmentEventCode	=	CWT.ChemRtLinkTreatmentEventCode
							,ChemRtLinkTreatmentEventDesc	=	CWT.ChemRtLinkTreatmentEventDesc
							,ChemRtLinkTreatmentCode		=	CWT.ChemRtLinkTreatmentCode
							,ChemRtLinkTreatmentDesc		=	CWT.ChemRtLinkTreatmentDesc
							,ChemRtLinkTreatmentSettingCode	=	CWT.ChemRtLinkTreatmentSettingCode
							,ChemRtLinkTreatmentSettingDesc	=	CWT.ChemRtLinkTreatmentSettingDesc
							,ChemRtLinkDateDecisionTreat	=	CWT.ChemRtLinkDateDecisionTreat
							,ChemRtLinkDateTreatment		=	CWT.ChemRtLinkDateTreatment
							,ChemRtLinkOrgIdDecisionTreat	=	CWT.ChemRtLinkOrgIdDecisionTreat
							,ChemRtLinkOrgCodeDecisionTreat	=	CWT.ChemRtLinkOrgCodeDecisionTreat
							,ChemRtLinkOrgDescDecisionTreat	=	CWT.ChemRtLinkOrgDescDecisionTreat
							,ChemRtLinkOrgIdTreatment		=	CWT.ChemRtLinkOrgIdTreatment
							,ChemRtLinkOrgCodeTreatment		=	CWT.ChemRtLinkOrgCodeTreatment
							,ChemRtLinkOrgDescTreatment		=	CWT.ChemRtLinkOrgDescTreatment
							,ChemRtLinkDefinitiveTreatment	=	CWT.ChemRtLinkDefinitiveTreatment
							,ChemRtLinkChemoRadio			=	CWT.ChemRtLinkChemoRadio
							,ChemRtLinkModalitySubCode		=	CWT.ChemRtLinkModalitySubCode
							,ChemRtLinkRadioSurgery			=	CWT.ChemRtLinkRadioSurgery
							-- CWT Based data flags
							,cwtFlag2WW						=	CWT.cwtFlag2WW
							,cwtFlag28						=	CWT.cwtFlag28
							,cwtFlag31						=	CWT.cwtFlag31
							,cwtFlag62						=	CWT.cwtFlag62
							,cwtType2WW						=	CWT.cwtType2WW
							,cwtType28						=	CWT.cwtType28
							,cwtType31						=	CWT.cwtType31
							,cwtType62						=	CWT.cwtType62
							,cwtReason2WW					=	CWT.cwtReason2WW
							,cwtReason28					=	CWT.cwtReason28
							,cwtReason31					=	CWT.cwtReason31
							,cwtReason62					=	CWT.cwtReason62
							,HasTxMod						=	CWT.HasTxMod
							,HasChemRtLink					=	CWT.HasChemRtLink
							-- CWT Wait Calculations
							,ClockStartDate2WW				=	CWT.ClockStartDate2WW
							,ClockStartDate28				=	CWT.ClockStartDate28
							,ClockStartDate31				=	CWT.ClockStartDate31
							,ClockStartDate62				=	CWT.ClockStartDate62
							,AdjTime2WW						=	CWT.AdjTime2WW
							,AdjTime28						=	CWT.AdjTime28
							,AdjTime31						=	CWT.AdjTime31
							,AdjTime62						=	CWT.AdjTime62
							,TargetDate2WW					=	CWT.TargetDate2WW
							,TargetDate28					=	CWT.TargetDate28
							,TargetDate31					=	CWT.TargetDate31
							,TargetDate62					=	CWT.TargetDate62
							,DaysTo2WWBreach				=	CWT.DaysTo2WWBreach
							,DaysTo28DayBreach				=	CWT.DaysTo28DayBreach
							,DaysTo31DayBreach				=	CWT.DaysTo31DayBreach
							,DaysTo62DayBreach				=	CWT.DaysTo62DayBreach
							,ClockStopDate2WW				=	CWT.ClockStopDate2WW
							,ClockStopDate28				=	CWT.ClockStopDate28
							,ClockStopDate31				=	CWT.ClockStopDate31
							,ClockStopDate62				=	CWT.ClockStopDate62
							,Waitingtime2WW					=	CWT.Waitingtime2WW
							,Waitingtime28					=	CWT.Waitingtime28
							,Waitingtime31					=	CWT.Waitingtime31
							,Waitingtime62					=	CWT.Waitingtime62
							,Breach2WW						=	CWT.Breach2WW
							,Breach28						=	CWT.Breach28
							,Breach31						=	CWT.Breach31
							,Breach62						=	CWT.Breach62
							,DaysTo62DayBreachNoDTT			=	CWT.DaysTo62DayBreachNoDTT
							,Treated7Days					=	CWT.Treated7Days
							,Treated7Days62Days				=	CWT.Treated7Days62Days
							,FutureAchieve62Days			=	CWT.FutureAchieve62Days
							,FutureFail62Days				=	CWT.FutureFail62Days
							,ActualWaitDTTTreatment			=	CWT.ActualWaitDTTTreatment
							,DTTTreated7Days				=	CWT.DTTTreated7Days
							,Treated7Days31Days				=	CWT.Treated7Days31Days
							,Treated7DaysBreach31Days		=	CWT.Treated7DaysBreach31Days
							,FutureAchieve31Days			=	CWT.FutureAchieve31Days
							,FutureFail31Days				=	CWT.FutureFail31Days
							,FutureDTT						=	CWT.FutureDTT
							,NoDTTDate						=	CWT.NoDTTDate
							-- CWT Based Provenance
							,LastCommentUser				=	CWT.LastCommentUser
							,LastCommentDate				=	CWT.LastCommentDate
							,CwtReportDate					=	CWT.ReportDate
							,PtlSnapshotId					=	PtlSnapshotId.PtlSnapshotId
							-- PTL_Live Snapshot data (that isn't already in CWT or Referrals)
							,Pathway						=	PTL_Live.Pathway
							,TrackingNotes					=	PTL_Live.TrackingNotes
							,DateLastTracked				=	PTL_Live.DateLastTracked
							,CommentUser					=	PTL_Live.CommentUser
							,DaysSinceLastTracked			=	PTL_Live.DaysSinceLastTracked
							,Weighting						=	PTL_Live.Weighting
							,DaysToNextBreach				=	PTL_Live.DaysToNextBreach
							,NextBreachTarget				=	PTL_Live.NextBreachTarget
							,NextBreachDate					=	PTL_Live.NextBreachDate
							,DominantColourValue			=	PTL_Live.DominantColourValue
							,ColourValue2WW					=	PTL_Live.ColourValue2WW
							,ColourValue28Day				=	PTL_Live.ColourValue28Day
							,ColourValue31Day				=	PTL_Live.ColourValue31Day
							,ColourValue62Day				=	PTL_Live.ColourValue62Day
							,DominantColourDesc				=	PTL_Live.DominantColourDesc
							,ColourDesc2WW					=	PTL_Live.ColourDesc2WW
							,ColourDesc28Day				=	PTL_Live.ColourDesc28Day
							,ColourDesc31Day				=	PTL_Live.ColourDesc31Day
							,ColourDesc62Day				=	PTL_Live.ColourDesc62Day
							,DominantPriority				=	PTL_Live.DominantPriority
							,Priority2WW					=	PTL_Live.Priority2WW
							,Priority28						=	PTL_Live.Priority28
							,Priority31						=	PTL_Live.Priority31
							,Priority62						=	PTL_Live.Priority62
							,PathwayUpdateEventID			=	PTL_Live.PathwayUpdateEventID
							,NextActionDesc					=	PTL_Live.NextActionDesc
							,NextActionSpecificDesc			=	PTL_Live.NextActionSpecificDesc
							,NextActionTargetDate			=	PTL_Live.NextActionTargetDate
							,DaysToNextAction				=	PTL_Live.DaysToNextAction
							,OwnerDesc						=	PTL_Live.OwnerDesc
							,AdditionalDetails				=	PTL_Live.AdditionalDetails
							,Escalated						=	PTL_Live.Escalated
							-- TECHNICAL DEBT -- PTL Status
							,ReportingPathwayLength			=	PTL_Live.ReportingPathwayLength
							-- TECHNICAL DEBT --CWT Status
							,DominantCWTStatusCode 			=	PTL_Live.DominantCWTStatusCode 
							,DominantCWTStatusDesc			=	PTL_Live.DominantCWTStatusDesc
							,CWTStatusCode2WW				=	PTL_Live.CWTStatusCode2WW
							,CWTStatusDesc2WWL				=	PTL_Live.CWTStatusDesc2WW
							,CWTStatusCode28 				=	PTL_Live.CWTStatusCode28 
							,CWTStatusDesc28 				=	PTL_Live.CWTStatusDesc28 
							,CWTStatusCode31 				=	PTL_Live.CWTStatusCode31 
							,CWTStatusDesc31 				=	PTL_Live.CWTStatusDesc31 
							,CWTStatusCode62 				=	PTL_Live.CWTStatusCode62 
							,CWTStatusDesc62 				=	PTL_Live.CWTStatusDesc62 
							,SSRS_PTLFlag62					=	PTL_Live.SSRS_PTLFlag62

				FROM		SCR_Warehouse.SCR_Referrals Referrals
				INNER JOIN	SCR_Warehouse.SCR_CWT CWT
								ON	Referrals.CARE_ID = CWT.CARE_ID
				LEFT JOIN	SCR_Reporting.PTL_Live PTL_Live
								ON	CWT.CWT_ID = PTL_Live.CWT_ID
				CROSS JOIN	@PtlSnapshotId PtlSnapshotId

			-- If there have been no errors up to this point then commit the transaction
			COMMIT TRANSACTION

		-- End the try
		END TRY
		
		-- Catch errors that may have occured during the attempted transaction to ensure that the transaction is rolled back
		BEGIN CATCH

			IF @@TRANCOUNT > 0
				PRINT 'Rolling back because of error in processing SCR_PTL_History'
				ROLLBACK TRANSACTION
 
			SELECT ERROR_NUMBER() AS ErrorNumber
			SELECT ERROR_MESSAGE() AS ErrorMessage
 
		END CATCH	
		
		-- Keep a record of when creating a SCR_PTL_History snapshot dataset finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspCreateSomersetReportingHistory', @Step = 'Insert PTL History'
		
GO
