SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 CREATE PROCEDURE [LocalConfig].[uspCreateReplicaViews]
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
-- EXEC LocalConfig.uspCreateReplicaViews

		-- Declare the variables for the procedure
		DECLARE @SQL nvarchar(max)
		DECLARE @TableCounter int = 1
		DECLARE @TableName nvarchar(max)

		-- Create a table of the tables in the replica
		SELECT		name
					,ROW_NUMBER() OVER (ORDER BY Name) AS Ix
		INTO		#ReplicaTables
		FROM		Lookup.ReplicaTables 
		ORDER BY	Name

		-- Loop through each table in the replica to drop and recreate existing views
		WHILE @TableCounter <= (SELECT MAX(Ix) FROM #ReplicaTables)
		BEGIN

				-- Retrieve the table name we are working with
				SELECT		@TableName = Name
				FROM		#ReplicaTables
				WHERE		Ix = @TableCounter

				-- Set the SQL to drop the view
				SET @SQL = 'IF OBJECT_ID(''LocalConfig.' + @TableName + ''') IS NOT NULL DROP VIEW LocalConfig.' + @TableName

				-- Run the SQL to drop the view
				--PRINT @SQL
				EXEC (@SQL)

				-- Set the SQL to create the view
				SET @SQL = 
				'CREATE VIEW LocalConfig.' + @TableName + ' AS' + CHAR(10) +
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
				'' + CHAR(10) +
				'		-- Select the whole dataset from the replica table' + CHAR(10) +
				'		SELECT		*' + CHAR(10) +
				'		FROM		CancerRegister_Replicated..' + @TableName -- Enter the location of your replica server here

				-- Run the SQL to create the view
				--PRINT @SQL
				EXEC (@SQL)

				SET @TableCounter = @TableCounter + 1
		END
GO
