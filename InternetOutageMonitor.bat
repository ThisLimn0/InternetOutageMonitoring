@ECHO OFF
SETLOCAL EnableDelayedExpansion
MODE 60,20
COLOR 1B
TITLE Internet Outage Monitoring - Initialising

::::::::::::::::::::::::::::::::::::::::::::
SET "LogFile=.\InternetOutage!DATE!.log"
SET "Server1=8.8.8.8" ::: Google Public DNS
SET "Server2=1.0.0.1" ::: Cloudflare DNS
SET "Server3=9.9.9.9" ::: Quad9 DNS
::::::::::::::::::::::::::::::::::::::::::::

SET "InitialTimeout=30"
SET "DefaultTimeout=60"
SET "Minutes=0"
SET "Once=true"
SET "InternetConnectedFlag=true"




TITLE Internet Outage Monitoring - Initial delay. Please wait !InitialTimeout! seconds.
TIMEOUT /T !InitialTimeout! /NOBREAK >NUL
:MAIN
CALL :GetInternetConnection

IF /i "!InternetConnectedFlag!"=="false" (
	TITLE No Internet. Since !Minutes! minutes ago. Start: !InternetOutageStartPoint!
	ECHO.No Internet. Since !Minutes! minutes ago. Start: !InternetOutageStartPoint!
) ELSE IF DEFINED InternetOutageStartPoint (
	TITLE Internet Outage Monitoring - Internet available. Last outage: !InternetOutageStartPoint!
) ELSE (
	TITLE Internet Outage Monitoring - Internet available.
)

TIMEOUT /T !ModifiedTimeout! /NOBREAK >NUL
GOTO :MAIN

:GetInternetConnection
IF /i "!InternetConnectedFlag!"=="true" (
	SET "Minutes=0"
)
SET "ModifiedTimeout=!DefaultTimeout!"
FOR %%X IN (!Server1! !Server2! !Server3!) DO (
	PING -n 2 -w 1000 %%X | FIND /i "bytes=" >NUL
	SET /A "ModifiedTimeout-=2"
	IF !ERRORLEVEL! EQU 0 (
		IF /i "!InternetConnectedFlag!"=="false" (
			CALL :GetDate
			CALL :GetTime
			CALL :LogData
			ECHO.Event was written into "!LogFile!".
			ECHO.The connection was re-established.
			SET /A "ModifiedTimeout-=2"
		)
		SET "InternetConnectedFlag=true"
		GOTO :EOF
	) ELSE (
		IF  /i "!InternetConnectedFlag!"=="true" (
			CALL :GetDate
			CALL :GetTime
			SET "InternetOutageStartPoint=!DD!.!MO!.!YYYY! !HH!:!MI!:!SS!"
			SET "InternetConnectedFlag=false"
		)
		SET "InternetConnectedFlag=false"
	)
)
IF /i "!InternetConnectedFlag!"=="false" (
	SET /A "Minutes+=1"
)
EXIT /B

:GetDate
SET "TmpDate=!DATE!"
SET "DD=!TmpDate:~0,2!"
SET "MO=!TmpDate:~3,2!"
SET "YYYY=!TmpDate:~6,4!"
EXIT /B

:GetTime
SET "TmpTime=!TIME!"
SET "HH=!TmpTime:~0,2!"
SET "MI=!TmpTime:~3,2!"
SET "SS=!TmpTime:~6,2!"
EXIT /B

:LogData
IF EXIST "!LogFile!" (
	ECHO.[WARN][!DD!.!MO!.!YYYY! !HH!:!MI!:!SS!] No connection to the Internet. This happened !Minutes! ago. Start of the outage: !InternetOutageStartPoint! >>"!LogFile!"
) ELSE (
	ECHO.Internet Outage Monitoring>"!LogFile!"
	ECHO.-------------------------->>"!LogFile!"
	ECHO.[WARN][!DD!.!MO!.!YYYY! !HH!:!MI!:!SS!] No connection to the Internet. This happened !Minutes! ago. Start of the outage: !InternetOutageStartPoint! >>"!LogFile!"
)
EXIT /B
