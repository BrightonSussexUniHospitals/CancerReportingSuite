SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




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

Original Work Created Date:	23/04/2020
Original Work Created By:	Lawrence Simpson / Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Calculate the CWT status code for records against the 28day FDS pathway
**************************************************************************************************************************************************/

-- Test me
-- 

CREATE FUNCTION [LocalConfig].[fnCWTStatusCode28]
(
	@cwtFlag28 int,
	@DateReceipt smalldatetime,
	@OrgCodeDiagnosis varchar(5),
	@DateDiagnosis smalldatetime,
	@Breach28 int,
	@IsCwtCancerDiagnosis int,
	@DateFirstSeen smalldatetime,
	@ReportDate datetime,
	@CancerTypeCode varchar(2)

	--@OrgCodeFirstSeen varchar (5), 
	--@DeftOrgCodeTreatment varchar (5),
	--@PatientStatusCode varchar (2),
	--@DeftDateTreatment smalldatetime,
	--@cwtFlag62 int,
	--@TargetDate62 smalldatetime,
	--@FirstAppointmentTypeCode int,	
	--@CancerSite varchar(50)
)

RETURNS int
AS
BEGIN
	-- An Error
	IF @cwtFlag28 = 5
	RETURN	39

	-- Not Applicable
	IF @cwtFlag28 = 4
	RETURN	38

	-- Suspected cancer – referral to serious non-specific symptom clinic
	IF		@CancerTypeCode = '17'
	RETURN	55

	-- Referral pre-Apr 19
	IF 	@DateReceipt < '01 Apr 2019'
	RETURN	43

	-- Has a diagnosis and diagnosis org not RXH
	IF		LEFT(ISNULL(@OrgCodeDiagnosis, LocalConfig.fnOdsCode()), 3) != LocalConfig.fnOdsCode() 
	AND		@DateDiagnosis IS NOT NULL
	RETURN	12

	-- Closed / excluded
	IF @cwtFlag28 = 0
	RETURN	35

	-- FDS clock stop (compliant)
	IF	@cwtFlag28 = 2
	AND		@Breach28  = 0
	RETURN	40

	-- FDS clock stop (breach)
	IF	@cwtFlag28 = 2
	AND		@Breach28  = 1
	RETURN	41                   
                      
	-- Diagnosed
	IF	@IsCwtCancerDiagnosis >= 0
	AND		@cwtFlag28 = 1
	RETURN	27                 

	-- Pre 2WW Appt
	IF	(@DateFirstSeen > @ReportDate
	OR		@DateFirstSeen IS NULL)
	AND		@cwtFlag28 = 1
	RETURN	42 -- 'FDS Pre-2WW'   
                      
	-- Undiagnosed
	IF	@IsCwtCancerDiagnosis = -1
	AND		@cwtFlag28 = 1
	RETURN	26 	


	-- Uncategorised
	IF @cwtFlag28 = 0
	RETURN	35 -- Closed / Excluded
	IF @cwtFlag28 = 1
	RETURN	36 -- Open
	IF @cwtFlag28 = 2
	RETURN	37 -- Reportable
	IF @cwtFlag28 = 4
	RETURN	38 -- Not applicable
	IF @cwtFlag28 = 5
	RETURN	39 -- Error!

	-- Catch all for any records not yet categorised
	RETURN 34 -- Error!

END
GO
