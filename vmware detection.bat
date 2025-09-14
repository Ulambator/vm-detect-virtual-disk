@echo off
title VMware Full Detection Script
echo --- VMware Detection Script ---
echo.

REM ============================
REM System / BIOS Checks
REM ============================
echo [BIOS / System Info]
wmic bios get manufacturer,version,serialnumber
wmic computersystem get manufacturer,model,systemtype
wmic csproduct get name,vendor,version,identifyingnumber
echo.

REM ============================
REM CPU Checks
REM ============================
echo [CPU Info]
wmic cpu get name,manufacturer,processorid
echo.

REM ============================
REM Disk Checks
REM ============================
echo [Physical Disk Info]
wmic diskdrive get model,serialnumber,interfaceType,mediaType
echo.

REM ============================
REM Network Adapter Checks
REM ============================
echo [Network Adapters]
wmic nic get name,macaddress,adaptertype
echo.
echo Checking VMware MAC prefixes (00:05:69,00:0C:29,00:1C:14,00:50:56)...
for /f "tokens=2 delims=," %%A in ('wmic nic get macaddress /format:csv ^| find ":"') do (
    set mac=%%A
    set mac=!mac::=-!
    echo !mac! | findstr /i "000569 000c29 001c14 005056" >nul && echo Possible VMware NIC detected: %%A
)
echo.

REM ============================
REM Registry Checks
REM ============================
echo [Registry VMware Keys]
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\VMware, Inc." 2>nul
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\VMware, Inc.\VMware Tools" 2>nul
reg query "HKEY_LOCAL_MACHINE\HARDWARE\ACPI\DSDT\VBOX__" 2>nul
reg query "HKEY_LOCAL_MACHINE\HARDWARE\ACPI\FADT\VBOX__" 2>nul
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Oracle\VirtualBox" 2>nul
echo.

REM ============================
REM IO Port / Device Checks
REM ============================
echo [IO Ports / Devices]
echo Scanning common VMware IO ports...
echo Port 0x5658 (VMware backdoor)
echo Port 0x5659
echo Port 0x564D
echo Port 0x565A
echo Note: detection of these ports requires custom code, cannot be fully checked in .bat
echo.

REM ============================
REM Environment / Processes Checks
REM ============================
echo [Processes / Services]
tasklist | findstr /i "vmtoolsd.exe vmwaretray.exe vmwareuser.exe"
sc query | findstr /i "vmtools"
echo.

REM ============================
REM Misc Checks
REM ============================
echo [Miscellaneous Checks]
echo Checking for common VMware files and folders...
if exist "C:\Program Files\VMware\" echo VMware folder exists
if exist "C:\Program Files (x86)\VMware\" echo VMware folder exists
if exist "C:\Windows\System32\drivers\vmmouse.sys" echo VMware mouse driver detected
if exist "C:\Windows\System32\drivers\vmhgfs.sys" echo VMware HGFS driver detected
if exist "C:\Windows\System32\drivers\vm3dgl.dll" echo VMware 3D driver detected
echo.

@echo off
echo ===============================
echo Detecting Virtualization Artifacts
echo ===============================
echo.

:: VMware Keys
echo [VMware Registry Keys]
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\VMware, Inc." 2>nul
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\VMware, Inc.\VMware Tools" 2>nul
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmhgfs" 2>nul
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vmci" 2>nul
echo.

:: VirtualBox Keys
echo [VirtualBox Registry Keys]
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Oracle\VirtualBox" 2>nul
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VBoxDrv" 2>nul
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\VBoxGuest" 2>nul
reg query "HKEY_LOCAL_MACHINE\HARDWARE\ACPI\DSDT\VBOX__" 2>nul
reg query "HKEY_LOCAL_MACHINE\HARDWARE\ACPI\FADT\VBOX__" 2>nul
echo.

:: Check for virtual disk / storage keys
echo [Virtual Disks / Storage]
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\disk" /s 2>nul | findstr /i "VMware VBox"
echo.

:: Check for network adapters (VMware / VirtualBox)
echo [Virtual Network Adapters]
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /s 2>nul | findstr /i "VMware VBox"
echo.

:: Check for video / GPU adapters
echo [Virtual Video / GPU]
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\DISPLAY" /s 2>nul | findstr /i "VMware VBox"
echo.

:: MACHINE GUID
reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography /v MachineGuid
echo.

echo Detection complete.
pause

