SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [SCR_Warehouse].[uspUpdateProcessAuditHistory]
		(@ProcessAuditHistoryId int = NULL
		,@Process varchar(255)
		,@Step varchar(255)
		,@StepTime datetime = NULL
		,@ProcessAuditHistoryIdCreated int = NULL OUTPUT
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

Original Work Created Date:	11/10/2019
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				This procedure maintains the process of updating the ProcessAudit table, a 
							table which keeps a record of when steps in a process start and finish
**************************************************************************************************************************************************/

/************************************************************************************************************************************************************************************************************
-- Understanding the parameters for this stored procedure
	-- @ProcessAuditHistoryId
	This parameter determines whether the stored procedure is updating the finish time for an existing record or creating a new one
	By passing the ID of an existing record, it is assumed that the record is having it's end date captured

************************************************************************************************************************************************************************************************************/

/* -- Test me
DECLARE @ProcessAuditHistoryIdCreated int, @ProcessAuditHistoryIdCreated2 int
EXEC SCR_Warehouse.uspUpdateProcessAuditHistory @Process = 'Test ProcessAuditHistory', @Step = 'Test step', @ProcessAuditHistoryIdCreated = @ProcessAuditHistoryIdCreated OUTPUT 
SELECT @ProcessAuditHistoryIdCreated AS ProcessAuditHistoryIdCreated

EXEC SCR_Warehouse.uspUpdateProcessAuditHistory @ProcessAuditHistoryId = @ProcessAuditHistoryIdCreated, @Process = 'Test ProcessAuditHistory', @Step = 'Test step', @ProcessAuditHistoryIdCreated = @ProcessAuditHistoryIdCreated2 OUTPUT
SELECT @ProcessAuditHistoryIdCreated2 AS ProcessAuditHistoryIdCreated2

SELECT * FROM SCR_Warehouse.ProcessAuditHistory WHERE ProcessAuditHistoryId = @ProcessAuditHistoryIdCreated
*/


		-- Set up the @PahInserted tablevar to capture the inserted process audit history ID
		DECLARE @PahInserted TABLE (ProcessAuditHistoryId int)
		
		-- Set the @StepTime to now, unless a time was specified
		IF @StepTime IS NULL
		SET @StepTime = GETDATE()

		-- Update the ProcessAuditHistory record for the process start
		IF @ProcessAuditHistoryId IS NULL
		BEGIN
				INSERT INTO	SCR_Warehouse.ProcessAuditHistory (
						Process
						,Step
						,LastStarted
						)
				OUTPUT	inserted.ProcessAuditHistoryId INTO @PahInserted(ProcessAuditHistoryId)
				VALUES(@Process, @Step, @StepTime)

				-- Return the ID of the record that was just entered
				SELECT @ProcessAuditHistoryIdCreated = ProcessAuditHistoryId FROM @PahInserted
		END
		
		-- Update the ProcessAuditHistory record for the process finish (if we can find a record that matches on the supplied ID, process and step values)
		IF	@ProcessAuditHistoryId IS NOT NULL
		AND	(SELECT COUNT(*) FROM SCR_Warehouse.ProcessAuditHistory WHERE ProcessAuditHistoryId = @ProcessAuditHistoryId AND Process = @Process AND Step = @Step) = 1
		BEGIN
				UPDATE	SCR_Warehouse.ProcessAuditHistory 
				SET		LastSuccessfullyCompleted = @StepTime
				OUTPUT	inserted.ProcessAuditHistoryId INTO @PahInserted(ProcessAuditHistoryId)
				WHERE	ProcessAuditHistoryId = @ProcessAuditHistoryId

				-- Return the ID of the record that was just updated
				SELECT @ProcessAuditHistoryIdCreated = ProcessAuditHistoryId FROM @PahInserted
		END
		
		-- Update the ProcessAuditHistory record for the process finish (if we can't find a record that matches on the supplied ID, process and step values)
		IF @ProcessAuditHistoryId IS NOT NULL
		AND	(SELECT COUNT(*) FROM SCR_Warehouse.ProcessAuditHistory WHERE ProcessAuditHistoryId = @ProcessAuditHistoryId AND Process = @Process AND Step = @Step) != 1
		BEGIN
				INSERT INTO	SCR_Warehouse.ProcessAuditHistory (
						Process
						,Step
						,LastSuccessfullyCompleted
						)
				OUTPUT inserted.ProcessAuditHistoryId INTO @PahInserted(ProcessAuditHistoryId)
				VALUES(@Process, @Step, @StepTime)

				-- Return the ID of the record that was just entered
				SELECT @ProcessAuditHistoryIdCreated = ProcessAuditHistoryId FROM @PahInserted
		END

GO
