SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [LocalConfig].[fnNextActionColours]
(
	@OwnerCode varchar (255), 
	@NextActionID int,
	@NextActionSpecificID int
)

RETURNS varchar (255)
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

Original Work Created Date:	19/11/2019
Original Work Created By:	Lawrence Simpson / Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Return an HTML colour value based on the combination of OwnerCode,
							NextActionId and NextActionSpecificId passed to the function
**************************************************************************************************************************************************/

-- Test me
-- Select LocalConfig.fnNextActionColours (12,34,1)
-- Select LocalConfig.fnNextActionColours (11,1,1)
-- Select LocalConfig.fnNextActionColours (11,2,1)
-- Select LocalConfig.fnNextActionColours (11,3,1)
-- Select LocalConfig.fnNextActionColours (11,4,1)


BEGIN
	
	-- Covid / Coronavirus
	IF @NextActionID IN (34,35)
	OR @NextActionSpecificID IN (28,29)
	RETURN '#FFFF00'

	-- Radiology awaiting results
	IF	@OwnerCode IN (12)
	AND	@NextActionID IN (12)
	RETURN '#E6B8B7'
	
	-- Radiology
	IF	@OwnerCode IN (12)
	RETURN '#C00000' 

	-- Pathology
	IF	@OwnerCode IN (9)
	RETURN '#FF0000'
	-- 
	IF	@NextActionID IN (1,3,6,8,10,13,15,18)
	RETURN '#000000'

	IF	@NextActionID IN (2,14,25,33)
	RETURN '#92D050'

	IF	@NextActionID IN (4,11)
	RETURN '#D8E4BC'

	IF	@NextActionID IN (7)
	RETURN '#00B050'

	IF	@NextActionID IN (9)
	RETURN '#FFC000'

	IF	@NextActionID IN (22)
	AND	@NextActionSpecificID IN (7)
	RETURN '#4BACC6'

	IF	@NextActionID IN (22)
	AND	@NextActionSpecificID IN (21)
	RETURN '#0070C0'	

	IF	@NextActionID IN (22)
	AND	@NextActionSpecificID IN (22)
	RETURN '#8DB4E2'		
	
	IF	@NextActionID IN (22)
	AND	@NextActionSpecificID IN (23)
	RETURN '#B8CCE4'

	IF	@NextActionID IN (22)
	RETURN '#00B0F0'

	IF	@NextActionID IN (24,27,28)
	RETURN '#A6A6A6'
	
	IF	@NextActionID IN (26,32)
	RETURN '#8064A2'
	
	IF	@NextActionID IN (29)
	RETURN '#DA9694'

	IF	@NextActionID IN (31)
	RETURN '#0000FF'

	IF	@NextActionID IN (5)
	AND	@NextActionSpecificID IN (3,4,5,9,14,16,17,24,26,27)
	RETURN '#C00000'

	IF	@NextActionID IN (5)
	AND	@NextActionSpecificID IN (11)
	RETURN '#FDE9D9'

	IF	@NextActionID IN (12)
	AND	@NextActionSpecificID IN (5,9,14,16,17,27)
	RETURN '#E6B8B7'

	IF	@NextActionID IN (12)
	AND	@NextActionSpecificID IN (11)
	RETURN '#FDE9D9'

	IF	@NextActionID IN (12)
	AND	@NextActionSpecificID IN (3,4,24,26)
	RETURN '#FDE9D9'

	IF	@NextActionID IN (16)
	AND	@NextActionSpecificID IN (3,4,5,9,14,16,17,24,26,27)
	RETURN '#C00000'

	IF	@NextActionID IN (16)
	AND	@NextActionSpecificID IN (11)
	RETURN '#FDE9D9'

	-- Return NULL if we haven't already ascribed a value
	RETURN CAST(NULL AS varchar(255))

END
GO
