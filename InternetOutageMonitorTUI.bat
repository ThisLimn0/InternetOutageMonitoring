@ECHO OFF
SETLOCAL EnableDelayedExpansion
TITLE Internet Uptime Monitoring - Initialising
COLOR 1B

::::::::::::::::::::::::::::::::::::::::::::
SET "Server1=8.8.8.8" ::: Google Public DNS
SET "Server2=1.0.0.1" ::: Cloudflare DNS
SET "Server3=9.9.9.9" ::: Quad9 DNS
::::::::::::::::::::::::::::::::::::::::::::

SET "DefaultTimeout=60"
SET "Minutes=0"
SET "InternetConnectedFlag=true"

CALL :SetGraphics
CALL :InitDispEng

:MAIN
SET "LogFile=.\InternetUptime!DATE!.log"
CALL :GetInternetConnection
CALL :Display
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
			SET "InternetOutageStartPoint=!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!"
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
	ECHO.[WARN][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] No connection to the Internet. This happened !Minutes! ago. Start of the outage: !InternetOutageStartPoint! >>"!LogFile!"
) ELSE (
	ECHO.Internet Uptime Monitoring>"!LogFile!"
	ECHO.-------------------------->>"!LogFile!"
	ECHO.[WARN][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] No connection to the Internet. This happened !Minutes! ago. Start of the outage: !InternetOutageStartPoint! >>"!LogFile!"
)
EXIT /B


:SetGraphics
SET "SPACER=                                       "
SET "DIV_LINE=‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹"
SET "CABLE_INTACT_L1=   ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹   "
SET "CABLE_INTACT_L2=  ﬂ±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤ﬂ  "
SET "CABLE_INTACT_L3=‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹"
SET "CABLE_INTACT_L4=ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ"
SET "CABLE_INTACT_L5=  ‹≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±≤±‹  "
SET "CABLE_INTACT_L6=   ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ   "
SET "CABLE_BROKEN_L1=   ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ € ‹‹‹‹‹‹‹‹‹‹‹‹‹   "
SET "CABLE_BROKEN_L2=  ﬂ±≤±≤±≤±≤±≤±≤±≤±≤± € ±≤±≤±≤±≤±≤±≤±≤ﬂ  "
SET "CABLE_BROKEN_L3=‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ € ‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹"
SET "CABLE_BROKEN_L4=ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ € ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ"
SET "CABLE_BROKEN_L5=  ‹≤±≤±≤±≤±≤±≤±≤± € ±≤±≤±≤±≤±≤±≤±≤±≤±‹  "
SET "CABLE_BROKEN_L6=   ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ € ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ   "
SET "QUESTIONMARK_L1=                ‹‹ﬂﬂﬂﬂ‹‹                "
SET "QUESTIONMARK_L2=                ﬂﬂ    €€                "
SET "QUESTIONMARK_L3=                    ‹€ﬂ                 "
SET "QUESTIONMARK_L4=                   ‹€ﬂ                  "
SET "QUESTIONMARK_L5=                   ﬂﬂ                   "
SET "QUESTIONMARK_L6=                   €€                   "
SET "STATUS_INTACT=          Internet available.           "
SET "STATUS_BROKEN=        Internet not available.         "
SET "STATUS_QUESTN=                   ??                   "
SET "NORECORD_L1=        €ﬂ                    ﬂ€        "
SET "NORECORD_L2=        € No outages recorded. €        "
SET "NORECORD_L3=        €‹                    ‹€        "
EXIT /B

:InitDispEng
MODE 120,31
CLS
SET "WRITABLE_LINES=30"
SET "WRITABLE_CHARS=119"
SET "STATUS_PANEL_LINES=8"
SET "LOG_PANEL_LINES=22"
SET "L0=!SPACER!!STATUS_QUESTN!"
SET "L8=!DIV_LINE!"
FOR /L %%A IN (0,1,!STATUS_PANEL_LINES!) DO (
	IF DEFINED L%%A (
		ECHO.!L%%A!
	) ELSE IF DEFINED QUESTIONMARK_L%%A (
		ECHO.!SPACER!!QUESTIONMARK_L%%A!
	)
)
EXIT /B

:Display
CLS
IF /i "!InternetConnectedFlag!"=="false" (
	TITLE Internet Uptime Monitoring - Internet not available since !Minutes! minutes ago. Start: !InternetOutageStartPoint!
	SET "L0=!SPACER!!STATUS_BROKEN!"
	FOR /L %%A IN (0,1,!STATUS_PANEL_LINES!) DO (
		IF DEFINED L%%A (
			ECHO.!L%%A!
		) ELSE IF DEFINED CABLE_BROKEN_L%%A (
			ECHO.!SPACER!!CABLE_BROKEN_L%%A!
		)
	)
	REM ECHO.No connection to the Internet. This happened !Minutes! minutes ago. Start of the outage: !InternetOutageStartPoint!
) ELSE IF DEFINED InternetOutageStartPoint (
	TITLE Internet Uptime Monitoring - Internet available. Last outage: !InternetOutageStartPoint!
	SET "L0=!SPACER!!STATUS_INTACT!"
	FOR /L %%A IN (0,1,!STATUS_PANEL_LINES!) DO (
		IF DEFINED L%%A (
			ECHO.!L%%A!
		) ELSE IF DEFINED CABLE_INTACT_L%%A (
			ECHO.!SPACER!!CABLE_INTACT_L%%A!
		)
	)
) ELSE (
	TITLE Internet Uptime Monitoring - Internet available.
	SET "L0=!SPACER!!STATUS_INTACT!"
	FOR /L %%A IN (0,1,!STATUS_PANEL_LINES!) DO (
		IF DEFINED L%%A (
			ECHO.!L%%A!
		) ELSE IF DEFINED CABLE_INTACT_L%%A (
			ECHO.!SPACER!!CABLE_INTACT_L%%A!
		)
	)
)
EXIT /B