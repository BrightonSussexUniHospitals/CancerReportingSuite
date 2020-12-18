SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [SCR_Warehouse].[uspUpdateProcessAudit]
		(@UpdateType int
		,@Process varchar(255)
		,@Step varchar(255)
		,@StepTime datetime = NULL
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

Original Work Created Date:	02/10/2019
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				This procedure maintains the process of updating the ProcessAudit table, a 
							table which keeps a record of when steps in a process start and finish
**************************************************************************************************************************************************/

/************************************************************************************************************************************************************************************************************
-- Understanding the parameters for this stored procedure
	-- @UpdateType
	This parameter determines whether the stored procedure is updating for the start of a process step or the completion of that step
	It has 2 possible values:
		1	The process step has started
		2	The process step has finised

************************************************************************************************************************************************************************************************************/

-- EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 1, @Process = 'Test ProcessAudit', @Step = 'Test step' -- Run me
-- EXEC SCR_Warehouse.uspUpdateProcessAudit @UpdateType = 2, @Process = 'Test ProcessAudit', @Step = 'Test step' -- Run me

		-- Set the @StepTime to now, unless a time was specified
		IF @StepTime IS NULL
		SET @StepTime = GETDATE()

		-- Create a record for the combination of @Process and @Step values if they don't already exist
		IF (SELECT COUNT(*) FROM SCR_Warehouse.ProcessAudit WHERE Process = @Process AND Step = @Step) = 0
		INSERT INTO SCR_Warehouse.ProcessAudit (Process, Step) VALUES(@Process, @Step)
		
		-- Update the ProcessAudit record for the process start
		IF @UpdateType = 1
		UPDATE	SCR_Warehouse.ProcessAudit 
		SET		LastStarted = @StepTime
				,LastSuccessfullyCompleted = CAST(NULL AS datetime) -- reset the completion time to NULL
		WHERE	Process = @Process 
		AND		Step = @Step
		
		-- Update the ProcessAudit record for the process finish
		IF @UpdateType = 2
		UPDATE	SCR_Warehouse.ProcessAudit 
		SET		LastSuccessfullyCompleted = @StepTime
		WHERE	Process = @Process 
		AND		Step = @Step
GO
