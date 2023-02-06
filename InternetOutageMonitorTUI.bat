@ECHO OFF
SETLOCAL EnableDelayedExpansion

COLOR 1B
TITLE Internet Outage Monitoring - Initialising

:::    /// ::::: /// :[IOMon]: /// ::::: /// :::
:::      A pure batch Internet outage monitor.
:::       only using the given windows utils.
:::
:::        (ccc)2023 by Limn0 @ NerdRevolt
:::
:::    /// ::: /// ::: /// ::: /// ::: /// :::

::::::::::::::::::::::::::::::::::::::::::::
SET "Logging=true"
SET "LogFile=.\InternetOutage!DATE!.log"
SET "Server1=1.0.0.1" ::: Cloudflare DNS
SET "Server2=8.8.8.8" ::: Google Public DNS
SET "Server3=9.9.9.9" ::: Quad9 DNS
::::::::::::::::::::::::::::::::::::::::::::

SET "MachineLog=.\IOMon.TUI"
SET "InitialTimeout=5"
SET "DefaultTimeout=60"
SET "Minutes=0"
SET "Once=true"
SET "InternetConnectedFlag=true"

CALL :SetGraphics
CALL :InitializeDisplay
CALL :InitialTimeout
CALL :DecideConnType

CALL :ClearLogging
CALL :ManageLogging "LOG_EVENT=RECORD_START" "LOG_CONNECTIONTYPE=!ConnType!"


:MAIN
CALL :DecideConnType
CALL :GetInternetConnection
CALL :GenerateLogView
CALL :Display
TIMEOUT /T !ModifiedTimeout! /NOBREAK >NUL
GOTO :MAIN


:DecideConnType
::: Get connection type once
SET "SHRT_CONNTYPE=UNKW"
IF DEFINED ConnType (
	SET "OldConnType=!ConnType!"
	SET "LogSwitch=true"
)
::: Get Router IP address once (IPv4 and IPv6)
IF NOT DEFINED RouterIPv4 (
	FOR /f "tokens=2,3 delims={,}" %%A IN ('"WMIC NICConfig where IPEnabled="True" get DefaultIPGateway /value | find "I" "') DO (
		SET "TmpIPv4=%%~A"
		IF DEFINED TmpIPv4 (
			SET "RouterIPv4=%%~A"
		)
		SET "TmpIPv6=%%~B"
		IF DEFINED TmpIPv6 (
			SET "RouterIPv6=%%~B"
		)
	)
)
:::If both IPv4 and IPv6 are not available, connection type is unknown.
IF NOT DEFINED RouterIPv4 (
	IF NOT DEFINED RouterIPv6 (
		SET "ConnType=Unknown"
		SET "SHRT_CONNTYPE=UNKW"
		EXIT /b
	)
	::: Latency based connection type guess - IPv6
	PING %RouterIPv6% -n 1 -6 | FINDSTR /R "\=1ms \<1ms" 1>nul
	IF ERRORLEVEL 1 (
		PING %RouterIPv6% -n 1 -6 | FINDSTR /C:"TTL=" 1>nul
		IF ERRORLEVEL 1 (
			SET "ConnType=Timeout"
			SET "SHRT_CONNTYPE=TOUT"
		) ELSE (
			SET "ConnType=WiFi"
			SET "SHRT_CONNTYPE=WIFI"
		)
	) ELSE (
		SET "ConnType=Ethernet"
		SET "SHRT_CONNTYPE=ETHR"
	)
) ELSE (
	::: Latency based connection type guess - IPv4
	PING %RouterIPv4% -n 1 -4 | FINDSTR /R "\=1ms \<1ms" 1>nul
	IF ERRORLEVEL 1 (
		PING %RouterIPv4% -n 1 -4 | FINDSTR /C:"TTL=" 1>nul
		IF ERRORLEVEL 1 (
			SET "ConnType=Timeout"
			SET "SHRT_CONNTYPE=TOUT"
		) ELSE (
			SET "ConnType=WiFi"
			SET "SHRT_CONNTYPE=WIFI"
		)
	) ELSE (
		SET "ConnType=Ethernet"
		SET "SHRT_CONNTYPE=ETHR"
	)
)
::: Deprecated logging function
IF "!LogSwitch!"=="true" (
	IF "!OldConnType!" NEQ "!ConnType!" (
		REM CALL :LogConnSwitch "!OldConnType!" "!ConnType!"
	)
) ELSE (
	CALL :DateTime
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


:GetInternetConnection
::: Reset internet outage start point if internet is available.
IF /i "!InternetConnectedFlag!"=="true" (
	SET "Minutes=0"
)
::: Reset the modified timeout value.
SET "ModifiedTimeout=!DefaultTimeout!"
::: Ping the three test servers. For each successful ping,
::: reduce the modified timeout value by 2 seconds.
FOR %%X IN (!Server1! !Server2! !Server3!) DO (
	PING -n 2 -w 1000 %%X | FIND /i "bytes=" >NUL
	SET /A "ModifiedTimeout-=2"
	IF !ERRORLEVEL! EQU 0 (
		IF /i "!InternetConnectedFlag!"=="false" (
			CALL :DateTime
			CALL :LogData
			SET /A "ModifiedTimeout-=2"
		)
		SET "InternetConnectedFlag=true"
		GOTO :EOF
	) ELSE (
		IF  /i "!InternetConnectedFlag!"=="true" (
			CALL :DateTime
			SET "InternetOutageStartPoint=!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!"
			SET "InternetConnectedFlag=false"
		)
		SET "InternetConnectedFlag=false"
	)
)
::: If all the pings fail increase the internet outage duration by 1 minute.
IF /i "!InternetConnectedFlag!"=="false" (
	SET /A "Minutes+=1"
)
EXIT /B


:DateTime
::: This function is used to get the current date and time.
::: SET VARIABLES: DD=Day, MO=Month, YY=ShortYear, YYYY=LongYear, HH=Hours, MI=Minutes, SS=Seconds, MS=Milliseconds
SET "TMPTime=!TIME!"
SET "TMPDate=!DATE!"
SET "HH=!TmpTime:~0,2!"
SET "MI=!TmpTime:~3,2!"
SET "SS=!TmpTime:~6,2!"
SET "MS=!TmpTime:~9,3!"
SET "DD=!TmpDate:~0,2!"
SET "MO=!TmpDate:~3,2!"
SET "YY=!TmpDate:~8,2!"
SET "YYYY=!TmpDate:~6,4!"
EXIT /B


:ClearLogging
:::Clear pure logging variables
SET "LOGGING_MODULES=LOG_EVENT LOG_CONNECTIONTYPE LOG_CONNECTIONTYPEOLD LOG_CONNECTIONTYPENEW LOG_DURATION"
FOR %%A IN (!LOGGING_MODULES!) DO (
	IF DEFINED %%A (
		SET "%%A="
	)
)
EXIT /B


:ManageLogging
:::Grab call arguments
FOR %%A IN (%*) DO (
	SET "%%~A"
)
:::If we aren't logging we won't bother with the rest
IF NOT "!Logging!"=="true" (
	EXIT /B
)
:::Grab current date and time
CALL :DateTime
:::Check for different LOG_EVENT types, and write a human readable
:::and a machine readable log for each.
IF "!LOG_EVENT!"=="RECORD_START" (
	ECHO.!YYYY!.!MO!.!DD!;!HH!:!MI!:!SS!:!MS!;!LOG_EVENT!;!LOG_CONNECTIONTYPE!
)
IF "!LOG_EVENT!"=="CONNECTION_TYPE_CHANGE" (
	ECHO.!YYYY!.!MO!.!DD!;!HH!:!MI!:!SS!:!MS!;!LOG_EVENT!;!LOG_CONNECTIONTYPEOLD!;!LOG_CONNECTIONTYPENEW!
)
IF "!LOG_EVENT!"=="OUTAGE_START" (
	ECHO.!YYYY!.!MO!.!DD!;!HH!:!MI!:!SS!:!MS!;!LOG_EVENT!;!LOG_CONNECTIONTYPE!
)
IF "!LOG_EVENT!"=="OUTAGE_END" (
	ECHO.!YYYY!.!MO!.!DD!;!HH!:!MI!:!SS!:!MS!;!LOG_EVENT!;!LOG_DURATION!;!LOG_CONNECTIONTYPE!
)
IF "!LOG_EVENT!"=="ROUTERCONNECTIONISSUE_START" (
	ECHO.!YYYY!.!MO!.!DD!;!HH!:!MI!:!SS!:!MS!;!LOG_EVENT!;!LOG_CONNECTIONTYPE!
)
IF "!LOG_EVENT!"=="ROUTERCONNECTIONISSUE_END" (
	ECHO.!YYYY!.!MO!.!DD!;!HH!:!MI!:!SS!:!MS!;!LOG_EVENT!;!LOG_DURATION!;!LOG_CONNECTIONTYPE!
)
EXIT /B


:LogData
:::Deprecated logging function
CALL :DateTime
IF EXIST "!LogFile!" (
	ECHO.[WARN][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] No connection to the Internet. This happened !Minutes! minutes ago. Start of the outage: !InternetOutageStartPoint!>>"!LogFile!"
) ELSE (
	ECHO.Internet Outage Monitoring>"!LogFile!"
	ECHO.-------------------------->>"!LogFile!"
	ECHO.[WARN][!DD!.!MO!.!YYYY! - !HH!:!MI!:!SS!] No connection to the Internet. This happened !Minutes! minutes ago. Start of the outage: !InternetOutageStartPoint!>>"!LogFile!"
)
EXIT /B

:LogConnSwitch
:::Deprecated logging function
:::This function logs a connection type switch.
SET "ConnSwitchFrom=%~1"
SET "ConnSwitchTo=%~2"
IF /i "!ConnSwitchFrom!"=="!ConnSwitchTo!" (
	EXIT /B
)
CALL :DateTime
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
:::This function sets the text graphics for the console window.
SET "SPACER=                                       "
SET "DIV_LINE=ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ"
SET "VERT_DIV=³"
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
SET "PRERNTIMEOUT_L1=              ÜÜÜÜ    ÜÜÜÜ              "
SET "PRERNTIMEOUT_L2=              ÛÛÛÛ    ÛÛÛÛ              "
SET "PRERNTIMEOUT_L3=              ÛÛÛÛ    ÛÛÛÛ              "
SET "PRERNTIMEOUT_L4=              ÛÛÛÛ    ÛÛÛÛ              "
SET "PRERNTIMEOUT_L5=              ÛÛÛÛ    ÛÛÛÛ              "
SET "PRERNTIMEOUT_L6=              ÛÛÛÛ    ÛÛÛÛ              "
SET "LOGVIEW_STATUS_L9=Recent detected Internet outages:      "
SET "LOGVIEW_STATUS_L11=	Now |  "
SET "STATUS_INTACT=          Internet available.           "
SET "STATUS_BROKEN=        Internet not available.         "
SET "STATUS_QUESTN=                   ??                   "
SET "NORECORD_L17=        Ûß                    ßÛ        "
SET "NORECORD_L18=        Û     No records.      Û        "
SET "NORECORD_L19=        ÛÜ                    ÜÛ        "
EXIT /B


:InitialTimeout
:::Some machines take their time to initially connect to the internet after booting.
IF "!Once!"=="true" (
	SET "Once=false"
	SET "L0=!SPACER! Delay: Waiting !InitialTimeout! seconds until start"
	SET "L8=!DIV_LINE!"
	CLS
	FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
		IF DEFINED L%%A (
			ECHO.!L%%A!
		) ELSE IF DEFINED PRERNTIMEOUT_L%%A (
			ECHO.!SPACER!!PRERNTIMEOUT_L%%A!
		) ELSE (
			ECHO.!SPACER!
		)
	)
	FOR /L %%A IN (1,1,!InitialTimeout!) DO (
		SET "L0=!SPACER! Delay: Waiting to start. !InitialTimeout! seconds left."
		CLS
		FOR /L %%B IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED L%%B (
				ECHO.!L%%B!
			) ELSE IF DEFINED PRERNTIMEOUT_L%%B (
				ECHO.!SPACER!!PRERNTIMEOUT_L%%B!
			) ELSE (
				ECHO.!SPACER!
			)
		)
		SET /A "InitialTimeout-=1"
		TIMEOUT /T 1 /NOBREAK >nul
	)
)
EXIT /B


:InitializeDisplay
:::Initialize display engine
MODE 120,31
SET "WRITABLE_LINES=30"
SET "WRITABLE_CHARS=119"
SET "STATUS_PANEL_LINE_START=1"
SET "STATUS_PANEL_LINE_END=8"
SET "LOG_PANEL_LINE_START=9"
SET "LOG_PANEL_LINE_END=29"
:::Generate TAB character with a robocopy hack.
FOR /F "delims= " %%T IN ('ROBOCOPY /L . . /njh /njs') DO SET "TAB=%%T"
EXIT /B


:Display
:::Display function
CLS
CALL :GenerateStatusView
CALL :GenerateLogView
EXIT /B


:GenerateStatusView
:::Status display from data the script has collected
:::8 lines,120 columns
:::--------------------------------------------------
:::<WindowTitle> Internet Outage Monitoring - !CurrentStatus!
:::--------------------------------------------------
:::<Centered>Current status
:::SYMBOL_L1
:::SYMBOL_L2
:::SYMBOL_L3
:::SYMBOL_L4
:::SYMBOL_L5
:::SYMBOL_L6
:::<SHORT INFO LINE>CONN ETHR | WIFI | UNKN<TAB><TAB>RUTR GOOD | BROK | UNKN<TAB><TAB>BGSV HALT | RUNN | UNKN
:::----------------------------------------------------
SET "STATUSPANEL_L8=!DIV_LINE!"
IF /i "!InternetConnectedFlag!"=="false" (
	:::Title
	TITLE Internet Outage Monitoring - Internet not available since !Minutes! minutes ago. Start: !InternetOutageStartPoint!
	:::Status
	SET "STATUSPANEL_L0=!SPACER!!STATUS_BROKEN!"
	:::Connection type switch
	IF "!ConnType!"=="Ethernet" (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED CABLE_BROKEN_L%%A (
				SET "STATUSPANEL_L%%A=!SPACER!!CABLE_BROKEN_L%%A!"
			)
		)
	) ELSE IF "!ConnType!"=="WiFi" (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED WRLSS_BROKEN_L%%A (
				SET "STATUSPANEL_L%%A=!SPACER!!WRLSS_BROKEN_L%%A!"
			)
		)
	) ELSE (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED QUESTIONMARK_L%%A (
				SET "STATUSPANEL_L%%A=!SPACER!!QUESTIONMARK_L%%A!"
			)
		)
	)
) ELSE IF DEFINED InternetOutageStartPoint (
	:::Title
	TITLE Internet Outage Monitoring - Internet available. Last outage: !InternetOutageStartPoint!
	:::Status
	SET "STATUSPANEL_L0=!SPACER!!STATUS_INTACT!"
	:::Connection type switch
	IF "!ConnType!"=="Ethernet" (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED CABLE_INTACT_L%%A (
				SET "STATUSPANEL_L%%A=!SPACER!!CABLE_INTACT_L%%A!"
			)
		)
	) ELSE IF "!ConnType!"=="WiFi" (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED WRLSS_INTACT_L%%A (
				SET "STATUSPANEL_L%%A=!SPACER!!WRLSS_INTACT_L%%A!"
			)
		)
	) ELSE (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED QUESTIONMARK_L%%A (
				SET "STATUSPANEL_L%%A=!SPACER!!QUESTIONMARK_L%%A!"
			)
		)
	)
) ELSE (
	:::Title
	TITLE Internet Outage Monitoring - Internet available.
	:::Status
	SET "STATUSPANEL_L0=!SPACER!!STATUS_INTACT!"
	:::Connection type switch
	IF "!ConnType!"=="Ethernet" (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED CABLE_INTACT_L%%A (
				SET "STATUSPANEL_L%%A=!SPACER!!CABLE_INTACT_L%%A!"
			)
		)
	) ELSE IF "!ConnType!"=="WiFi" (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED WRLSS_INTACT_L%%A (
				SET "STATUSPANEL_L%%A=!SPACER!!WRLSS_INTACT_L%%A!"
			)
		)
	) ELSE (
		FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
			IF DEFINED QUESTIONMARK_L%%A (
				SET "STATUSPANEL_L%%A=!SPACER!!QUESTIONMARK_L%%A!"
			)
		)
	)
)

:::Generate short info line
SET "STATUSPANEL_L7=CONN !SHRT_CONNTYPE!!TAB!!TAB!"


:::Display status panel

FOR /L %%A IN (0,1,!STATUS_PANEL_LINE_END!) DO (
	IF DEFINED STATUSPANEL_L%%A (
		ECHO.!STATUSPANEL_L%%A!
	) ELSE (
		ECHO.
	)
)
EXIT /B


:GenerateLogView
:::Log display from machine readable log file
:::21 lines,120 columns
:::Reverse order
:::--------------------------------------------------
:::Recent detected Internet outages:
:::///////////1 LINE SPACE FROM TOP///////////
:::<TAB>Now |<TAB>!CurrentStatus!
:::///////////1 LINE SPACE BETWEEN EVENTS///////////
:::<TAB>!LastEventDate! |<TAB>!LastEventTime! Outage: !LastOutageMinutes! minute/minutes.
::://////IF MORE THAN 1 OUTAGE FOR THAT DAY:////////
:::<TAB>!LastEventDate! |<TAB>!LastEventTime! Outage: !LastOutageMinutes! minute/minutes.
:::<TAB><TAB>           |<TAB>!EventTimeBefore! Outage: !OutageBeforeMinutes! minute/minutes.
::://///////ON CONNECTION TYPE CHANGE EVENT/////////
:::<TAB>!LastEventDate! |<TAB>!LastEventTime! Connection type changed to !ConnType!.
::://///////ON RECORD START EVENT///////////////////
:::<TAB>!LastEventDate! |<TAB>!LastEventTime! Record start - detected connection type: !ConnType!
:::--------------------------------------------------
:::Recent detected internet outages:
:::
:::         Now ¦   No connection to the Internet. This happened 43 minutes ago. Start of the outage: 06.02.2023 20:06:26
:::
:::  03.01.2023 ¦   16:22:12 Outage: 8 minutes.
:::             ¦   09:54:07 Outage: 19 minutes.
:::             ¦   06:14:59 Outage: 2 minutes.
:::             ¦   03:44:22 Connection change: Ethernet to WiFi
:::             ¦   01:25:59 Outage: 2 minutes.
:::
:::  02.01.2023 ¦   14:34:23 Outage: 80 minutes.
:::             ¦   07:57:03 Outage: 1 minutes.
:::             ¦   07:14:54 Outage: 5 minutes.
:::             ¦   07:03:00 Record start - detected connection type: Ethernet
:::--------------------------------------------------

IF NOT EXIST "!MachineLog!" (
	:::If machine log file does not exist, display "No record" message
	FOR /L %%A IN (!LOG_PANEL_LINE_START!,1,!LOG_PANEL_LINE_END!) DO (
		IF DEFINED NORECORD_L%%A (
			ECHO.!SPACER!!NORECORD_L%%A!
		) ELSE ( ECHO. )
	)
) ELSE (
	:::Reverse machine log file into rev.tmp
	IF EXIST "!RevTmp!" DEL /F /Q "!RevTmp!" >NUL
	SET "RevTmp=.\rev.tmp"
	SET /A LineCount=0
	FOR /F "delims=" %%A IN (%MachineLog%) DO (
		SET /A LineCount+=1
		SET "MachineRevLine[!LineCount!]=%%A"
	)
	(
	FOR /L %%A IN (%LineCount%,-1,1) DO ECHO.!MachineRevLine[%%A]!
	)>"!RevTmp!"
	CALL :GenerateLogView.ReadRev
	:::Go through the 20 lines and group them by date. Note: they are in reverse order.
	FOR /L %%A IN (1,1,20) DO (
		SET "Line=!MachineLog[%%A]!"
		FOR /F "tokens=* delims=;" %%B IN ("%Line%") DO (
			SET "Date=%%B"
			IF EXIST ".\!Date!-IOM.tmp" (
				:::If date-group file exists, append line to it
				ECHO.!Line!>>".\!Date!-IOM.tmp"
			) ELSE (
				:::If date-group file does not exist, create it and append line to it
				ECHO.!Line!>".\!Date!-IOM.tmp"
			)
		)
	)
	:::First line is always "Recent detected internet outages:" and after that an empty line for readability
	SET "LogViewLineRemainder=19"
	:::TODO: Implement "Now" tag if current status is "No connection to the Internet" and reduce LogViewLineRemainder by 2
	:::Go through the date-group files and display them
	FOR /F "usebackq delims=" %%A IN (`DIR /B /A-D /O-D ".\*-IOM.tmp"`) DO (
		SET "FirstLine=true"
		FOR /F "delims=" %%B IN (.\%%A) DO (
			SET "CurrentLine=%%B"
			IF "!FirstLine!" EQU "true" (
				:::If first line of file, display date on the left of divider
				FOR /F "tokens=* delims=;" %%C IN ("%CurrentLine%") DO (
					SET "Date=%%C"
					SET "Time=%%D"
					SET "Event=%%E"
					SET "Field_4=%%F"
					SET "Field_5=%%G"
					SET "Field_6=%%H"
				)
				CALL :GenerateLogView.DisplayPrep "FirstLine=!Firstline!" "LinesLeft=!LogViewLineRemainder!" "Date=!Date!" "Time=!Time!" "Event=!Event!" "Field_4=!Field_4!" "Field_5=!Field_5!" "Field_6=!Field_6!"
				SET "FirstLine=false"
			) ELSE (
				:::If not first line of file, just display time on the right of divider
				FOR /F "tokens=* delims=;" %%C IN ("%CurrentLine%") DO (
					SET "Time=%%D"
					SET "Event=%%E"
					SET "Field_4=%%F"
					SET "Field_5=%%G"
					SET "Field_6=%%H"
				)
				CALL :GenerateLogView.DisplayPrep "FirstLine=!Firstline!" "LinesLeft=!LogViewLineRemainder!" "Date=!Date!" "Time=!Time!" "Event=!Event!" "Field_4=!Field_4!" "Field_5=!Field_5!" "Field_6=!Field_6!"
				CALL :GenerateLogView.Display
			)
			SET "FirstLine=false"
		)
		:::Delete temporary date-group file
		REM DEL /F /Q ".\%%A" >NUL
	)
)
EXIT /B


:GenerateLogView.ReadRev
:::Read in first 20 lines of rev.tmp
SET /A LineCount=0
FOR /F "delims=" %%A IN (!RevTmp!) DO (
	SET /A LineCount+=1
	SET "MachineLog[!LineCount!]=%%A"
	:::If line is empty, exit
	IF NOT DEFINED MachineLog[!LineCount!] EXIT /B
	:::If line count of 20 is reached, exit
	IF !LineCount! EQU 20 EXIT /B
)
EXIT /B


:GenerateLogView.DisplayPrep
:::Grab call arguments
FOR %%A IN (%*) DO (
	SET "%%~A"
	ECHO.%%~A
	PAUSE
)
:::If no lines left, exit
IF !LinesLeft! EQU 0 EXIT /B
SET /A CurrentCalcLine=%LOG_PANEL_LINE_END%-%LinesLeft%
:::If first line of file, display date on the left of divider
IF "!FirstLine!" EQU "true" (
	:::If first line of file, display date on the left of divider
	SET "LOGPANEL_L!CurrentCalcLine!=.!TAB!!Date! |!TAB!!Time!"
) ELSE (
	
)
IF "!LOG_EVENT!"=="RECORD_START" (
	ECHO.!YYYY!.!MO!.!DD!;!HH!:!MI!:!SS!:!MS!;!LOG_EVENT!;!LOG_CONNECTIONTYPE!
)
IF "!LOG_EVENT!"=="CONNECTION_TYPE_CHANGE" (
	ECHO.!YYYY!.!MO!.!DD!;!HH!:!MI!:!SS!:!MS!;!LOG_EVENT!;!LOG_CONNECTIONTYPEOLD!;!LOG_CONNECTIONTYPENEW!
)
IF "!LOG_EVENT!"=="OUTAGE_START" (
	ECHO.!YYYY!.!MO!.!DD!;!HH!:!MI!:!SS!:!MS!;!LOG_EVENT!;!LOG_CONNECTIONTYPE!
)
IF "!LOG_EVENT!"=="OUTAGE_END" (
	ECHO.!YYYY!.!MO!.!DD!;!HH!:!MI!:!SS!:!MS!;!LOG_EVENT!;!LOG_DURATION!;!LOG_CONNECTIONTYPE!
)
IF "!LOG_EVENT!"=="ROUTERCONNECTIONISSUE_START" (
	ECHO.!YYYY!.!MO!.!DD!;!HH!:!MI!:!SS!:!MS!;!LOG_EVENT!;!LOG_CONNECTIONTYPE!
)
IF "!LOG_EVENT!"=="ROUTERCONNECTIONISSUE_END" (
	ECHO.!YYYY!.!MO!.!DD!;!HH!:!MI!:!SS!:!MS!;!LOG_EVENT!;!LOG_DURATION!;!LOG_CONNECTIONTYPE!
)
EXIT /B


:GenerateLogView.Display
:::Display the generated, grouped events as a whole.
FOR /L %%A IN (!LOG_PANEL_LINE_START!,1,!LOG_PANEL_LINE_END!) DO (
	IF DEFINED LOGPANEL_L%%A (
		ECHO.!LOGPANEL_L%%A!
	) ELSE
		ECHO.
	)
)
EXIT /B
