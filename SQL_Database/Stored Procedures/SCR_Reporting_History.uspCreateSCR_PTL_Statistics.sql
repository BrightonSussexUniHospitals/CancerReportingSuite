SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [SCR_Reporting_History].[uspCreateSCR_PTL_Statistics] 
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

Original Work Created Date:	17/06/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Create and update the archive datasets for all SCR / Somerset reporting
**************************************************************************************************************************************************/

--  EXEC SCR_Reporting_History.uspCreateSCR_PTL_Statistics


/************************************************************************************************************************************************************************************************************
-- Setup variables for the procedure
************************************************************************************************************************************************************************************************************/

		DECLARE @DimensionGroupsInsert varchar(max)
		DECLARE @DimensionGroupsSelect varchar(max)
		DECLARE @DimensionGroupsMatchOn varchar(max)
		DECLARE @DimensionGroupsNoMatchOn varchar(max)
		DECLARE @DimensionGroupsSQL varchar(max)

/************************************************************************************************************************************************************************************************************
-- Find the field names we will be working with
************************************************************************************************************************************************************************************************************/

		-- Drop the #CommonNames table if it exists
		IF OBJECT_ID('tempdb..#CommonNames') IS NOT NULL
		DROP TABLE #CommonNames
	
		-- Create table of common fields between measure table and dimension groups
		SELECT		c.name
		INTO		#CommonNames
		FROM		(SELECT		name
								,object_id
								,schema_id
					FROM		sys.tables
					UNION ALL
					SELECT		name
								,object_id
								,schema_id
					FROM		sys.views) t
		INNER JOIN	sys.columns c
						ON	t.object_id = c.object_id
		INNER JOIN	sys.schemas s
						ON	t.schema_id = s.schema_id
		WHERE		(t.name = 'SCR_PTL_Statistics_View' 
		AND			s.name = 'LocalConfig')
		OR			(t.name = 'SCR_PTL_StatisticsDimensionGroups'
		AND			s.name = 'LocalConfig')
		AND			c.name not in ('StatisticsDimensionGroupId')
		GROUP BY	c.name
		HAVING		Count(*) >1

		-- Drop the #DimensionFieldNames if it exists
		IF OBJECT_ID('tempdb..#DimensionFieldNames') IS NOT NULL 
		DROP TABLE #DimensionFieldNames
		
		-- Create table of Dimension field names
		SELECT		c.name
		INTO		#DimensionFieldNames
		FROM		sys.tables t
		INNER JOIN	sys.columns c
						ON	t.object_id = c.object_id
		INNER JOIN	sys.schemas s
						ON	t.schema_id = s.schema_id
		WHERE		(t.name = 'SCR_PTL_StatisticsDimensionGroups'
		AND			s.name = 'LocalConfig')
		AND			c.name not in ('StatisticsDimensionGroupId')

/************************************************************************************************************************************************************************************************************
-- Identify snapshots to be loaded and Remove any snapshots that are being reloaded
************************************************************************************************************************************************************************************************************/

		-- Drop the #LoadOrReload if it exists
		IF OBJECT_ID('tempdb..#LoadOrReload') IS NOT NULL 
		DROP TABLE #LoadOrReload
		
		-- Find the unloaded snapshots and snapshots to be reloaded
		SELECT		COALESCE(stat.PtlSnapshotId, snap.PtlSnapshotId, hist.PtlSnapshotId) AS PtlSnapshotId
					,SUM(CASE WHEN stat.PtlSnapshotId IS NOT NULL THEN 1 ELSE 0 END) AS RecordsInStatisticsTable
					,SUM(CASE WHEN hist.PtlSnapshotId IS NOT NULL THEN 1 ELSE 0 END) AS RecordsInHistoryTable
					,SUM(ISNULL(CAST(snap.LoadedIntoStatistics AS int),0)) AS LoadedIntoStatistics
		INTO		#LoadOrReload
		FROM		(SELECT		PtlSnapshotId
					FROM		SCR_Reporting_History.SCR_PTL_Statistics
					GROUP BY	PtlSnapshotId) stat
		FULL JOIN	SCR_Reporting_History.SCR_PTL_SnapshotDates snap
						ON	stat.PtlSnapshotId = snap.PtlSnapshotId
		FULL JOIN	(SELECT		PtlSnapshotId
					FROM		SCR_Reporting_History.SCR_PTL_History
					GROUP BY	PtlSnapshotId) hist
						ON	stat.PtlSnapshotId = hist.PtlSnapshotId
		GROUP BY	COALESCE(stat.PtlSnapshotId, snap.PtlSnapshotId, hist.PtlSnapshotId)
		ORDER BY	COALESCE(stat.PtlSnapshotId, snap.PtlSnapshotId, hist.PtlSnapshotId)

		-- Begin a TRY-CATCH to rollback if an error occurs in the transaction
		BEGIN TRY
		
			-- Begin a transaction to ensure that the process completes before deleted records are actually committed
			BEGIN TRANSACTION

				-- Delete statistics for records that are to be reloaded (and can be)
				DELETE
				FROM		stat
				FROM		#LoadOrReload reload
				INNER JOIN	SCR_Reporting_History.SCR_PTL_Statistics stat
								ON	reload.PtlSnapshotId = stat.PtlSnapshotId
				WHERE		reload.RecordsInStatisticsTable = 1
				AND			reload.RecordsInHistoryTable = 1
				AND			reload.LoadedIntoStatistics = 0

/************************************************************************************************************************************************************************************************************
-- Create dynamic SQL code to create the aggregated dataset we will use to populate the PTL Statistics datasets
************************************************************************************************************************************************************************************************************/


				-- Drop the SCR_PTL_Statistics_work table if it exists
				IF OBJECT_ID('SCR_Reporting_History.SCR_PTL_Statistics_work') IS NOT NULL
				DROP TABLE SCR_Reporting_History.SCR_PTL_Statistics_work
		
				-- Concatenate the common fields between the StatisticsDimensionGroupId table and SCR_Reporting_History table to create a select statement for the PTL statistics
				SELECT		@DimensionGroupsSelect = 
							CAST
							(
								(
								SELECT		CHAR(10) + 
											'			,hist.' +
											'[' + DimensionFieldName + ']'
								FROM		(SELECT		rn = row_number() over (partition by 1 order by cn.name)
														,DimensionFieldName = cn.name	
											FROM		#CommonNames cn
											) fn
								ORDER BY	fn.rn
								FOR XML PATH('')
								) AS varchar(max)
							)

				-- Create a SQL statement to insert new combinations of dimenstions from the SCR_Reporting_History table into the 
				SET			@DimensionGroupsSQL =	CAST('SELECT		hist.PtlSnapshotId' AS varchar(max)) + 
													CAST(@DimensionGroupsSelect + ' ' + CHAR(10) AS varchar(max)) + 
													CAST('			,COUNT(*) AS PtlRecordCount ' + CHAR(10) AS varchar(max)) + 
													CAST('INTO		SCR_Reporting_History.SCR_PTL_Statistics_work ' + CHAR(10) AS varchar(max)) + 
													CAST('FROM		LocalConfig.SCR_PTL_Statistics_View hist ' + CHAR(10) AS varchar(max)) + 
													CAST('INNER JOIN	#LoadOrReload ToLoad ' + CHAR(10) AS varchar(max)) + 
													CAST('				ON	hist.PtlSnapshotId = ToLoad.PtlSnapshotId ' + CHAR(10) AS varchar(max)) + 
													CAST('				AND	ToLoad.RecordsInHistoryTable = 1 ' + CHAR(10) AS varchar(max)) + 
													CAST('				AND	ToLoad.LoadedIntoStatistics = 0 ' + CHAR(10) AS varchar(max)) + 
													CAST('WHERE		ToLoad.LoadedIntoStatistics = 0 ' + CHAR(10) AS varchar(max)) + 
													CAST('GROUP BY	hist.PtlSnapshotId' AS varchar(max)) + 
													CAST(@DimensionGroupsSelect AS varchar(max))

				-- Execute the SQL statement to create and aggregate the statistics from the SCR_Reporting_History table
				SELECT @DimensionGroupsSQL
				EXEC (@DimensionGroupsSQL)

/************************************************************************************************************************************************************************************************************
-- Create the dynamic SQL code which will identify new combinations of dimensions and add them to the StatisticsDimensionGroups table
************************************************************************************************************************************************************************************************************/
	
				-- Concatenate the common fields between the StatisticsDimensionGroups table and SCR_Reporting_History table to create an insert statement for the PTL statistics
				SELECT		@DimensionGroupsInsert = 
							CAST
							(
								(
								SELECT		CHAR(10) + 
											CASE WHEN fn.rn = 1
											THEN
											''
											ELSE
											','
											END + 
											'[' + DimensionFieldName + ']'
								FROM		(SELECT		rn = row_number() over (partition by 1 order by cn.name)
														,DimensionFieldName = cn.name	
											FROM		#CommonNames cn
											) fn
								ORDER BY	fn.rn
								FOR XML PATH('')
								) AS varchar(max)
							)
		
				-- Concatenate the common fields between the StatisticsDimensionGroups table and SCR_Reporting_History table to create a select statement for the PTL statistics
				SELECT		@DimensionGroupsSelect = 
							CAST
							(
								(
								SELECT		CHAR(10) + 
											CASE WHEN fn.rn = 1
											THEN
											'stat.'
											ELSE
											',stat.'
											END + 
											'[' + DimensionFieldName + ']'
								FROM		(SELECT		rn = row_number() over (partition by 1 order by cn.name)
														,DimensionFieldName = cn.name	
											FROM		#CommonNames cn
											) fn
								ORDER BY	fn.rn
								FOR XML PATH('')
								) AS varchar(max)
							)
		
				-- Concatenate the fields in the StatisticsDimensionGroups table that aren't in the SCR_Reporting_History table to create a join statement 
				-- that only looks at combinations in StatisticsDimensionGroups that have null values for those fields
				SELECT		@DimensionGroupsNoMatchOn = 
							ISNULL(CAST
							(
								(
								SELECT		CHAR(10) + 
											CASE	WHEN fn.rn = 1 
													THEN 
													'ON		DimGroups.[' + DimensionFieldName + '] IS NULL ' 
													ELSE
													'AND		DimGroups.[' + DimensionFieldName + '] IS NULL ' 
													END
								FROM		(SELECT		rn = row_number() over (order by dfn.name ASC)
														,rnrev = row_number() over (order by dfn.name DESC)
														,DimensionFieldName = dfn.name	
											FROM		#DimensionFieldNames dfn
											LEFT JOIN	#CommonNames cn
															ON	dfn.name = cn.name
											WHERE		cn.name IS NULL
											) fn
								--WHERE		df1.name = df2.name
								ORDER BY	fn.rn
								FOR XML PATH('')
								) AS varchar(max)
							), 'ON 1=1 ')
		
				-- Concatenate the common fields between the StatisticsDimensionGroups table and SCR_Reporting_History table to create a join statement 
				-- that looks for new combinations of dimensions
				SELECT		@DimensionGroupsMatchOn = 
							CAST
							(
								(
								SELECT		CHAR(10) + 
											'AND		(stat.[' + DimensionFieldName + '] = DimGroups.[' + DimensionFieldName + '] ' + CHAR(10) + 
											'OR		(stat.[' + DimensionFieldName + '] IS NULL AND DimGroups.[' + DimensionFieldName + '] IS NULL)) ' + CHAR(10)
								FROM		(SELECT		rn = row_number() over (order by cn.name ASC)
														,DimensionFieldName = cn.name	
											FROM		#CommonNames cn
											) fn
								--WHERE		df1.name = df2.name
								ORDER BY	fn.rn
								FOR XML PATH('')
								) AS varchar(max)
							)

				-- Create a SQL statement to identify new combinations of dimensions and add them to the StatisticsDimensionGroups table
				SET			@DimensionGroupsSQL =	CAST('INSERT INTO LocalConfig.SCR_PTL_StatisticsDimensionGroups (' AS varchar(max)) + 
													CAST(@DimensionGroupsInsert + ') ' + CHAR(10) AS varchar(max)) +
													CAST('SELECT		DISTINCT ' AS varchar(max)) + 
													CAST(@DimensionGroupsSelect + ' ' + CHAR(10) AS varchar(max)) +
													CAST('FROM		SCR_Reporting_History.SCR_PTL_Statistics_work stat ' + CHAR(10) AS varchar(max)) +
													CAST('LEFT JOIN	LocalConfig.SCR_PTL_StatisticsDimensionGroups DimGroups ' AS varchar(max)) + 
													CAST(@DimensionGroupsNoMatchOn AS varchar(max)) + 
													CAST(@DimensionGroupsMatchOn AS varchar(max)) + 
													CAST('WHERE		DimGroups.StatisticsDimensionGroupId IS NULL' AS varchar(max))

				-- Execute the SQL statement to identify new combinations of dimensions and add them to the StatisticsDimensionGroups table
				SELECT @DimensionGroupsSQL
				EXEC (@DimensionGroupsSQL)
				
/************************************************************************************************************************************************************************************************************
-- Create the dynamic SQL code which will assign the StatisticsDimensionGroupId to records in the SCR_Reporting_History.SCR_PTL_Statistics_work table
************************************************************************************************************************************************************************************************************/
	
				-- Add the StatisticsDimensionGroupId field to the SCR_Reporting_History.SCR_PTL_Statistics_work table
				ALTER TABLE SCR_Reporting_History.SCR_PTL_Statistics_work ADD StatisticsDimensionGroupId int NULL
		
				-- Create a SQL statement to assign the StatisticsDimensionGroupId to records in the SCR_Reporting_History.SCR_PTL_Statistics_work table
				SET			@DimensionGroupsSQL =	CAST('UPDATE stat ' + CHAR(10) AS varchar(max)) +
													CAST('SET		StatisticsDimensionGroupId = DimGroups.StatisticsDimensionGroupId' + CHAR(10) AS varchar(max)) +
													CAST('FROM		SCR_Reporting_History.SCR_PTL_Statistics_work stat ' + CHAR(10) AS varchar(max)) +
													CAST('INNER JOIN	LocalConfig.SCR_PTL_StatisticsDimensionGroups DimGroups ' AS varchar(max)) + 
													CAST(@DimensionGroupsNoMatchOn AS varchar(max)) + 
													CAST(@DimensionGroupsMatchOn AS varchar(max))

				-- Execute the SQL statement to identify new combinations of dimensions and add them to the StatisticsDimensionGroups table
				SELECT @DimensionGroupsSQL
				EXEC (@DimensionGroupsSQL) 

/************************************************************************************************************************************************************************************************************
-- Insert the records in the SCR_Reporting_History.SCR_PTL_Statistics_work table into the SCR_PTL_Statistics table
************************************************************************************************************************************************************************************************************/

				-- Insert the records in the SCR_Reporting_History.SCR_PTL_Statistics_work table
				INSERT INTO SCR_Reporting_History.SCR_PTL_Statistics (
							PtlSnapshotId
							,StatisticsDimensionGroupId
							,PtlRecordCount
							)
				SELECT		PtlSnapshotId
							,StatisticsDimensionGroupId
							,PtlRecordCount
				FROM		SCR_Reporting_History.SCR_PTL_Statistics_work


/************************************************************************************************************************************************************************************************************
-- Tidy up
************************************************************************************************************************************************************************************************************/

				-- Drop the SCR_PTL_Statistics_work table if it exists
				IF OBJECT_ID('SCR_Reporting_History.SCR_PTL_Statistics_work') IS NOT NULL
				DROP TABLE SCR_Reporting_History.SCR_PTL_Statistics_work

				-- Mark the inserted snapshots as being in the SCR_PTL_Statistics table
				UPDATE		snap
				SET			LoadedIntoStatistics = 1
				FROM		SCR_Reporting_History.SCR_PTL_SnapshotDates snap
				INNER JOIN	#LoadOrReload ToLoad
								ON	snap.PtlSnapshotId = ToLoad.PtlSnapshotId

			-- Commit the transaction
			PRINT 'Committal of updated statistics at ' + CONVERT(varchar(255), GETDATE(), 126)
			COMMIT TRANSACTION

		-- End try block
		END TRY

		-- In case the transaction failed 
		BEGIN CATCH

			IF @@TRANCOUNT > 0 -- SELECT @@TRANCOUNT
				PRINT 'Rolling back because of error in updating statistics at ' + CONVERT(varchar(255), GETDATE(), 126)
				ROLLBACK TRANSACTION
 
			SELECT ERROR_NUMBER() AS ErrorNumber
			SELECT ERROR_MESSAGE() AS ErrorMessage
 
		END CATCH	





































GO
