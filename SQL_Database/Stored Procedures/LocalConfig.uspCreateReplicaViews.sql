SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 CREATE PROCEDURE [LocalConfig].[uspCreateReplicaViews] (
		@ReplicaDatabaseName VARCHAR(255) NULL = ''
		,@DataViewVersion VARCHAR(255) NULL = ''
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

Original Work Created Date:	30/07/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Create local config views of the tables 
							in the SCR replica
**************************************************************************************************************************************************/

-- Test me
-- EXEC LocalConfig.uspCreateReplicaViews @ReplicaDatabaseName = N'CancerRegister_Replicated_v20.01', @DataViewVersion = N'v20.01'

/**************************************************************************************************************************************************
-- Set up the variables
**************************************************************************************************************************************************/

		-- Declare the variables for the procedure
		DECLARE @InternalReplicaDatabaseName nvarchar(max)
		DECLARE @InternalDataViewVersion VARCHAR(255)
		DECLARE @CopyrightNotice nvarchar(max)
		DECLARE @SQL nvarchar(max)
		DECLARE @TableCounter int = 1
		DECLARE @TableName nvarchar(max)
		DECLARE @VersionSpecificSQL nvarchar(max)

		-- Determine and set the internal replica database name
		IF ISNULL(@ReplicaDatabaseName, '') != ''
		BEGIN
			SET @InternalReplicaDatabaseName = @ReplicaDatabaseName
		END

		ELSE
		BEGIN
			-- Point to the SCR test replica if we are on the test SQL server
			IF @@SERVERNAME = 'SVVSQLTST01\SVVDFLTSQLTST03'
			BEGIN
				SET @InternalReplicaDatabaseName = 'CancerRegisterTest_Replicated'
			END

			-- Point to the SCR test replica if we are on the test SQL server
			IF @@SERVERNAME = 'SVCDEFAULTDB03'
			BEGIN
				SET @InternalReplicaDatabaseName = 'CancerRegister_Replicated'
			END
		END
		
		-- Determine the version of SCR the views should be built for
		IF ISNULL(@DataViewVersion, '') = '' AND OBJECT_ID('LocalConfig.versionDataViewLog') IS NOT NULL
		BEGIN
			SELECT		@InternalDataViewVersion = vwvl.DataViewVersion
			FROM		(SELECT		*
									,ROW_NUMBER() OVER (ORDER BY ID DESC) AS IdIx
						FROM		LocalConfig.versionDataViewLog
						) vwvl
			WHERE		vwvl.IdIx = 1
		END

		ELSE
		BEGIN
			SET @InternalDataViewVersion = @DataViewVersion
		END
		
		-- Set the copyright notice variable
		SET @CopyrightNotice = 
				'' + CHAR(10) +
				'/******************************************************** © Copyright & Licensing ****************************************************************' + CHAR(10) +
				'© 2019 Perspicacity Ltd & Brighton & Sussex University Hospitals' + CHAR(10) +
				'' + CHAR(10) +
				'This code / file is part of Perspicacity & BSUH''s Cancer Data Warehouse & Reporting suite.' + CHAR(10) +
				'' + CHAR(10) +
				'This Cancer Data Warehouse & Reporting suite is free software: you can ' + CHAR(10) +
				'redistribute it and/or modify it under the terms of the GNU Affero ' + CHAR(10) +
				'General Public License as published by the Free Software Foundation, ' + CHAR(10) +
				'either version 3 of the License, or (at your option) any later version.' + CHAR(10) +
				'' + CHAR(10) +
				'This Cancer Data Warehouse & Reporting suite is distributed in the hope ' + CHAR(10) +
				'that it will be useful, but WITHOUT ANY WARRANTY; without even the ' + CHAR(10) +
				'implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  ' + CHAR(10) +
				'See the GNU Affero General Public License for more details.' + CHAR(10) +
				'' + CHAR(10) +
				'You should have received a copy of the GNU Affero General Public License' + CHAR(10) +
				'along with this program.  If not, see <https://www.gnu.org/licenses/>.' + CHAR(10) +
				'' + CHAR(10) +
				'A full copy of this code can be found at https://github.com/BrightonSussexUniHospitals/CancerReportingSuite' + CHAR(10) +
				'' + CHAR(10) +
				'You may also be interested in the other repositories at https://github.com/perspicacity-ltd or' + CHAR(10) +
				'https://github.com/BrightonSussexUniHospitals' + CHAR(10) +
				'' + CHAR(10) +
				'Original Work Created Date:	30/07/2020' + CHAR(10) +
				'Original Work Created By:	Perspicacity Ltd (Matthew Bishop) & BSUH (Lawrence Simpson)' + CHAR(10) +
				'Original Work Contact:		07545 878906' + CHAR(10) +
				'Original Work Contact:		matthew.bishop@perspicacityltd.co.uk / lawrencesimpson@nhs.net' + CHAR(10) +
				'Description:				Create a local config view to point at the place where the SCR' + CHAR(10) +
				'							replicated data is located so that the core procedures don''t' + CHAR(10) +
				'							need to be changed when they are copied to different environments ' + CHAR(10) +
				'							(e.g. live vs test or from one trust to another)' + CHAR(10) +
				'**************************************************************************************************************************************************/' + CHAR(10) +
				'' + CHAR(10)

/**************************************************************************************************************************************************
-- Loop through each table in Lookup.ReplicaTables and create the associated view
**************************************************************************************************************************************************/

		-- Create a table of the tables in the replica
		SELECT		name
					,VersionSpecificSQL
					,ROW_NUMBER() OVER (ORDER BY Name) AS Ix
		INTO		#ReplicaTables
		FROM		Lookup.ReplicaTables
		WHERE		DataViewVersion = @InternalDataViewVersion
		ORDER BY	Name

		-- Loop through each table in the replica to drop and recreate existing views
		WHILE @TableCounter <= (SELECT MAX(Ix) FROM #ReplicaTables)
		BEGIN

				-- Reset the @VersionSpecificSQL parameter
				SET @VersionSpecificSQL = NULL
				
				-- Retrieve the table name we are working with
				SELECT		@TableName = Name
							,@VersionSpecificSQL = VersionSpecificSQL
				FROM		#ReplicaTables
				WHERE		Ix = @TableCounter

				/*********************************************************************************************************************************/
				-- Drop the existing view
				/*********************************************************************************************************************************/
				
				-- Set the SQL to drop the view
				SET @SQL = 'IF OBJECT_ID(''LocalConfig.' + @TableName + ''') IS NOT NULL DROP VIEW LocalConfig.' + @TableName

				-- Run the SQL to drop the view
				--PRINT @SQL
				EXEC (@SQL)

				/*********************************************************************************************************************************/
				-- Create the new view
				/*********************************************************************************************************************************/
				
				-- Set the SQL to create the view
				SET @SQL = 
				'CREATE VIEW LocalConfig.' + @TableName + ' AS' + CHAR(10) + @CopyrightNotice

				
				-- Set the SQL for the select portion of the view where Lookup.ReplicaTables has a version specific select statement
				IF @VersionSpecificSQL IS NOT NULL
				BEGIN
					SET @SQL = @SQL + REPLACE(@VersionSpecificSQL, '~~ReplicaDatabaseName~~', @InternalReplicaDatabaseName)
				END

				-- Set the SQL for the select portion of the view where Lookup.ReplicaTables has no version specific select statement
				ELSE
				BEGIN
					SET @SQL = @SQL + 
					'		-- Select the whole dataset from the replica table' + CHAR(10) +
					'		SELECT		*' + CHAR(10) +
					'		FROM		' + @InternalReplicaDatabaseName + '..' + @TableName
				END

				-- Run the SQL to create the view
				--PRINT @SQL
				EXEC (@SQL)

				SET @TableCounter = @TableCounter + 1
		END



GO
