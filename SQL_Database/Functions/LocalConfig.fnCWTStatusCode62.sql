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
Description:				Calculate the CWT status code for records against the 62 day pathway
**************************************************************************************************************************************************/

-- Test me
-- 

CREATE FUNCTION [LocalConfig].[fnCWTStatusCode62]
(
	@OrgCodeFirstSeen varchar (5), 
	@DeftOrgCodeTreatment varchar (5),
	@PatientStatusCode varchar (2),
	@DateDiagnosis smalldatetime,
	@DeftDateTreatment smalldatetime,
	@DateFirstSeen smalldatetime,
	@cwtFlag2WW int,
	@cwtFlag62 int,
	@IsCwtCancerDiagnosis int,
	@TargetDate62 smalldatetime,
	@ReportDate datetime,
	@FirstAppointmentTypeCode int,
	@DateReceipt smalldatetime,
	@CancerSite varchar(50),
	@CancerTypeCode varchar(2),
	@cwtFlag28 int
)

RETURNS int
AS
BEGIN
	
	-- Not RXH
	IF		LEFT(ISNULL(@OrgCodeFirstSeen, LocalConfig.fnOdsCode()), 3) != LocalConfig.fnOdsCode()
	AND		LEFT(ISNULL(@DeftOrgCodeTreatment, LocalConfig.fnOdsCode()), 3) != LocalConfig.fnOdsCode()
	RETURN	12
	
	-- No Cancer, but patient not informed (FDS is still open)
	IF		@PatientStatusCode IN (3)
	AND		@cwtFlag28&1 = 1		-- pathway is still open -- NB: this means that the first bit is = 1 and could also be written as @cwtFlag28 IN (1,5) - try SELECT 1&1, 2&1, 4&1, 5&1, 3&2, 5&2, 6&2, 7&5 to see how this works
	RETURN	56
	
	-- No Cancer
	IF		@PatientStatusCode IN (3)
	RETURN	2

	-- Suspected cancer – referral to serious non-specific symptom clinic
	IF		@CancerTypeCode = '17'
	RETURN	55

	-- Diagnosed Dated or Treated
	IF		@cwtFlag62 = 2 -- reportable
	BEGIN
			-- 'Future Treatment Diagnosed Breach'
			IF		@DeftDateTreatment >= @ReportDate
			AND		@DeftDateTreatment > @TargetDate62
			RETURN	49 

			-- 'Future Treatment Diagnosed In Target'
			IF		@DeftDateTreatment >= @ReportDate
			RETURN	50 

			-- 'Treated Diagnosed Breach'
			IF		@DeftDateTreatment > @TargetDate62
			RETURN	45 

			--'Treated Diagnosed In Target'
			RETURN	46
	END

	-- Treated undiagnosed
	IF		@cwtFlag62 IN (1,2) -- Is 62 day pathway ?Is 2 necessary?
	AND		@DeftDateTreatment IS NOT NULL -- has treatment date
	AND		@IsCwtCancerDiagnosis = -1 --undiagnosed
	BEGIN
			-- 'Future Treatment Undiagnosed Breach'
			IF		@DeftDateTreatment >= @ReportDate
			AND		@DeftDateTreatment > @TargetDate62
			RETURN	51

			-- 'Future Treatment Undiagnosed In Target'
			IF		@DeftDateTreatment >= @ReportDate
			RETURN	52 

			-- 'Treated Undiagnosed Breach'
			IF		@DeftDateTreatment > @TargetDate62
			RETURN	47 

			--'Treated Undiagnosed In Target'
			RETURN	48
	END

	-- 2WW Pending
	IF		@DateFirstSeen > @ReportDate
	AND		@cwtFlag2WW = 1
	RETURN	14

	-- Patient did not have first appointment
	IF		@DateFirstSeen IS NULL
	AND		@cwtFlag2WW = 0		
	AND		@FirstAppointmentTypeCode = 1
	RETURN	53

	-- 2WW Undated
	IF		@DateFirstSeen IS NULL
	AND		@cwtFlag2WW = 1
	RETURN	15

	--Diagnosed
	IF		ISNULL(@IsCwtCancerDiagnosis, -1) >= 0
	AND		@cwtFlag62 = 1
	RETURN	25
	   
	-- Referral > 1yr ago (Breast / Skin >12 months filter)
	IF		@DateReceipt < DATEADD(MONTH, -12, @ReportDate)
	AND		@CancerSite in ('Breast','Skin')
	AND		(@cwtFlag2WW IN (1)									-- Would be on the SCR PTL
	OR		@cwtFlag62 IN (1,2))								-- Would be on the SCR PTL
	RETURN	29

	-- Referral > 1yr ago (All other >12 months filter)
	IF		@DateReceipt < DATEADD(MONTH, -12, @ReportDate)
	AND NOT @CancerSite in ('Breast','Skin') 
	AND		(@cwtFlag2WW IN (1)									-- Would be on the SCR PTL
	OR		@cwtFlag62 IN (1,2))								-- Would be on the SCR PTL
	RETURN	30	

	-- 62 Day Undiagnosed
	IF		@IsCwtCancerDiagnosis = -1
	AND		@cwtFlag62 = 1
	RETURN	24

	-- Uncategorised
	IF @cwtFlag62 = 0
	RETURN	35 -- Closed / Excluded
	IF @cwtFlag62 = 1
	RETURN	36 -- Open
	IF @cwtFlag62 = 2
	RETURN	37 -- Reportable
	IF @cwtFlag62 = 4
	RETURN	38 -- Not applicable
	IF @cwtFlag62 = 5
	RETURN	39 -- Error!

	-- Catch all for any records not yet categorised
	RETURN 34 -- Error!

END
GO
