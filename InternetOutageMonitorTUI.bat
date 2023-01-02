@ECHO OFF
SETLOCAL EnableDelayedExpansion
TITLE Internet Outage Monitoring - Initialising
COLOR 1B

::::::::::::::::::::::::::::::::::::::::::::
SET "LogFile=.\InternetOutage!DATE!.log"
SET "Server1=1.0.0.1" ::: Cloudflare DNS
SET "Server2=8.8.8.8" ::: Google Public DNS
SET "Server3=9.9.9.9" ::: Quad9 DNS
::::::::::::::::::::::::::::::::::::::::::::

SET "DefaultTimeout=60"
SET "Minutes=0"
SET "InternetConnectedFlag=true"

CALL :SetGraphics
CALL :DecideConnType
CALL :InitDispEng

:MAIN
CALL :DecideConnType
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
			REM ECHO.Event was written into "!LogFile!".
			REM ECHO.The connection was re-established.
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
CALL :GetDate
CALL :GetTime
IF EXIST "!LogFile!" (
	ECHO.[WARN][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] No connection to the Internet. This happened !Minutes! minutes ago. Start of the outage: !InternetOutageStartPoint!>>"!LogFile!"
) ELSE (
	ECHO.Internet Outage Monitoring>"!LogFile!"
	ECHO.-------------------------->>"!LogFile!"
	ECHO.[WARN][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] No connection to the Internet. This happened !Minutes! minutes ago. Start of the outage: !InternetOutageStartPoint!>>"!LogFile!"
)
EXIT /B

:LogConnSwitch
SET "ConnSwitchFrom=%~1"
SET "ConnSwitchTo=%~2"
IF /i "!ConnSwitchFrom!"=="!ConnSwitchTo!" (
	EXIT /B
)
CALL :GetDate
CALL :GetTime
IF "!ConnSwitchTo!"=="Timeout" (
	IF EXIST "!LogFile!" (
		ECHO.[INFO][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] Connection !ConnSwitchFrom! timed out.>>"!LogFile!"
		EXIT /B
	) ELSE (
		ECHO.Internet Outage Monitoring>"!LogFile!"
		ECHO.-------------------------->>"!LogFile!"
		ECHO.[INFO][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] Connection !ConnSwitchFrom! timed out.>>"!LogFile!"
		EXIT /B
	)
) ELSE IF "!ConnSwitchFrom!"=="Timeout" (
	IF EXIST "!LogFile!" (
		ECHO.[INFO][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] Connection !ConnSwitchTo! was reestablished.>>"!LogFile!"
		EXIT /B
	) ELSE (
		ECHO.Internet Outage Monitoring>"!LogFile!"
		ECHO.-------------------------->>"!LogFile!"
		ECHO.[INFO][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] Connection !ConnSwitchTo! was reestablished.>>"!LogFile!"
		EXIT /B
	)
)
IF EXIST "!LogFile!" (
	ECHO.[INFO][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] Connection switched from !ConnSwitchFrom! to !ConnSwitchTo!.>>"!LogFile!"
	EXIT /B
) ELSE (
	ECHO.Internet Outage Monitoring>"!LogFile!"
	ECHO.-------------------------->>"!LogFile!"
	ECHO.[INFO][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] Connection switched from !ConnSwitchFrom! to !ConnSwitchTo!.>>"!LogFile!"
	EXIT /B
)
EXIT /B

:SetGraphics
SET "SPACER=                                       "
SET "DIV_LINE=ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ"
SET "CABLE_INTACT_L1=   ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ   "
SET "CABLE_INTACT_L2=  ß±²±²±²±²±²±²±²±²±²±²±²±²±²±²±²±²±²ß  "
SET "CABLE_INTACT_L3=ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ"
SET "CABLE_INTACT_L4=ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß"
SET "CABLE_INTACT_L5=  Ü²±²±²±²±²±²±²±²±²±²±²±²±²±²±²±²±²±Ü  "
SET "CABLE_INTACT_L6=   ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß   "
SET "CABLE_BROKEN_L1=   ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ Û ÜÜÜÜÜÜÜÜÜÜÜÜÜ   "
SET "CABLE_BROKEN_L2=  ß±²±²±²±²±²±²±²±²± Û ±²±²±²±²±²±²±²ß  "
SET "CABLE_BROKEN_L3=ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ Û ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ"
SET "CABLE_BROKEN_L4=ßßßßßßßßßßßßßßßßßß Û ßßßßßßßßßßßßßßßßßßß"
SET "CABLE_BROKEN_L5=  Ü²±²±²±²±²±²±²± Û ±²±²±²±²±²±²±²±²±Ü  "
SET "CABLE_BROKEN_L6=   ßßßßßßßßßßßßß Û ßßßßßßßßßßßßßßßßßß   "
SET "WRLSS_INTACT_L1=              ßßßßßÜ                    "
SET "WRLSS_INTACT_L2=              ßßßßÜ ßÜ                  "
SET "WRLSS_INTACT_L3=              ßßßÜ ßÜ ßÜ                "
SET "WRLSS_INTACT_L4=              ßßÜ ßÜ ßÜ Û               "
SET "WRLSS_INTACT_L5=             ÜÛÛÜßÜ Û Û Û               "
SET "WRLSS_INTACT_L6=             ßÛÛß ß ß ß ß               "
SET "WRLSS_BROKEN_L1=              ßßßßßÜ  Û                 "
SET "WRLSS_BROKEN_L2=              ßßßßÜ  Û                  "
SET "WRLSS_BROKEN_L3=              ßßßÜ  Û  Ü                "
SET "WRLSS_BROKEN_L4=              ßßÜ  Û  Ü Û               "
SET "WRLSS_BROKEN_L5=             ÜÛÛ  Û   Û Û               "
SET "WRLSS_BROKEN_L6=             ßÛ  Û  ß ß ß               "
SET "QUESTIONMARK_L1=                ÜÜßßßßÜÜ                "
SET "QUESTIONMARK_L2=                ßß    ÛÛ                "
SET "QUESTIONMARK_L3=                    ÜÛß                 "
SET "QUESTIONMARK_L4=                   ÜÛß                  "
SET "QUESTIONMARK_L5=                   ßß                   "
SET "QUESTIONMARK_L6=                   ÛÛ                   "
SET "STATUS_INTACT=          Internet available.           "
SET "STATUS_BROKEN=        Internet not available.         "
SET "STATUS_QUESTN=                   ??                   "
SET "NORECORD_L17=        Ûß                    ßÛ        "
SET "NORECORD_L18=        Û     No records.      Û        "
SET "NORECORD_L19=        ÛÜ                    ÜÛ        "
EXIT /B

:DecideConnType
IF DEFINED ConnType (
	SET "OldConnType=!ConnType!"
	SET "LogSwitch=true"
)
::: Get Router IP address once
IF NOT DEFINED RouterIPv4 (
	FOR /f "tokens=2,3 delims={,}" %%A IN ('"WMIC NICConfig where IPEnabled="True" get DefaultIPGateway /value | find "I" "') DO (
		SET "RouterIPv4=%%~A"
		SET "RouterIPv6=%%~B"
	)
)
IF NOT DEFINED RouterIPv4 (
	IF NOT DEFINED RouterIPv6 (
		SET "ConnType=Unknown"
		EXIT /b
	)
	::: Latency based connection type guess - IPv6
	PING %RouterIPv6% -n 1 -6 | FINDSTR /C:"1ms" 1>nul
	IF ERRORLEVEL 1 (
		PING %RouterIPv6% -n 1 -6 | FINDSTR /C:"TTL=" 1>nul
		IF ERRORLEVEL 1 ( SET "ConnType=Timeout" ) ELSE ( SET "ConnType=WiFi" )
	) ELSE ( SET "ConnType=Ethernet" )
) ELSE (
	::: Latency based connection type guess - IPv4
	PING %RouterIPv4% -n 1 -4 | FINDSTR /C:"1ms" 1>nul
	IF ERRORLEVEL 1 (
		PING %RouterIPv4% -n 1 -4 | FINDSTR /C:"TTL=" 1>nul
		IF ERRORLEVEL 1 ( SET "ConnType=Timeout" ) ELSE ( SET "ConnType=WiFi" )
	) ELSE ( SET "ConnType=Ethernet" )
)
IF "!LogSwitch!"=="true" (
	IF "!OldConnType!" NEQ "!ConnType!" (
		CALL :LogConnSwitch "!OldConnType!" "!ConnType!"
	)
) ELSE (
	CALL :GetDate
	CALL :GetTime
	IF EXIST "!LogFile!" (
		ECHO.[INFO][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] Initial detected connection type: !ConnType!>>"!LogFile!"
		EXIT /B
	) ELSE (
		ECHO.Internet Outage Monitoring>"!LogFile!"
		ECHO.-------------------------->>"!LogFile!"
		ECHO.[INFO][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] Initial detected connection type: !ConnType!>>"!LogFile!"
		EXIT /B
	)
)
EXIT /B

:InitDispEng
MODE 120,31
CLS
SET "WRITABLE_LINES=30"
SET "WRITABLE_CHARS=119"
SET "STATUS_PANEL_LINE_END=8"
SET "LOG_PANEL_LINE_END=29"
SET "L0=!SPACER!!STATUS_QUESTN!Connection type: !ConnType!"
SET "L8=!DIV_LINE!"
FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
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
	:::Title
	TITLE Internet Outage Monitoring - Internet not available since !Minutes! minutes ago. Start: !InternetOutageStartPoint!
	:::Status
	SET "L0=!SPACER!!STATUS_BROKEN!"
	:::Connection type switch
	IF "!ConnType!"=="Ethernet" (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED L%%A (
				ECHO.!L%%A!
			) ELSE IF DEFINED CABLE_BROKEN_L%%A (
				ECHO.!SPACER!!CABLE_BROKEN_L%%A!
			)
		)
	) ELSE IF "!ConnType!"=="WiFi" (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED L%%A (
				ECHO.!L%%A!
			) ELSE IF DEFINED WRLSS_BROKEN_L%%A (
				ECHO.!SPACER!!WRLSS_BROKEN_L%%A!
			)
		)
	) ELSE (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED L%%A (
				ECHO.!L%%A!
			) ELSE IF DEFINED QUESTIONMARK_L%%A (
				ECHO.!SPACER!!QUESTIONMARK_L%%A!
			)
		)
	)
	:::Log display
	FOR /L %%A IN (9,1,!LOG_PANEL_LINE_END!) DO (
		ECHO.
	)
	REM ECHO.No connection to the Internet. This happened !Minutes! minutes ago. Start of the outage: !InternetOutageStartPoint!
) ELSE IF DEFINED InternetOutageStartPoint (
	:::Title
	TITLE Internet Outage Monitoring - Internet available. Last outage: !InternetOutageStartPoint!
	:::Status
	SET "L0=!SPACER!!STATUS_INTACT!"
	:::Connection type switch
	IF "!ConnType!"=="Ethernet" (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED L%%A (
				ECHO.!L%%A!
			) ELSE IF DEFINED CABLE_INTACT_L%%A (
				ECHO.!SPACER!!CABLE_INTACT_L%%A!
			)
		)
	) ELSE IF "!ConnType!"=="WiFi" (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED L%%A (
				ECHO.!L%%A!
			) ELSE IF DEFINED WRLSS_INTACT_L%%A (
				ECHO.!SPACER!!WRLSS_INTACT_L%%A!
			)
		)
	) ELSE (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED L%%A (
				ECHO.!L%%A!
			) ELSE IF DEFINED QUESTIONMARK_L%%A (
				ECHO.!SPACER!!QUESTIONMARK_L%%A!
			)
		)
	)
	FOR /L %%A IN (9,1,!LOG_PANEL_LINE_END!) DO (
		ECHO.
	)
) ELSE (
	:::Title
	TITLE Internet Outage Monitoring - Internet available.
	:::Status
	SET "L0=!SPACER!!STATUS_INTACT!"
	:::Connection type switch
	IF "!ConnType!"=="Ethernet" (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED L%%A (
				ECHO.!L%%A!
			) ELSE IF DEFINED CABLE_INTACT_L%%A (
				ECHO.!SPACER!!CABLE_INTACT_L%%A!
			)
		)
	) ELSE IF "!ConnType!"=="WiFi" (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED L%%A (
				ECHO.!L%%A!
			) ELSE IF DEFINED WRLSS_INTACT_L%%A (
				ECHO.!SPACER!!WRLSS_INTACT_L%%A!
			)
		)
	) ELSE (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED L%%A (
				ECHO.!L%%A!
			) ELSE IF DEFINED QUESTIONMARK_L%%A (
				ECHO.!SPACER!!QUESTIONMARK_L%%A!
			)
		)
	)
	FOR /L %%A IN (9,1,!LOG_PANEL_LINE_END!) DO (
		IF DEFINED NORECORD_L%%A (
			ECHO.!SPACER!!NORECORD_L%%A!
		) ELSE ( ECHO. )
	)
)
EXIT /B

:ManageLogging

EXIT /B