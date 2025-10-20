/*
Enter custom T-SQL here that would run after SQL Server has started up. 
*/


USE [master]
GO

/* For security reasons the login is created disabled and with a random password. */

CREATE LOGIN [schematic] WITH PASSWORD='Abcd1234', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

ALTER LOGIN [schematic] ENABLE
GO

ALTER SERVER ROLE [sysadmin] ADD MEMBER [schematic]
GO


CREATE LOGIN [SVC_DS_DEPLOY] WITH PASSWORD='Abcd1234', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

ALTER LOGIN [SVC_DS_DEPLOY] ENABLE
GO

USE msdb
GO

CREATE USER [SVC_DS_DEPLOY] FOR LOGIN [SVC_DS_DEPLOY]
GO

ALTER ROLE SQLAgentOperatorRole ADD MEMBER [SVC_DS_DEPLOY]
GO

GRANT SELECT ON msdb.dbo.sysjobs TO [SVC_DS_DEPLOY];
GO
GRANT SELECT ON msdb.dbo.syscategories TO[SVC_DS_DEPLOY];
GO
GRANT EXECUTE ON msdb.dbo.sp_delete_job TO [SVC_DS_DEPLOY];
GO
GRANT EXECUTE ON msdb.dbo.sp_add_category TO [SVC_DS_DEPLOY];
GO
GRANT EXECUTE ON msdb.dbo.sp_add_job TO [SVC_DS_DEPLOY];
GO
GRANT EXECUTE ON msdb.dbo.sp_add_jobstep TO [SVC_DS_DEPLOY];
GO
GRANT EXECUTE ON msdb.dbo.sp_update_job TO [SVC_DS_DEPLOY];
GO
GRANT EXECUTE ON msdb.dbo.sp_add_jobschedule TO [SVC_DS_DEPLOY];
GO
GRANT EXECUTE ON msdb.dbo.sp_add_jobserver TO [SVC_DS_DEPLOY];
GO