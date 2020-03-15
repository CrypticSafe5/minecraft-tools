ECHO off
CLS

:: Default values
SET OUTPUT_DIR=OUTPUT
SET RAM_MIN=1024
SET RAM_MAX=4096
SET LOG=1

GOTO:main

:: Help message
:showHelp
    ECHO Usage:
    ECHO   %0 [-h / --help] [-o / --out-dir] NEW_SERVER
    ECHO   [-n / --ram-min] 1024 [-x / --ram-max] 4096'
    ECHO   [-q / --quiet]'
    ECHO.
    ECHO Options:
    ECHO   -h, --help
    ECHO     Display the help message of this script
    ECHO   -o, --out-dir
    ECHO     The name of the directory to output to
    ECHO   -n, --ram-min
    ECHO     Minimum amount of ram to be used with java
    ECHO   -x, --ram-max
    ECHO     Maximum amount of ram to be used with java
GOTO:EOF

:setOutDir
    SHIFT
    SET OUTPUT_DIR="%1"
    SHIFT
GOTO:main

:setRamMin
    SHIFT
    SET RAM_MIN="%1"
    SHIFT
GOTO:main

:setRamMax
    SHIFT
    SET RAM_MAX="%1"
    SHIFT
GOTO:main

:main
    :: Argument handling
    IF "%1"=="-h" GOTO:showHelp
    IF "%1"=="--help" GOTO:showHelp

    IF "%1"=="-o" GOTO:setOutDir
    IF "%1"=="--out-dir" GOTO:setOutDir

    IF "%1"=="-n" GOTO:setRamMin
    IF "%1"=="--ram-min" GOTO:setRamMin

    IF "%1"=="-x" GOTO:setRamMax
    IF "%1"=="--ram-max" GOTO:setRamMax

    :: Setup
    SET URL_FORGE_INSTALLER=https://files.minecraftforge.net/maven/net/minecraftforge/forge/1.12-14.21.1.2387/forge-1.12-14.21.1.2387-installer.jar
    SET DIR=%CD%\%OUTPUT_DIR%
    mkdir %OUTPUT_DIR%
    CD %OUTPUT_DIR%

    :: Get version numbers
    FOR /F "tokens=7 delims=/" %%X IN ("%URL_FORGE_INSTALLER%") DO SET TMP="%%X"
    FOR /F "tokens=1 delims=-" %%X IN (%TMP%) DO SET FORGE_MCVERSION=%%X
    FOR /F "tokens=2 delims=-" %%X IN (%TMP%) DO SET FORGE_VERSION=%%X
    SET FORGE_INSTALLER_FILE=%DIR%\forge-%FORGE_MCVERSION%-%FORGE_VERSION%-installer.jar
    SET FORGE_UNIVERSAL_FILE=%DIR%\forge-%FORGE_MCVERSION%-%FORGE_VERSION%-universal.jar

    :: Get and use Forge installer
    ECHO ^> Fetching Forge installer
    START /W /MIN "" bitsadmin /transfer getInstallerJar /download /priority high %URL_FORGE_INSTALLER% %FORGE_INSTALLER_FILE%
    ECHO ^> Running Forge installer
    IF "%LOG%" EQU "1" (
        java -jar %FORGE_INSTALLER_FILE% --installServer >> ..\CreateForgeLog.txt
    ) ELSE (
        java -jar %FORGE_INSTALLER_FILE% --installServer > nul 2>&1
    )
    ECHO ^> Forge installer complete
    DEL %FORGE_INSTALLER_FILE% %FORGE_INSTALLER_FILE%.log forge-%FORGE_MCVERSION%-%FORGE_VERSION%-changelog.txt
    ECHO ^> Deleted installer and log

    :: Initialize server
    ECHO ^> Initializing the server
    IF "%LOG%" EQU "1" (
        java -Xms%RAM_MIN%M -Xmx%RAM_MAX%M -jar %FORGE_UNIVERSAL_FILE% nogui >> ..\CreateForgeLog.txt
    ) ELSE (
        java -Xms%RAM_MIN%M -Xmx%RAM_MAX%M -jar %FORGE_UNIVERSAL_FILE% nogui > nul 2>&1
    )

    ECHO eula=true > eula.txt
    ECHO ^> Set eula to true
    ECHO ^> COMPLETE

    ECHO WINNING
    cd ..
    ::rmdir OUTPUT /S /Q