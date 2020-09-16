
USE [msdb]
GO

/****** Object:  Job [Cancer Reporting Data (daily)]    Script Date: 03/09/2020 14:28:38 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 03/09/2020 14:28:38 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Cancer Reporting Data (daily)', 
              @enabled=1, 
              @notify_level_eventlog=0, 
              @notify_level_email=0, 
              @notify_level_netsend=0, 
              @notify_level_page=0, 
              @delete_level=0, 
              @description=N'No description available.', 
              @category_name=N'[Uncategorized (Local)]', 
              @owner_login_name=N'BSUH\Lawrence.Simpson', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run USP create Somerset Reporting data]    Script Date: 03/09/2020 14:28:38 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run USP create Somerset Reporting data', 
              @step_id=1, 
              @cmdexec_success_code=0, 
              @on_success_action=1, 
              @on_success_step_id=0, 
              @on_fail_action=2, 
              @on_fail_step_id=0, 
              @retry_attempts=0, 
              @retry_interval=0, 
              @os_run_priority=0, @subsystem=N'TSQL', 
              @command=N'EXEC CancerReporting.SCR_Warehouse.uspScheduleSomersetReportingData', 
              @database_name=N'CancerReporting', 
              @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Cancer Reporting (Near-real time)', 
              @enabled=1, 
              @freq_type=4, 
              @freq_interval=1, 
              @freq_subday_type=4, 
              @freq_subday_interval=1, 
              @freq_relative_interval=0, 
              @freq_recurrence_factor=0, 
              @active_start_date=20190926, 
              @active_end_date=99991231, 
              @active_start_time=0, 
              @active_end_time=235959, 
              @schedule_uid=N'45c552ac-73f7-41ae-9c2d-b94980b998a1'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Cancer Reporting Daily', 
              @enabled=0, 
              @freq_type=4, 
              @freq_interval=1, 
              @freq_subday_type=1, 
              @freq_subday_interval=0, 
              @freq_relative_interval=0, 
              @freq_recurrence_factor=0, 
              @active_start_date=20190618, 
              @active_end_date=99991231, 
              @active_start_time=50000, 
              @active_end_time=235959, 
              @schedule_uid=N'b3944d42-0174-4f37-887b-817dfa5bf7ab'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO
