SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [SCR_Reporting_History].[uspUpdateLastPTL_Record] 
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

Original Work Created Date:	08/07/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Keep a copy of the most recent record for each pathway
**************************************************************************************************************************************************/

-- Test me
-- EXEC SCR_Reporting_History.uspUpdateLastPTL_Record

/************************************************************************************************************************************************************************************************************
-- Create the SCR_Reporting_History tables (if they don't already exist)
************************************************************************************************************************************************************************************************************/

		-- Create SCR_LastPTL_Record table if it doesn't exist
		IF OBJECT_ID('SCR_Reporting_History.SCR_LastPTL_Record') IS NULL
		BEGIN 
		
				-- Create SCR_LastPTL_Record table
				CREATE TABLE SCR_Reporting_History.SCR_LastPTL_Record(
					InLastRefresh bit NOT NULL DEFAULT 1,
					PtlSnapshotId int NOT NULL,
					CWT_ID varchar(255) NOT NULL DEFAULT '',	-- Composite Key for the CWT record (careid, treatmentid, all modality ids)
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
					FDPlannedInterval bit NULL,					-- tblMAIN_REFERRALS.FDPlannedInterval
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
					-- PTL_Daily Snapshot data (that isn't already in CWT or Referrals)
					Pathway varchar(255) NULL,
					TrackingNotes varchar(max) NULL,
					DateLastTracked datetime NULL,
					CommentUser varchar(50) NULL,
					DaysSinceLastTracked int NULL,
					Weighting numeric(2, 1) NULL,
					DaysToNextBreach int NULL,
					NextBreachTarget varchar(17) NULL,
					NextBreachDate smalldatetime NULL,
					DominantColourValue varchar(255) NULL,
					ColourValue2WW varchar(255)  NULL,
					ColourValue28Day varchar(255) NULL,
					ColourValue31Day varchar(255) NULL,
					ColourValue62Day varchar(255) NULL,
					DominantColourDesc varchar(255) NULL,
					ColourDesc2WW varchar(255) NULL,
					ColourDesc28Day varchar(255) NULL,
					ColourDesc31Day varchar(255) NULL,
					ColourDesc62Day varchar(255) NULL,
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

				-- Add a primary key to the SCR_LastPTL_Record table
				ALTER TABLE SCR_Reporting_History.SCR_LastPTL_Record ADD  CONSTRAINT PK_SCR_LastPTL_Record PRIMARY KEY CLUSTERED 
				(
					CWT_ID DESC
				)

				-- Add an index for CARE_ID to the SCR_LastPTL_Record table
				CREATE NONCLUSTERED INDEX Ix_CARE_ID ON SCR_Reporting_History.SCR_LastPTL_Record
				(
					CARE_ID DESC
				)

		END


/************************************************************************************************************************************************************************************************************
-- Delete all records currently on the PTL (leaving behind all records that are no longer on the PTL) and then re-add the records on the PTL (to refresh their data)
************************************************************************************************************************************************************************************************************/

		-- Keep a record of when creating the SCR_LastPTL_Record snapshot dataset started
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'SCR_Reporting_History.uspUpdateLastPTL_Record', @Step = 'Create last PTL record for each pathway'
		
		-- Begin a try-catch just to ensure that the transaction is rolled back in the case that the SCR_LastPTL_Record transaction fails
		BEGIN TRY
			
			-- Begin a transaction to process the SCR_LastPTL_Record table (to ensure that the deleted data is replaced before the transaction is committed)
			BEGIN TRANSACTION
				
				-- Drop the #SnapshotIx table if it exists
				IF OBJECT_ID('tempdb..#SnapshotIx') IS NOT NULL
				DROP TABLE #SnapshotIx
				
				-- Create the table that orders the PTL Snapshot Dates
				SELECT		sd.PtlSnapshotId
							,sd.LoadedIntoLastPtlRecord
							,ROW_NUMBER() OVER (ORDER BY sd.PtlSnapshotDate ASC) AS PtlSnapshotIx
				INTO		#SnapshotIx
				FROM		SCR_Reporting_History.SCR_PTL_SnapshotDates sd
		
				-- Drop the #MostRecent_LastPTL_Record table if it exists
				IF OBJECT_ID('tempdb..#MostRecent_LastPTL_Record') IS NOT NULL
				DROP TABLE #MostRecent_LastPTL_Record
				
				-- Find the most recently loaded snapshot for each CWT_ID in the SCR_LastPTL_Record table
				SELECT		LastPtlRec.CWT_ID
							,MAX(snap.PtlSnapshotIx) AS MaxPtlSnapshotIx
				INTO		#MostRecent_LastPTL_Record
				FROM		SCR_Reporting_History.SCR_LastPTL_Record LastPtlRec
				INNER JOIN	#SnapshotIx snap
								ON	LastPtlRec.PtlSnapshotId = snap.PtlSnapshotId
				GROUP BY	LastPtlRec.CWT_ID
		
				-- Drop the #MostRecent_PTL_History table if it exists
				IF OBJECT_ID('tempdb..#MostRecent_PTL_History') IS NOT NULL
				DROP TABLE #MostRecent_PTL_History

				-- Find the most recently loaded snapshot for each CWT_ID in the SCR_PTL_History table
				SELECT		Hist.CWT_ID
							,MAX(snap.PtlSnapshotIx) AS MaxPtlSnapshotIx
				INTO		#MostRecent_PTL_History
				FROM		SCR_Reporting_History.SCR_PTL_History Hist
				INNER JOIN	#SnapshotIx snap
								ON	Hist.PtlSnapshotId = snap.PtlSnapshotId
				GROUP BY	Hist.CWT_ID
		
				-- Drop the #MoreRecentSnapshot table if it exists
				IF OBJECT_ID('tempdb..#MoreRecentSnapshot') IS NOT NULL
				DROP TABLE #MoreRecentSnapshot

				-- Identify records where there is a more recent snapshot in the SCR_PTL_History table
				SELECT		Hist.CWT_ID
							,Hist.MaxPtlSnapshotIx
				INTO		#MoreRecentSnapshot
				FROM		#MostRecent_PTL_History Hist
				LEFT JOIN	#MostRecent_LastPTL_Record LastPTL
								ON	Hist.CWT_ID = LastPTL.CWT_ID
				WHERE		Hist.MaxPtlSnapshotIx > LastPTL.MaxPtlSnapshotIx
				OR			LastPTL.CWT_ID IS NULL
				
				-- Delete all records with a more recent record in the SCR_LastPTL_Record table (leaving behind all records that have not further records in the SCR_LastPTL_Record table)
				DELETE
				FROM		LastPTL
				FROM		SCR_Reporting_History.SCR_LastPTL_Record LastPTL
				INNER JOIN	#MoreRecentSnapshot MoreRecent
								ON	LastPTL.CWT_ID = MoreRecent.CWT_ID

				-- Mark all remaining records as no longer being in the last refresh
				UPDATE		SCR_Reporting_History.SCR_LastPTL_Record
				SET			InLastRefresh = 0

				-- Insert PTL History
				INSERT INTO	SCR_Reporting_History.SCR_LastPTL_Record
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
							,FDPlannedInterval
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

				SELECT		CARE_ID							=	Hist.CARE_ID
							,PatientPathwayID				=	Hist.PatientPathwayID
							,PatientPathwayIdIssuer			=	Hist.PatientPathwayIdIssuer
							,PATIENT_ID						=	Hist.PATIENT_ID
							,MainRefActionId				=	Hist.MainRefActionId
							,DiagnosisActionId				=	Hist.DiagnosisActionId
							,DemographicsActionId			=	Hist.DemographicsActionId
							-- Demographics
							,Forename						=	Hist.Forename
							,Surname						=	Hist.Surname
							,DateBirth						=	Hist.DateBirth
							,HospitalNumber					=	Hist.HospitalNumber
							,NHSNumber						=	Hist.NHSNumber
							,NHSNumberStatusCode			=	Hist.NHSNumberStatusCode
							,NstsStatus						=	Hist.NstsStatus
							,IsTemporaryNHSNumber			=	Hist.IsTemporaryNHSNumber
							,DeathStatus					=	Hist.DeathStatus
							,DateDeath						=	Hist.DateDeath
							,PctCode						=	Hist.PctCode
							,PctDesc						=	Hist.PctDesc
							,CcgCode						=	Hist.CcgCode
							,CcgDesc						=	Hist.CcgDesc
							-- Referral Pathway data
							,CancerSite						=	Hist.CancerSite
							,CancerSiteBS					=	Hist.CancerSiteBS
							,CancerSubSiteCode				=	Hist.CancerSubSiteCode
							,CancerSubSiteDesc				=	Hist.CancerSubSiteDesc
							,ReferralCancerSiteCode			=	Hist.ReferralCancerSiteCode
							,ReferralCancerSiteDesc			=	Hist.ReferralCancerSiteDesc
							,ReferralCancerSiteBS			=	Hist.ReferralCancerSiteBS
							,CancerTypeCode					=	Hist.CancerTypeCode
							,CancerTypeDesc					=	Hist.CancerTypeDesc
							,PriorityTypeCode				=	Hist.PriorityTypeCode
							,PriorityTypeDesc				=	Hist.PriorityTypeDesc
							,SourceReferralCode				=	Hist.SourceReferralCode
							,SourceReferralDesc				=	Hist.SourceReferralDesc
							,ReferralMethodCode				=	Hist.ReferralMethodCode
							,DecisionToReferDate			=	Hist.DecisionToReferDate
							,TumourStatusCode				=	Hist.TumourStatusCode
							,TumourStatusDesc				=	Hist.TumourStatusDesc
							,PatientStatusCode				=	Hist.PatientStatusCode
							,PatientStatusDesc				=	Hist.PatientStatusDesc
							,PatientStatusCodeCwt			=	Hist.PatientStatusCodeCwt
							,PatientStatusDescCwt			=	Hist.PatientStatusDescCwt
							,ConsultantCode					=	Hist.ConsultantCode
							,ConsultantName					=	Hist.ConsultantName
							,InappropriateRef				=	Hist.InappropriateRef
							-- Referral Transfer data
							,TransferReason					=	Hist.TransferReason
							,TransferNewRefDate				=	Hist.TransferNewRefDate
							,TransferTumourSiteCode			=	Hist.TransferTumourSiteCode
							,TransferTumourSiteDesc			=	Hist.TransferTumourSiteDesc
							,TransferActionedDate			=	Hist.TransferActionedDate
							,TransferSourceCareId			=	Hist.TransferSourceCareId
							,TransferOrigSourceCareId		=	Hist.TransferOrigSourceCareId
							-- Faster Diagnosis
							,FastDiagInformedDate			=	Hist.FastDiagInformedDate
							,FastDiagExclDate				=	Hist.FastDiagExclDate
							,FastDiagCancerSiteID			=	Hist.FastDiagCancerSiteID
							,FastDiagCancerSiteOverrideID	=	Hist.FastDiagCancerSiteOverrideID
							,FastDiagCancerSiteCode			=	Hist.FastDiagCancerSiteCode
							,FastDiagCancerSiteDesc			=	Hist.FastDiagCancerSiteDesc
							,FastDiagEndReasonID			=	Hist.FastDiagEndReasonID
							,FastDiagEndReasonCode			=	Hist.FastDiagEndReasonCode
							,FastDiagEndReasonDesc			=	Hist.FastDiagEndReasonDesc
							,FastDiagDelayReasonID			=	Hist.FastDiagDelayReasonID
							,FastDiagDelayReasonCode		=	Hist.FastDiagDelayReasonCode
							,FastDiagDelayReasonDesc		=	Hist.FastDiagDelayReasonDesc
							,FastDiagDelayReasonComments	=	Hist.FastDiagDelayReasonComments
							,FastDiagExclReasonID			=	Hist.FastDiagExclReasonID
							,FastDiagExclReasonCode			=	Hist.FastDiagExclReasonCode
							,FastDiagExclReasonDesc			=	Hist.FastDiagExclReasonDesc
							,FastDiagOrgID					=	Hist.FastDiagOrgID
							,FastDiagOrgCode				=	Hist.FastDiagOrgCode
							,FastDiagOrgDesc				=	Hist.FastDiagOrgDesc
							,FastDiagCommMethodID			=	Hist.FastDiagCommMethodID
							,FastDiagCommMethodCode			=	Hist.FastDiagCommMethodCode
							,FastDiagCommMethodDesc			=	Hist.FastDiagCommMethodDesc
							,FastDiagOtherCommMethod		=	Hist.FastDiagOtherCommMethod
							,FastDiagInformingCareProfID	=	Hist.FastDiagInformingCareProfID
							,FastDiagInformingCareProfCode	=	Hist.FastDiagInformingCareProfCode
							,FastDiagInformingCareProfDesc	=	Hist.FastDiagInformingCareProfDesc
							,FastDiagOtherCareProf			=	Hist.FastDiagOtherCareProf
							,FDPlannedInterval				=	Hist.FDPlannedInterval
							-- Referral Diagnoses
							,DateDiagnosis					=	Hist.DateDiagnosis
							,AgeAtDiagnosis					=	Hist.AgeAtDiagnosis
							,DiagnosisCode					=	Hist.DiagnosisCode
							,DiagnosisSubCode				=	Hist.DiagnosisSubCode
							,DiagnosisDesc					=	Hist.DiagnosisDesc
							,DiagnosisSubDesc				=	Hist.DiagnosisSubDesc
							,OrgIdDiagnosis					=	Hist.OrgIdDiagnosis	
							,OrgCodeDiagnosis				=	Hist.OrgCodeDiagnosis
							,OrgDescDiagnosis				=	Hist.OrgDescDiagnosis
							,SnomedCT_ID					=	Hist.SnomedCT_ID
							,SnomedCT_MCode					=	Hist.SnomedCT_MCode
							,SnomedCT_ConceptID				=	Hist.SnomedCT_ConceptID
							,SnomedCT_Desc					=	Hist.SnomedCT_Desc
							,Histology						=	Hist.Histology
							-- Referral Waits data
							,DateReceipt					=	Hist.DateReceipt
							,AgeAtReferral					=	Hist.AgeAtReferral
							,AppointmentCancelledDate		=	Hist.AppointmentCancelledDate
							,DateConsultantUpgrade			=	Hist.DateConsultantUpgrade
							,DateFirstSeen					=	Hist.DateFirstSeen
							,OrgIdUpgrade					=	Hist.OrgIdUpgrade
							,OrgCodeUpgrade					=	Hist.OrgCodeUpgrade
							,OrgDescUpgrade					=	Hist.OrgDescUpgrade
							,OrgIdFirstSeen					=	Hist.OrgIdFirstSeen
							,OrgCodeFirstSeen				=	Hist.OrgCodeFirstSeen
							,OrgDescFirstSeen				=	Hist.OrgDescFirstSeen
							,FirstAppointmentTypeCode		=	Hist.FirstAppointmentTypeCode
							,FirstAppointmentTypeDesc		=	Hist.FirstAppointmentTypeDesc
							,FirstAppointmentOffered		=	Hist.FirstAppointmentOffered
							,ReasonNoAppointmentCode		=	Hist.ReasonNoAppointmentCode
							,ReasonNoAppointmentDesc		=	Hist.ReasonNoAppointmentDesc
							,FirstSeenAdjTime				=	Hist.FirstSeenAdjTime
							,FirstSeenAdjReasonCode			=	Hist.FirstSeenAdjReasonCode
							,FirstSeenAdjReasonDesc			=	Hist.FirstSeenAdjReasonDesc
							,FirstSeenDelayReasonCode		=	Hist.FirstSeenDelayReasonCode
							,FirstSeenDelayReasonDesc		=	Hist.FirstSeenDelayReasonDesc
							,FirstSeenDelayReasonComment	=	Hist.FirstSeenDelayReasonComment
							,DTTAdjTime						=	Hist.DTTAdjTime
							,DTTAdjReasonCode				=	Hist.DTTAdjReasonCode
							,DTTAdjReasonDesc				=	Hist.DTTAdjReasonDesc
							-- Referral data flags
							,IsBCC							=	Hist.IsBCC
							,IsCwtCancerDiagnosis			=	Hist.IsCwtCancerDiagnosis
							,UnderCancerCareFlag			=	Hist.UnderCancerCareFlag
							-- Pathway Based Provenance
							,RefreshMaxActionDate			=	Hist.RefreshMaxActionDate
							,ReferralReportDate				=	Hist.ReferralReportDate
							-- CWT Based ID's
							,CWTInsertIx					=	Hist.CWTInsertIx
							,OriginalCWTInsertIx			=	Hist.OriginalCWTInsertIx
							,CWT_ID							=	Hist.CWT_ID
							,Tx_ID							=	Hist.Tx_ID
							,TREATMENT_ID					=	Hist.TREATMENT_ID
							,TREAT_ID						=	Hist.TREAT_ID
							,CHEMO_ID						=	Hist.CHEMO_ID
							,TELE_ID						=	Hist.TELE_ID
							,PALL_ID						=	Hist.PALL_ID
							,BRACHY_ID						=	Hist.BRACHY_ID
							,OTHER_ID						=	Hist.OTHER_ID
							,SURGERY_ID						=	Hist.SURGERY_ID
							,MONITOR_ID						=	Hist.MONITOR_ID
							,ChemoActionId					=	Hist.ChemoActionId
							,TeleActionId					=	Hist.TeleActionId
							,PallActionId					=	Hist.PallActionId
							,BrachyActionId					=	Hist.BrachyActionId
							,OtherActionId					=	Hist.OtherActionId
							,SurgeryActionId				=	Hist.SurgeryActionId
							,MonitorActionId				=	Hist.MonitorActionId
							-- CWT Based Definitive Treatments (Treatments, or potential to treat, with CWT flags)
							,DeftTreatmentEventCode			=	Hist.DeftTreatmentEventCode
							,DeftTreatmentEventDesc			=	Hist.DeftTreatmentEventDesc
							,DeftTreatmentCode				=	Hist.DeftTreatmentCode
							,DeftTreatmentDesc				=	Hist.DeftTreatmentDesc
							,DeftTreatmentSettingCode		=	Hist.DeftTreatmentSettingCode
							,DeftTreatmentSettingDesc		=	Hist.DeftTreatmentSettingDesc
							,DeftDateDecisionTreat			=	Hist.DeftDateDecisionTreat
							,DeftDateTreatment				=	Hist.DeftDateTreatment
							,DeftDTTAdjTime					=	Hist.DeftDTTAdjTime
							,DeftDTTAdjReasonCode			=	Hist.DeftDTTAdjReasonCode
							,DeftDTTAdjReasonDesc			=	Hist.DeftDTTAdjReasonDesc
							,DeftOrgIdDecisionTreat			=	Hist.DeftOrgIdDecisionTreat
							,DeftOrgCodeDecisionTreat		=	Hist.DeftOrgCodeDecisionTreat
							,DeftOrgDescDecisionTreat		=	Hist.DeftOrgDescDecisionTreat
							,DeftOrgIdTreatment				=	Hist.DeftOrgIdTreatment
							,DeftOrgCodeTreatment			=	Hist.DeftOrgCodeTreatment
							,DeftOrgDescTreatment			=	Hist.DeftOrgDescTreatment
							,DeftDefinitiveTreatment		=	Hist.DeftDefinitiveTreatment
							,DeftChemoRT					=	Hist.DeftChemoRT
							-- CWT Based Treatment modality Treatments
							,TxModTreatmentEventCode		=	Hist.TxModTreatmentEventCode
							,TxModTreatmentEventDesc		=	Hist.TxModTreatmentEventDesc
							,TxModTreatmentCode				=	Hist.TxModTreatmentCode
							,TxModTreatmentDesc				=	Hist.TxModTreatmentDesc
							,TxModTreatmentSettingCode		=	Hist.TxModTreatmentSettingCode
							,TxModTreatmentSettingDesc		=	Hist.TxModTreatmentSettingDesc
							,TxModDateDecisionTreat			=	Hist.TxModDateDecisionTreat
							,TxModDateTreatment				=	Hist.TxModDateTreatment
							,TxModOrgIdDecisionTreat		=	Hist.TxModOrgIdDecisionTreat
							,TxModOrgCodeDecisionTreat		=	Hist.TxModOrgCodeDecisionTreat
							,TxModOrgDescDecisionTreat		=	Hist.TxModOrgDescDecisionTreat
							,TxModOrgIdTreatment			=	Hist.TxModOrgIdTreatment
							,TxModOrgCodeTreatment			=	Hist.TxModOrgCodeTreatment
							,TxModOrgDescTreatment			=	Hist.TxModOrgDescTreatment
							,TxModDefinitiveTreatment		=	Hist.TxModDefinitiveTreatment
							,TxModChemoRadio				=	Hist.TxModChemoRadio
							,TxModChemoRT					=	Hist.TxModChemoRT
							,TxModModalitySubCode			=	Hist.TxModModalitySubCode
							,TxModRadioSurgery				=	Hist.TxModRadioSurgery
							-- CWT Based ChemoRT Treatment modality Treatments
							,ChemRtLinkTreatmentEventCode	=	Hist.ChemRtLinkTreatmentEventCode
							,ChemRtLinkTreatmentEventDesc	=	Hist.ChemRtLinkTreatmentEventDesc
							,ChemRtLinkTreatmentCode		=	Hist.ChemRtLinkTreatmentCode
							,ChemRtLinkTreatmentDesc		=	Hist.ChemRtLinkTreatmentDesc
							,ChemRtLinkTreatmentSettingCode	=	Hist.ChemRtLinkTreatmentSettingCode
							,ChemRtLinkTreatmentSettingDesc	=	Hist.ChemRtLinkTreatmentSettingDesc
							,ChemRtLinkDateDecisionTreat	=	Hist.ChemRtLinkDateDecisionTreat
							,ChemRtLinkDateTreatment		=	Hist.ChemRtLinkDateTreatment
							,ChemRtLinkOrgIdDecisionTreat	=	Hist.ChemRtLinkOrgIdDecisionTreat
							,ChemRtLinkOrgCodeDecisionTreat	=	Hist.ChemRtLinkOrgCodeDecisionTreat
							,ChemRtLinkOrgDescDecisionTreat	=	Hist.ChemRtLinkOrgDescDecisionTreat
							,ChemRtLinkOrgIdTreatment		=	Hist.ChemRtLinkOrgIdTreatment
							,ChemRtLinkOrgCodeTreatment		=	Hist.ChemRtLinkOrgCodeTreatment
							,ChemRtLinkOrgDescTreatment		=	Hist.ChemRtLinkOrgDescTreatment
							,ChemRtLinkDefinitiveTreatment	=	Hist.ChemRtLinkDefinitiveTreatment
							,ChemRtLinkChemoRadio			=	Hist.ChemRtLinkChemoRadio
							,ChemRtLinkModalitySubCode		=	Hist.ChemRtLinkModalitySubCode
							,ChemRtLinkRadioSurgery			=	Hist.ChemRtLinkRadioSurgery
							-- CWT Based data flags
							,cwtFlag2WW						=	Hist.cwtFlag2WW
							,cwtFlag28						=	Hist.cwtFlag28
							,cwtFlag31						=	Hist.cwtFlag31
							,cwtFlag62						=	Hist.cwtFlag62
							,cwtType2WW						=	Hist.cwtType2WW
							,cwtType28						=	Hist.cwtType28
							,cwtType31						=	Hist.cwtType31
							,cwtType62						=	Hist.cwtType62
							,cwtReason2WW					=	Hist.cwtReason2WW
							,cwtReason28					=	Hist.cwtReason28
							,cwtReason31					=	Hist.cwtReason31
							,cwtReason62					=	Hist.cwtReason62
							,HasTxMod						=	Hist.HasTxMod
							,HasChemRtLink					=	Hist.HasChemRtLink
							-- CWT Wait Calculations
							,ClockStartDate2WW				=	Hist.ClockStartDate2WW
							,ClockStartDate28				=	Hist.ClockStartDate28
							,ClockStartDate31				=	Hist.ClockStartDate31
							,ClockStartDate62				=	Hist.ClockStartDate62
							,AdjTime2WW						=	Hist.AdjTime2WW
							,AdjTime28						=	Hist.AdjTime28
							,AdjTime31						=	Hist.AdjTime31
							,AdjTime62						=	Hist.AdjTime62
							,TargetDate2WW					=	Hist.TargetDate2WW
							,TargetDate28					=	Hist.TargetDate28
							,TargetDate31					=	Hist.TargetDate31
							,TargetDate62					=	Hist.TargetDate62
							,DaysTo2WWBreach				=	Hist.DaysTo2WWBreach
							,DaysTo28DayBreach				=	Hist.DaysTo28DayBreach
							,DaysTo31DayBreach				=	Hist.DaysTo31DayBreach
							,DaysTo62DayBreach				=	Hist.DaysTo62DayBreach
							,ClockStopDate2WW				=	Hist.ClockStopDate2WW
							,ClockStopDate28				=	Hist.ClockStopDate28
							,ClockStopDate31				=	Hist.ClockStopDate31
							,ClockStopDate62				=	Hist.ClockStopDate62
							,Waitingtime2WW					=	Hist.Waitingtime2WW
							,Waitingtime28					=	Hist.Waitingtime28
							,Waitingtime31					=	Hist.Waitingtime31
							,Waitingtime62					=	Hist.Waitingtime62
							,Breach2WW						=	Hist.Breach2WW
							,Breach28						=	Hist.Breach28
							,Breach31						=	Hist.Breach31
							,Breach62						=	Hist.Breach62
							,DaysTo62DayBreachNoDTT			=	Hist.DaysTo62DayBreachNoDTT
							,Treated7Days					=	Hist.Treated7Days
							,Treated7Days62Days				=	Hist.Treated7Days62Days
							,FutureAchieve62Days			=	Hist.FutureAchieve62Days
							,FutureFail62Days				=	Hist.FutureFail62Days
							,ActualWaitDTTTreatment			=	Hist.ActualWaitDTTTreatment
							,DTTTreated7Days				=	Hist.DTTTreated7Days
							,Treated7Days31Days				=	Hist.Treated7Days31Days
							,Treated7DaysBreach31Days		=	Hist.Treated7DaysBreach31Days
							,FutureAchieve31Days			=	Hist.FutureAchieve31Days
							,FutureFail31Days				=	Hist.FutureFail31Days
							,FutureDTT						=	Hist.FutureDTT
							,NoDTTDate						=	Hist.NoDTTDate
							-- CWT Based Provenance
							,LastCommentUser				=	Hist.LastCommentUser
							,LastCommentDate				=	Hist.LastCommentDate
							,CwtReportDate					=	Hist.CwtReportDate
							,PtlSnapshotId					=	Hist.PtlSnapshotId
							-- PTL_Live Snapshot data (that isn't already in CWT or Referrals)
							,Pathway						=	Hist.Pathway
							,TrackingNotes					=	Hist.TrackingNotes
							,DateLastTracked				=	Hist.DateLastTracked
							,CommentUser					=	Hist.CommentUser
							,DaysSinceLastTracked			=	Hist.DaysSinceLastTracked
							,Weighting						=	Hist.Weighting
							,DaysToNextBreach				=	Hist.DaysToNextBreach
							,NextBreachTarget				=	Hist.NextBreachTarget
							,NextBreachDate					=	Hist.NextBreachDate
							,DominantColourValue			=	Hist.DominantColourValue
							,ColourValue2WW					=	Hist.ColourValue2WW
							,ColourValue28Day				=	Hist.ColourValue28Day
							,ColourValue31Day				=	Hist.ColourValue31Day
							,ColourValue62Day				=	Hist.ColourValue62Day
							,DominantColourDesc				=	Hist.DominantColourDesc
							,ColourDesc2WW					=	Hist.ColourDesc2WW
							,ColourDesc28Day				=	Hist.ColourDesc28Day
							,ColourDesc31Day				=	Hist.ColourDesc31Day
							,ColourDesc62Day				=	Hist.ColourDesc62Day
							,DominantPriority				=	Hist.DominantPriority
							,Priority2WW					=	Hist.Priority2WW
							,Priority28						=	Hist.Priority28
							,Priority31						=	Hist.Priority31
							,Priority62						=	Hist.Priority62
							,PathwayUpdateEventID			=	Hist.PathwayUpdateEventID
							,NextActionDesc					=	Hist.NextActionDesc
							,NextActionSpecificDesc			=	Hist.NextActionSpecificDesc
							,NextActionTargetDate			=	Hist.NextActionTargetDate
							,DaysToNextAction				=	Hist.DaysToNextAction
							,OwnerDesc						=	Hist.OwnerDesc
							,AdditionalDetails				=	Hist.AdditionalDetails
							,Escalated						=	Hist.Escalated
							-- TECHNICAL DEBT -- PTL Status
							,ReportingPathwayLength			=	Hist.ReportingPathwayLength
							-- TECHNICAL DEBT --CWT Status
							,DominantCWTStatusCode 			=	Hist.DominantCWTStatusCode 
							,DominantCWTStatusDesc			=	Hist.DominantCWTStatusDesc
							,CWTStatusCode2WW				=	Hist.CWTStatusCode2WW
							,CWTStatusDesc2WWL				=	Hist.CWTStatusDesc2WW
							,CWTStatusCode28 				=	Hist.CWTStatusCode28 
							,CWTStatusDesc28 				=	Hist.CWTStatusDesc28 
							,CWTStatusCode31 				=	Hist.CWTStatusCode31 
							,CWTStatusDesc31 				=	Hist.CWTStatusDesc31 
							,CWTStatusCode62 				=	Hist.CWTStatusCode62 
							,CWTStatusDesc62 				=	Hist.CWTStatusDesc62 
							,SSRS_PTLFlag62					=	Hist.SSRS_PTLFlag62
							
				FROM		SCR_Reporting_History.SCR_PTL_History Hist
				INNER JOIN	#SnapshotIx snap
								ON	Hist.PtlSnapshotId = snap.PtlSnapshotId
				INNER JOIN	#MoreRecentSnapshot MoreRecent
								ON	Hist.CWT_ID = MoreRecent.CWT_ID
				WHERE		snap.PtlSnapshotIx = MoreRecent.MaxPtlSnapshotIx

				-- Mark the snapshots as having been loaded into the SCR_LastPTL_Record table
				UPDATE		sd
				SET			sd.LoadedIntoLastPtlRecord = 1
				FROM		SCR_Reporting_History.SCR_PTL_SnapshotDates sd
				INNER JOIN	#SnapshotIx snap
								ON	sd.PtlSnapshotId = snap.PtlSnapshotId

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
		
		-- Keep a record of when creating the SCR_LastPTL_Record snapshot dataset finished
		EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'SCR_Reporting_History.uspUpdateLastPTL_Record', @Step = 'Create last PTL record for each pathway'
		

GO
