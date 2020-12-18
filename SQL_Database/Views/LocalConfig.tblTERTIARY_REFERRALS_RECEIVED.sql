SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [LocalConfig].[tblTERTIARY_REFERRALS_RECEIVED] AS

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

Original Work Created Date:	30/07/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop) & BSUH (Lawrence Simpson)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk / lawrencesimpson@nhs.net
Description:				Create a local config view to point at the place where the SCR
							replicated data is located so that the core procedures don't
							need to be changed when they are copied to different environments 
							(e.g. live vs test or from one trust to another)
**************************************************************************************************************************************************/

		-- Select the whole dataset from the replica table
		SELECT		*
		FROM		[CancerRegister_Replicated_v19.01]..tblTERTIARY_REFERRALS_RECEIVED
GO
