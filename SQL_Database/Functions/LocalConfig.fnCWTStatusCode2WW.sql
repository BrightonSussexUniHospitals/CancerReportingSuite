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

CREATE FUNCTION [LocalConfig].[fnCWTStatusCode2WW]
(
	@OrgCodeFirstSeen varchar (5), 
	@cwtFlag2WW int,
	@DateFirstSeen smalldatetime,
	@ReportDate datetime,
	@FirstAppointmentTypeCode int,
	@ReasonNoAppointmentCode int,
	@CancerTypeCode varchar(2)

	--@DeftOrgCodeTreatment varchar (5),
	--@PatientStatusCode varchar (2),
	--@DateDiagnosis smalldatetime,
	--@DeftDateTreatment smalldatetime,
	--@cwtFlag62 int,
	--@IsCwtCancerDiagnosis int,
	--@TargetDate62 smalldatetime,
	--@DateReceipt smalldatetime,
	--@CancerSite varchar(50),
	--@DateConsultantUpgrade smalldatetime,
	--@SourceReferralCode varchar(2)
)

RETURNS int
AS
BEGIN
	-- Not RXH
	IF		LEFT(ISNULL(@OrgCodeFirstSeen, LocalConfig.fnOdsCode()), 3) != LocalConfig.fnOdsCode()
	AND		@cwtFlag2WW IN (0,1,2)
	RETURN	12

	-- Suspected cancer – referral to serious non-specific symptom clinic
	IF		@CancerTypeCode = '17'
	RETURN	55
	
	-- Clock stopped
	IF		@cwtFlag2WW = 2
	RETURN	44 --2WW Seen

	-- Pre 2WW Appt - booked
	IF		@DateFirstSeen > @ReportDate
	AND		@cwtFlag2WW = 1
	RETURN	14 --2WW Pending

	-- Patient did not have first appointment
	IF		@DateFirstSeen IS NULL
	AND		@cwtFlag2WW = 0
	AND		@FirstAppointmentTypeCode = 1
	RETURN	5 + ISNULL(@ReasonNoAppointmentCode, 0)

	-- Pre 2WW Appt - unbooked
	IF		@DateFirstSeen IS NULL
	AND		@cwtFlag2WW = 1
	RETURN	15 --2WW Undated

	-- Uncategorised
	IF @cwtFlag2WW = 0
	RETURN	35 -- Closed / Excluded
	IF @cwtFlag2WW = 1
	RETURN	36 -- Open
	IF @cwtFlag2WW = 2
	RETURN	37 -- Reportable
	IF @cwtFlag2WW = 4
	RETURN	38 -- Not applicable
	IF @cwtFlag2WW = 5
	RETURN	39 -- Error!

	-- Catch all for any records not yet categorised
	RETURN 34 -- Uncategorised

END
GO
