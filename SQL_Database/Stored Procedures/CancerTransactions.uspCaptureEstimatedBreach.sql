SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [CancerTransactions].[uspCaptureEstimatedBreach] (
		@CWT_ID varchar(255)
		,@EstimatedWeight real
		,@EstimatedBreachDate date
		,@CapturedDate datetime = NULL
		,@CapturedBy varchar(255) = NULL
		,@ReturnDataset int = 1
		)

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

Original Work Created Date:	31/10/2019
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				This procedure is a data interface for the SSRS estimated breach report
							to pass parameters back and have them inserted into the 
							CancerTransactions.EstimatedBreach table, a part of the apparatus 
							enabling us to shoehorn	writeback functionality into SSRS
**************************************************************************************************************************************************/

-- EXEC CancerTransactions.uspCaptureEstimatedBreach @CWT_ID = 'Test', @EstimatedWeight = 0.5, @EstimatedBreachDate = '01 Jan 2019', @CapturedBy = 'MB_Test'
-- SELECT * FROM CancerTransactions.EstimatedBreach
		
		DECLARE @NewRecordId int

		-- Handle optional parameters with no value supplied
		IF @CapturedDate IS NULL
		SET @CapturedDate = GETDATE()

		IF @CapturedBy IS NULL
		SET @CapturedBy = SUSER_NAME()

		-- Enter the new breach record information
		INSERT INTO	CancerTransactions.EstimatedBreach (
					CWT_ID
					,EstimatedWeight
					,EstimatedBreachDate
					,CapturedDate
					,CapturedBy
					)
		VALUES		(
					@CWT_ID
					,@EstimatedWeight
					,@EstimatedBreachDate
					,@CapturedDate
					,@CapturedBy
					)

		-- Capture the EstimatedBreachId of the newly created record (within the scope of this session)
		SET @NewRecordId = SCOPE_IDENTITY()
		
		-- Mark all records for this CWT_ID as not current
		UPDATE		CancerTransactions.EstimatedBreach
		SET			CurrentRecord = 0
		WHERE		CWT_ID = @CWT_ID
		
		-- Mark the newly entered record as current
		UPDATE		CancerTransactions.EstimatedBreach
		SET			CurrentRecord = 1
		WHERE		EstimatedBreachId = @NewRecordId
		
		IF @ReturnDataset = 1
		SELECT 'Success' AS ReturnValue

		RETURN 0

		
GO
