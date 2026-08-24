@set iasver=1.0.1
::  ���ű����ʵ����֤���� IDM �汾�����˵��ݴ���ʾ"������汾"������ʱͬ�����£�
@set idmsupport=6.43
@setlocal DisableDelayedExpansion
@echo off

::  ǿ�����ô���ҳΪ 936 (GBK/��������)
chcp 936 >nul 2>&1


::============================================================================
::
::   IDM ����ű� (IAS)
::
::   ��Ŀ��ҳ: https://github.com/tytsxai/IDM-Activation-Script-Chinese
::   ���ⷴ��: https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues
::   ����֤  : GPL-3.0������ֿ��Ŀ¼ LICENSE��
::
::   ----- ���뵼�������ں���ά���� -----
::   001-047 �� : ͷ��Ԫ��Ϣ������ҳ���á�Ĭ�Ͽ��أ�iasver �ű��汾 / idmsupport ������ IDM �汾��
::   047-117 �� : PATH ���á�Sysnative / SysArm32 �ܹ����롢����������/act /frz /res /noupd /reupd /silent /log[=·��]��
::   117-152 �� : ��־��ʼ������ĬģʽУ�顢Null ������
::   152-445 �� : ����̽�⣨����ԱȨ�ޡ�IDM ��װ·����CLSID ע����������ͨ�ԣ�
::   447-510 �� : IDM �汾̽�� + ���˵������� / ���� / ���� / ���¿��� / ���� / ����������������
::   512-610 �� : ����������ע���ɾ������
::   615-694 �� : ���� / �ָ� IDM �Զ����¼�飨CheckUpdtVM��
::   696-945 �� : �����붳��������̡�ע������ݡ����ע����Ϣע�롢��β���
::   948-1126 ��: CLSID ɨ�裨PowerShell ��Ƕ�Σ�
::   1128-1250 ��: �˳�����ˡ������������ӳ���:kill_idm / :flush_input����
::                ��־�ӳ���:extract_logpath / :init_log / :log������ɫ���
::
::============================================================================



::  To activate, run the script with "/act" parameter or change 0 to 1 in below line
set _activate=0

::  To Freeze the 30 days trial period, run the script with "/frz" parameter or change 0 to 1 in below line
set _freeze=0

::  To reset the activation and trial, run the script with "/res" parameter or change 0 to 1 in below line
set _reset=0

::  To disable IDM's automatic update check (stops the "new version" popup), run the script with "/noupd" parameter or change 0 to 1 in below line
set _noupd=0

::  To restore IDM's automatic update check, run the script with "/reupd" parameter or change 0 to 1 in below line
set _reupd=0

::  If value is changed in above lines or parameter is used then script will run in unattended mode

::========================================================================================================================================

::  Set Path variable, it helps if it is misconfigured in the system

set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%PATH%"
)

:: Re-launch the script with x64 process if it was initiated by x86 process on x64 bit Windows
:: or with ARM64 process if it was initiated by x86/ARM32 process on ARM64 Windows

set "_cmdf=%~f0"
for %%# in (%*) do (
if /i "%%#"=="r1" set r1=1
if /i "%%#"=="r2" set r2=1
)

if exist %SystemRoot%\Sysnative\cmd.exe if not defined r1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %* r1"
exit /b
)

:: Re-launch the script with ARM32 process if it was initiated by x64 process on ARM64 Windows

if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 if not defined r2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %* r2"
exit /b
)

::========================================================================================================================================

set "blank="
set "mas=ht%blank%tps%blank%://github.com/tytsxai/IDM-Activation-Script-Chinese"

set _args=
set _elev=
set _silent=0
set _log=0
set _log_enabled=0
set _unattended=0
set "log_file="
set "exit_code=0"

set _args=%*
if defined _args set _args=%_args:"=%
if defined _args (
for %%A in (%_args%) do (
if /i "%%A"=="-el"  set _elev=1
if /i "%%A"=="/res" set _reset=1
if /i "%%A"=="/frz" set _freeze=1
if /i "%%A"=="/act" set _activate=1
if /i "%%A"=="/noupd" set _noupd=1
if /i "%%A"=="/reupd" set _reupd=1
if /i "%%A"=="/silent" set _silent=1
if /i "%%A"=="/quiet" set _silent=1
if /i "%%A"=="/log" set _log=1
)
)

::  /log=·�� ��·��Ҫ������ȡ�����ܿ������ for ѭ����for %%A in (...) ��
::  ���Ͻ����� = Ҳ���ָ�����"/log=C:\x.log" �������Ѿ������ "/log" ��
::  "C:\x.log" ���� token���Ƚϵõ���ֻ���� "/log"������ֱ�Ӵ�������������ȡ��
set "_logpath="
if defined _args echo %_args%| find /i "/log=" >nul 2>&1 && call :extract_logpath

if %_noupd%==1 if %_reupd%==1 set _reupd=0

for %%A in (%_activate% %_freeze% %_reset% %_noupd% %_reupd%) do (if "%%A"=="1" set _unattended=1)
if %_silent%==1 set _unattended=1
if %_silent%==1 set _log=1

set "log_dir=%SystemRoot%\Temp"
if %_log%==1 (
call :init_log
set _log_enabled=1
)
if %_log_enabled%==1 (
call :log "IAS %iasver% ����������: %_args%"
call :log "��־���: %log_file%"
if %_silent%==0 echo ��־�ļ�: %log_file%
)

if %_silent%==1 if %_activate%==0 if %_freeze%==0 if %_reset%==0 if %_noupd%==0 if %_reupd%==0 (
call :set_exit 2 "��Ĭģʽȱ�ٲ����������˳�"
goto done2
)

::  Check if Null service is working, it's important for the batch script

sc query Null | find /i "RUNNING" >nul 2>&1
if %errorlevel% NEQ 0 (
call :log "����: Null ����δ���У����ܵ��½ű�����"
echo:
echo Null ����δ���У��ű����ܻ����...
echo:
echo:
echo ���� - %mas%
echo:
echo:
if %_silent%==1 (ping 127.0.0.1 -n 2 >nul) else ping 127.0.0.1 -n 10
)
cls
chcp 936 >nul 2>&1

::  Check LF line ending

pushd "%~dp0"
>nul findstr /v "$" "%~nx0" && (
echo:
echo ����: �ű�����LF���з���ű�ĩβȱ�ٿ��С�
echo:
call :set_exit 2 "����: ��⵽ LF ���з���ȱ��ĩβ����"
if %_silent%==1 (ping 127.0.0.1 -n 2 >nul) else ping 127.0.0.1 -n 6 >nul
popd
exit /b %exit_code%
)
popd

::========================================================================================================================================

cls
chcp 936 >nul 2>&1
color 07
title  IDM ����ű� %iasver%

::========================================================================================================================================

set "nul1=1>nul"
set "nul2=2>nul"
set "nul6=2^>nul"
set "nul=>nul 2>&1"

set "psc=powershell.exe -NoProfile -Command"
set winbuild=1
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G

set _NCS=1
if %winbuild% LSS 10586 set _NCS=0
if %winbuild% GEQ 10586 reg query "HKCU\Console" /v ForceV2 %nul2% | find /i "0x0" %nul1% && (set _NCS=0)

if %_NCS% EQU 1 (
for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"
set     "Red="41;97m""
set    "Gray="100;97m""
set   "Green="42;97m""
set    "Blue="44;97m""
set  "_White="40;37m""
set  "_Green="40;92m""
set "_Yellow="40;93m""
) else (
set     "Red="Red" "white""
set    "Gray="Darkgray" "white""
set   "Green="DarkGreen" "white""
set    "Blue="Blue" "white""
set  "_White="Black" "Gray""
set  "_Green="Black" "Green""
set "_Yellow="Black" "Yellow""
)

set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "eline=echo: &call :_color %Red% "==== ERROR ====" &echo:"
set "line=___________________________________________________________________________________________________"
set "_buf={$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=34;$B.Height=300;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}"

::========================================================================================================================================

if %winbuild% LSS 7600 (
%nceline%
echo ��⵽��֧�ֵĲ���ϵͳ�汾 [%winbuild%].
echo �˽ű�֧�� Windows 7/8/8.1/10/11 ��������汾��
call :set_exit 2 "��֧�ֵĲ���ϵͳ�汾 [%winbuild%]"
goto done2
)

for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" (
%nceline%
echo ϵͳ���Ҳ��� powershell.exe��
call :set_exit 2 "ϵͳ���Ҳ��� powershell.exe"
goto done2
)

::========================================================================================================================================

::  Fix for the special characters limitation in path name

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%
set _PSarg=%_PSarg:'=''%

set "_appdata=%appdata%"
set "_ttemp=%userprofile%\AppData\Local\Temp"

setlocal EnableDelayedExpansion

::========================================================================================================================================

echo "!_batf!" | find /i "!_ttemp!" %nul1% && (
if /i not "!_work!"=="!_ttemp!" (
%eline%
echo �ű�����ʱ�ļ��������С�
echo ����ܴ�ѹ���ļ��鿴�������нű���
echo:
echo ���ѹѹ���ļ���Ȼ��ӽ�ѹ����ļ��������нű���
call :set_exit 2 "�ű�����ʱ�ļ������У�����ֹ"
goto done2
)
)

::========================================================================================================================================

::  Check PowerShell

REM :PowerShellTest: $ExecutionContext.SessionState.LanguageMode :PowerShellTest:

%psc% "$f=[io.file]::ReadAllText('!_batp!',[Text.Encoding]::GetEncoding(936)) -split ':PowerShellTest:\s*';iex ($f[1])" | find /i "FullLanguage" %nul1% || (
%eline%
%psc% $ExecutionContext.SessionState.LanguageMode
echo:
echo PowerShell �޷��������������̱���ֹ...
echo �����֯���ܽ����� Powershell Ӧ�ã��Է�ֹ��Щ�����
echo:
echo �鿴��ҳ�Ի�ȡ������%mas%
call :set_exit 2 "PowerShell ���б���ֹ"
goto done2
)

::========================================================================================================================================

::  Elevate script as admin and pass arguments and preventing loop

%nul1% fltmc || (
if not defined _elev %psc% "start cmd.exe -arg '/c \"!_PSarg!\"' -verb runas" && exit /b
%eline%
echo �˽ű���Ҫ����ԱȨ�ޡ�
echo ���Ҽ��˽ű���ѡ��"�Թ���Ա��������"��
call :set_exit 2 "ȱ�ٹ���ԱȨ��"
goto done2
)

::========================================================================================================================================

::  Disable QuickEdit and launch from conhost.exe to avoid Terminal app

set quedit=
set terminal=

if %_unattended%==1 (
set quedit=1
set terminal=1
)

for %%# in (%_args%) do (if /i "%%#"=="-qedit" set quedit=1)

if %winbuild% LSS 10586 (
reg query HKCU\Console /v QuickEdit %nul2% | find /i "0x0" %nul1% && set quedit=1
)

if %winbuild% GEQ 17763 (
set "launchcmd=start conhost.exe %psc%"
) else (
set "launchcmd=%psc%"
)

set "d1=$t=[AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1).DefineDynamicModule(2, $False).DefineType(0);"
set "d2=$t.DefinePInvokeMethod('GetStdHandle', 'kernel32.dll', 22, 1, [IntPtr], @([Int32]), 1, 3).SetImplementationFlags(128);"
set "d3=$t.DefinePInvokeMethod('SetConsoleMode', 'kernel32.dll', 22, 1, [Boolean], @([IntPtr], [Int32]), 1, 3).SetImplementationFlags(128);"
set "d4=$k=$t.CreateType(); $b=$k::SetConsoleMode($k::GetStdHandle(-10), 0x0080);"

if defined quedit goto :skipQE
::  conhost �������ڹر� QuickEdit���� start ���ܾ�����ȫ����/���ԣ������˵���ǰ���ڼ���������ֻ��ʾ���ܾ����ʡ���������
::  ע�⣺��Ҫ�� if (...) ��ס start �С���d1-d4 չ���󺬴������ţ���ضϴ���顣
if %winbuild% LSS 17763 goto :qeLegacy
start "" conhost.exe %psc% "%d1% %d2% %d3% %d4% & cmd.exe '/c' '!_PSarg! -qedit'"
if not errorlevel 1 exit /b
echo:
echo [����] �޷����� conhost ����̨���ܾ����ʻ򱻰�ȫ�������أ������ڵ�ǰ���ڼ���...
echo:
%psc% "%d1% %d2% %d3% %d4%" >nul 2>&1
goto :skipQE
:qeLegacy
%launchcmd% "%d1% %d2% %d3% %d4% & cmd.exe '/c' '!_PSarg! -qedit'"
exit /b
:skipQE

::========================================================================================================================================

::  Check for updates

set old=
if not %_unattended%==1 (
echo ________________________________________________
echo ��ǰ�汾��%iasver% �����زֿ�汾��
echo ��������£��������Ŀ��ҳ��%mas%
echo ________________________________________________
echo:
)

::========================================================================================================================================

cls
chcp 936 >nul 2>&1
title  IDM ����ű� %iasver%

echo:
echo ���ڳ�ʼ��...

::  Check WMI������ CIM��ʧ���ٻ��˾ɰ� WMI���°� Windows �� Get-WmiObject �� DCOM ·�����ܿ�����

echo   - ���ϵͳ��Ϣ (WMI/CIM)...
%psc% "$c=$null;try{$c=Get-CimInstance Win32_ComputerSystem -EA Stop}catch{};if(-not $c){try{$c=Get-WmiObject Win32_ComputerSystem -EA Stop}catch{}};$c.CreationClassName" %nul2% | find /i "computersystem" %nul1% || (
%eline%
%psc% "$c=$null;try{$c=Get-CimInstance Win32_ComputerSystem -EA Stop}catch{};if(-not $c){try{$c=Get-WmiObject Win32_ComputerSystem -EA Stop}catch{}};$c.CreationClassName"
echo:
echo WMI �޷��������������̱���ֹ...
echo:
echo �鿴��ҳ�Ի�ȡ������%mas%
call :set_exit 2 "WMI ��ѯʧ��"
goto done2
)

::  Check user account SID

echo   - ��ȡ�û��˻� SID...
set _sid=
for /f "delims=" %%a in ('%psc% "$c=$null;try{$c=Get-CimInstance Win32_ComputerSystem -EA Stop}catch{$c=Get-WmiObject Win32_ComputerSystem};([System.Security.Principal.NTAccount]$c.UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value" %nul6%') do (set _sid=%%a)

reg query HKU\%_sid%\Software %nul% || (
for /f "delims=" %%a in ('%psc% "$explorerProc = Get-Process -Name explorer | Where-Object {$_.SessionId -eq (Get-Process -Id $pid).SessionId} | Select-Object -First 1; $sid = (gwmi -Query ('Select * From Win32_Process Where ProcessID=' + $explorerProc.Id)).GetOwnerSid().Sid; $sid" %nul6%') do (set _sid=%%a)
)

reg query HKU\%_sid%\Software %nul% || (
%eline%
echo:
echo [%_sid%]
echo δ�ҵ��û��ʻ� SID�����̱���ֹ...
echo:
echo �鿴��ҳ�Ի�ȡ������%mas%
call :set_exit 2 "δ�ܻ�ȡ��ǰ�û� SID"
goto done2
)

::========================================================================================================================================

::  Check if the current user SID is syncing with the HKCU entries

%nul% reg delete HKCU\IAS_TEST /f
%nul% reg delete HKU\%_sid%\IAS_TEST /f

set HKCUsync=$null
%nul% reg add HKCU\IAS_TEST
%nul% reg query HKU\%_sid%\IAS_TEST && (
set HKCUsync=1
)

%nul% reg delete HKCU\IAS_TEST /f
%nul% reg delete HKU\%_sid%\IAS_TEST /f

::  Below code also works for ARM64 Windows 10 (including x64 bit emulation)

for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set arch=%%b
if /i not "%arch%"=="x86" set arch=x64

if "%arch%"=="x86" (
set "CLSID=HKCU\Software\Classes\CLSID"
set "CLSID2=HKU\%_sid%\Software\Classes\CLSID"
set "HKLM=HKLM\Software\Internet Download Manager"
) else (
set "CLSID=HKCU\Software\Classes\Wow6432Node\CLSID"
set "CLSID2=HKU\%_sid%\Software\Classes\Wow6432Node\CLSID"
set "HKLM=HKLM\SOFTWARE\Wow6432Node\Internet Download Manager"
)

for /f "tokens=2*" %%a in ('reg query "HKU\%_sid%\Software\DownloadManager" /v ExePath %nul6%') do call set "IDMan=%%b"

if not exist "%IDMan%" (
if %arch%==x64 set "IDMan=%ProgramFiles(x86)%\Internet Download Manager\IDMan.exe"
if %arch%==x86 set "IDMan=%ProgramFiles%\Internet Download Manager\IDMan.exe"
)

if not exist %SystemRoot%\Temp md %SystemRoot%\Temp
set "idmcheck=tasklist /fi "imagename eq idman.exe" | findstr /i "idman.exe" %nul1%"

::  Check CLSID registry access

echo   - У��ע�������Ȩ��...
%nul% reg add %CLSID2%\IAS_TEST
%nul% reg query %CLSID2%\IAS_TEST || (
%eline%
echo �޷�д�� %CLSID2%
echo:
echo �鿴��ҳ�Ի�ȡ������%mas%
call :set_exit 2 "�޷�д�� %CLSID2%"
goto done2
)

%nul% reg delete %CLSID2%\IAS_TEST /f

::========================================================================================================================================

if %_reset%==1 goto :_reset
if %_noupd%==1 goto :_noupdate
if %_reupd%==1 goto :_restoreupd
if %_activate%==1 (set frz=0&goto :_activate)
if %_freeze%==1 (set frz=1&goto :_activate)

::  ̽�Ȿ���Ѱ�װ�� IDM �汾�ţ�ֻ��ȡ IDMan.exe ���ļ��汾��Ϣ����д�κ�ע�����
::  ���˵��ݴ���ʾ"������汾 / �����汾"������"֧�����°�"����ģ��˵����

set "idmfound="
set "idmmm="
if exist "!IDMan!" (
for /f "delims=" %%a in ('%psc% "$v=(Get-Item -LiteralPath '!IDMan!').VersionInfo; if ($v.ProductVersion) {$v.ProductVersion.Trim()} else {$v.FileVersion}" %nul6%') do set "idmfound=%%a"
)
if defined idmfound for /f "tokens=1,2 delims=., " %%a in ("!idmfound!") do set "idmmm=%%a.%%b"
call :log "IDM �汾���: [!idmfound!] �ű������� %idmsupport%"

:MainMenu

cls
chcp 936 >nul 2>&1
title  IDM ����ű� %iasver%
if not defined terminal mode 75, 31

echo:
echo:
echo:                �ű� %iasver% ^| ������ IDM %idmsupport% ��֮ǰ�� 6.x �汾
if defined idmmm (
echo:                ������⵽�� IDM��!idmfound!
if not "!idmmm!"=="%idmsupport%" echo:                ע�⣺��������汾��ͬ���쳣ʱ�� README �� Q10
) else (
echo:                ����δ��⵽ IDM�����Ȱ�װ IDM �ټ���
)
echo:            ___________________________________________________
echo:
echo:               [1] ���������ڣ��Ƽ���
echo:               [2] ���д��ע����Ϣ��
echo:               [3] ���ü���/������
echo:               _____________________________________________
echo:
echo:               [4] ���� IDM ������ʾ
echo:               [5] �ָ� IDM ������ʾ
echo:               _____________________________________________
echo:
echo:               [6] ���� IDM
echo:               [7] ����
echo:               [0] �˳�
echo:            ___________________________________________________
echo:
call :_color2 %_White% "        " %_Green% "�ڼ������������ѡ�� [1,2,3,4,5,6,7,0]"
choice /C:12345670 /N
set _erl=%errorlevel%

if %_erl%==8 exit /b
if %_erl%==7 start %mas% & goto MainMenu
if %_erl%==6 start https://www.internetdownloadmanager.com/download.html & goto MainMenu
if %_erl%==5 goto :_restoreupd
if %_erl%==4 goto :_noupdate
if %_erl%==3 goto _reset
if %_erl%==2 (set frz=0&goto :_activate)
if %_erl%==1 (set frz=1&goto :_activate)
goto :MainMenu

::========================================================================================================================================

:_reset

call :log "��ʼִ����������"
cls
chcp 936 >nul 2>&1
if not %HKCUsync%==1 (
if not defined terminal mode 153, 35
) else (
if not defined terminal mode 113, 35
)
if not defined terminal %psc% "&%_buf%" %nul%

echo:
%idmcheck% && call :kill_idm

set _time=
for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmssfff')"') do set _time=%%a

echo:
echo ���ڱ��� CLSID ע����� %SystemRoot%\Temp

reg export %CLSID% "%SystemRoot%\Temp\_Backup_HKCU_CLSID_%_time%.reg"
if not %HKCUsync%==1 reg export %CLSID2% "%SystemRoot%\Temp\_Backup_HKU-%_sid%_CLSID_%_time%.reg"
call :log "�ѱ���ע���: _Backup_HKCU_CLSID_%_time%.reg"
if not %HKCUsync%==1 call :log "�ѱ���ע���: _Backup_HKU-%_sid%_CLSID_%_time%.reg"

call :delete_queue
%psc% "$sid = '%_sid%'; $HKCUsync = %HKCUsync%; $lockKey = $null; $deleteKey = 1; $f=[io.file]::ReadAllText('!_batp!',[Text.Encoding]::GetEncoding(936)) -split ':regscan\:.*';iex ($f[1])"

call :add_key

echo:
echo %line%
echo:
call :_color %Green% "IDM ��������ɡ�"

goto done

:delete_queue

echo:
echo ����ɾ�� IDM ע�����...
echo:
call :log "��ʼɾ�� IDM ע�����"

for %%# in (
""HKCU\Software\DownloadManager" "/v" "FName""
""HKCU\Software\DownloadManager" "/v" "LName""
""HKCU\Software\DownloadManager" "/v" "Email""
""HKCU\Software\DownloadManager" "/v" "Serial""
""HKCU\Software\DownloadManager" "/v" "scansk""
""HKCU\Software\DownloadManager" "/v" "tvfrdt""
""HKCU\Software\DownloadManager" "/v" "radxcnt""
""HKCU\Software\DownloadManager" "/v" "LstCheck""
""HKCU\Software\DownloadManager" "/v" "ptrk_scdt""
""HKCU\Software\DownloadManager" "/v" "LastCheckQU""
"%HKLM%"
) do for /f "tokens=* delims=" %%A in ("%%~#") do (
set "reg="%%~A"" &reg query !reg! %nul% && call :del
)

if not %HKCUsync%==1 for %%# in (
""HKU\%_sid%\Software\DownloadManager" "/v" "FName""
""HKU\%_sid%\Software\DownloadManager" "/v" "LName""
""HKU\%_sid%\Software\DownloadManager" "/v" "Email""
""HKU\%_sid%\Software\DownloadManager" "/v" "Serial""
""HKU\%_sid%\Software\DownloadManager" "/v" "scansk""
""HKU\%_sid%\Software\DownloadManager" "/v" "tvfrdt""
""HKU\%_sid%\Software\DownloadManager" "/v" "radxcnt""
""HKU\%_sid%\Software\DownloadManager" "/v" "LstCheck""
""HKU\%_sid%\Software\DownloadManager" "/v" "ptrk_scdt""
""HKU\%_sid%\Software\DownloadManager" "/v" "LastCheckQU""
) do for /f "tokens=* delims=" %%A in ("%%~#") do (
set "reg="%%~A"" &reg query !reg! %nul% && call :del
)

exit /b

:del

reg delete %reg% /f %nul%

if "%errorlevel%"=="0" (
set "reg=%reg:"=%"
echo ��ɾ�� - !reg!
call :log "��ɾ�� - !reg!"
) else (
set "reg=%reg:"=%"
call :_color2 %Red% "ʧ�� - !reg!"
call :set_exit 1 "ɾ��ʧ�� - !reg!"
)

exit /b

::========================================================================================================================================

::  ���� / �ָ� IDM ���Զ����¼��
::
::  ԭ����HKCU\Software\DownloadManager �µ� CheckUpdtVM Ϊ 0 ʱ��IDM ����
::  �Զ�����°汾��Ҳ�Ͳ��ᷴ������"�����°汾 / �����"����ʾ���ڡ�
::  ��ֵֻӰ����¼����Ϊ����д���кš����� CLSID����ʱ���ò˵� [5] �Ļء�
::  ˳���ĺô���IDM �Զ��������°�󼤻��ʧЧ���ص����¼�������ס��ǰ״̬��

:_noupdate

set "_updval=0"
set "_updact=����"
goto :_updapply

:_restoreupd

set "_updval=1"
set "_updact=�ָ�"

:_updapply

call :log "��ʼ%_updact% IDM �Զ����¼�飬CheckUpdtVM=%_updval%"
cls
chcp 936 >nul 2>&1
if not defined terminal mode 100, 30

echo:
if not exist "%IDMan%" (
call :_color %Red% "IDM [Internet Download Manager] δ��װ��"
echo ����ԴӴ���ַ����: https://www.internetdownloadmanager.com/download.html
call :set_exit 1 "δ��⵽ IDM ��װ"
goto done
)

echo ����%_updact% IDM ���Զ����¼��...
echo:

set "_updold="
for /f "tokens=3" %%a in ('reg query "HKCU\Software\DownloadManager" /v CheckUpdtVM %nul6%') do set "_updold=%%a"
if defined _updold (
echo ���ǰ CheckUpdtVM = !_updold!
call :log "���ǰ CheckUpdtVM = !_updold!"
) else (
echo ���ǰδ���� CheckUpdtVM��IDM Ĭ�ϻ��Զ�������
call :log "���ǰ CheckUpdtVM ������"
)

%idmcheck% && (echo: & echo ���ڹر� IDM �Ա�������Ч... & call :kill_idm)

echo:
set "reg="HKCU\Software\DownloadManager" /v "CheckUpdtVM" /t REG_DWORD /d "%_updval%"" & call :_updset
if not %HKCUsync%==1 (
set "reg="HKU\%_sid%\Software\DownloadManager" /v "CheckUpdtVM" /t REG_DWORD /d "%_updval%"" & call :_updset
)

echo:
echo %line%
echo:
if "%_updval%"=="0" (
call :_color %Green% "�ѽ��� IDM ���Զ����¼�飬���µ��������ٳ��֡�"
echo:
call :_color %Gray% "����ָ����������˵�ѡ�� [5] �ָ� IDM ������ʾ��"
call :_color %Gray% "���ѣ�ͣ���ڵ�ǰ�汾�ɱ�����º󼤻�ʧЧ����Ҳ���ٻ�ùٷ��޸���"
) else (
call :_color %Green% "�ѻָ� IDM ���Զ����¼�顣"
echo:
call :_color %Gray% "���ѣ�IDM ���µ��°汾�󼤻����ʧЧ����ʱ�������б��ű����ɡ�"
)

goto done

:_updset

reg add %reg% /f %nul%

if "%errorlevel%"=="0" (
set "reg=%reg:"=%"
echo ��д�� - !reg!
call :log "��д�� - !reg!"
) else (
set "reg=%reg:"=%"
call :_color2 %Red% "ʧ�� - !reg!"
call :set_exit 1 "д��ʧ�� - !reg!"
)

exit /b

::========================================================================================================================================

:_activate

if %frz%==1 (call :log "��ʼ��������������") else (call :log "��ʼ��������")
cls
chcp 936 >nul 2>&1
if not %HKCUsync%==1 (
if not defined terminal mode 153, 35
) else (
if not defined terminal mode 113, 35
)
if not defined terminal %psc% "&%_buf%" %nul%

if %frz%==0 if %_unattended%==0 (
echo:
echo %line%
echo:
echo      ��ʾ�����ֻ����£������ IDM ���ܵ���������кŴ��ڡ�
echo:
call :_color2 %_White% "     " %_Green% "���ȵ������Ƿ��ز˵���ѡ [1] ���������ڡ�"
echo %line%
echo:
choice /C:19 /N /M ">    [1] ���� [9] ���� : "
if !errorlevel!==1 goto :MainMenu
cls
chcp 936 >nul 2>&1
)

echo:
if not exist "%IDMan%" (
call :_color %Red% "IDM [Internet Download Manager] δ��װ��"
echo ����ԴӴ���ַ����: https://www.internetdownloadmanager.com/download.html
call :set_exit 1 "δ��⵽ IDM ��װ"
goto done
)

:: Internet check with internetdownloadmanager.com ping and port 80 test

set _int=
for /f "delims=[] tokens=2" %%# in ('ping -n 1 internetdownloadmanager.com') do (if not [%%#]==[] set _int=1)

if not defined _int (
%psc% "$t = New-Object Net.Sockets.TcpClient;try{$t.Connect("""internetdownloadmanager.com""", 80)}catch{};$t.Connected" | findstr /i "true" %nul1% || (
call :_color %Red% "�޷����ӵ� internetdownloadmanager.com�����̱���ֹ..."
call :set_exit 1 "�޷����ӵ� internetdownloadmanager.com"
goto done
)
call :_color %Gray% "Ping ���Ե� internetdownloadmanager.com ʧ��"
echo:
)

for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "regwinos=%%b"
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set "regarch=%%b"
for /f "tokens=6-7 delims=[]. " %%i in ('ver') do if "%%j"=="" (set fullbuild=%%i) else (set fullbuild=%%i.%%j)
for /f "tokens=2*" %%a in ('reg query "HKU\%_sid%\Software\DownloadManager" /v idmvers %nul6%') do set "IDMver=%%b"

echo ��⵽��Ϣ - [%regwinos% ^| %fullbuild% ^| %regarch% ^| IDM: %IDMver%]
call :log "��⵽��Ϣ - [%regwinos% | %fullbuild% | %regarch% | IDM: %IDMver%]"

%idmcheck% && (echo: & call :kill_idm)

set _time=
for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmssfff')"') do set _time=%%a

echo:
echo ���ڱ��� CLSID ע����� %SystemRoot%\Temp

reg export %CLSID% "%SystemRoot%\Temp\_Backup_HKCU_CLSID_%_time%.reg"
if not %HKCUsync%==1 reg export %CLSID2% "%SystemRoot%\Temp\_Backup_HKU-%_sid%_CLSID_%_time%.reg"

call :delete_queue
call :add_key

%psc% "$sid = '%_sid%'; $HKCUsync = %HKCUsync%; $lockKey = 1; $deleteKey = $null; $toggle = 1; $f=[io.file]::ReadAllText('!_batp!',[Text.Encoding]::GetEncoding(936)) -split ':regscan\:.*';iex ($f[1])"

if %frz%==0 call :register_IDM

call :download_files
if not defined _fileexist (
%eline%
echo ����: �޷�ͨ�� IDM �����ļ���
echo:
echo ����: %mas%
call :set_exit 1 "IDM ���ز���ʧ��"
goto :done
)

%psc% "$sid = '%_sid%'; $HKCUsync = %HKCUsync%; $lockKey = 1; $deleteKey = $null; $f=[io.file]::ReadAllText('!_batp!',[Text.Encoding]::GetEncoding(936)) -split ':regscan\:.*';iex ($f[1])"

echo:
echo %line%
echo:
if %frz%==0 (
call :_color %Green% "IDM ��������ɡ�"
echo:
call :_color %Gray% "�� IDM ����������кŴ��ڣ���ص��˵���ѡ [1] ���������ڡ�"
) else (
call :_color %Green% "IDM �� 30 ���������ѳɹ����ö��ᡣ"
echo:
call :_color %Gray% "��� IDM ��ʾע�ᵯ���������°�װ IDM��"
)
echo:
call :_color %Gray% "IDM �Զ����µ��°汾�����ü���ʧЧ������Ƶ����������ʾ���������˵�ѡ [4] ���ø��¡�"

::========================================================================================================================================

:done

echo %line%
echo:

::  ��βʱ�ѱ�������־λ����ʽ��ӡ����������ʱ�û���ֱ���õ���ԭ��ں�
::  �ɷ�������־������ȥ���ĵ���·����

if defined _time call :_color %Gray% "ע�������: %SystemRoot%\Temp\_Backup_*_%_time%.reg ����ԭ��˫�����ļ����뼴�ɣ�"
if "%_log_enabled%"=="1" call :_color %Gray% "��־�ļ�: %log_file%"
if not "%exit_code%"=="0" if not "%_log_enabled%"=="1" call :_color %Gray% "��������ǰ�ɼ� /log ��������һ�Σ���������־�ļ���"

echo:
echo:
call :log "���̽������˳��� %exit_code%"
if %_unattended%==1 (
if %_silent%==1 exit /b %exit_code%
timeout /t 2 & exit /b %exit_code%
)

if defined terminal (
call :_color %_Yellow% "�� 0 ������..."
choice /c 0 /n
) else (
call :flush_input
call :_color %_Yellow% "�����������..."
pause %nul1%
)
goto MainMenu

:done2

if "%_log_enabled%"=="1" if %_silent%==0 echo ��־�ļ�: %log_file%
call :log "���̽������˳��� %exit_code%"
if %_unattended%==1 (
if %_silent%==1 exit /b %exit_code%
timeout /t 2 & exit /b %exit_code%
)

if defined terminal (
echo �� 0 ���˳�...
choice /c 0 /n
) else (
	call :flush_input
	echo ��������˳�...
	pause %nul1%
	)
	exit /b %exit_code%

::========================================================================================================================================

:_rcont

reg add %reg% %nul%
call :add
exit /b

:register_IDM

echo:
echo ����Ӧ��ע����Ϣ...
echo:

set /a fname = %random% %% 9999 + 1000
set /a lname = %random% %% 9999 + 1000
set email=%fname%.%lname%@tonec.com

for /f "delims=" %%a in ('%psc% "$key = -join ((Get-Random -Count  20 -InputObject ([char[]]('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'))));$key = ($key.Substring(0,  5) + '-' + $key.Substring(5,  5) + '-' + $key.Substring(10,  5) + '-' + $key.Substring(15,  5) + $key.Substring(20));Write-Output $key" %nul6%') do (set key=%%a)

set "reg=HKCU\SOFTWARE\DownloadManager /v FName /t REG_SZ /d "%fname%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v LName /t REG_SZ /d "%lname%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Email /t REG_SZ /d "%email%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Serial /t REG_SZ /d "%key%"" & call :_rcont

if not %HKCUsync%==1 (
set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v FName /t REG_SZ /d "%fname%"" & call :_rcont
set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v LName /t REG_SZ /d "%lname%"" & call :_rcont
set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v Email /t REG_SZ /d "%email%"" & call :_rcont
set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v Serial /t REG_SZ /d "%key%"" & call :_rcont
)
exit /b

:download_files

echo:
echo �������ز�����Դ�Լ�����ע�������...
echo:
call :log "��ʼ���ز�����Դ"

set "file=%SystemRoot%\Temp\temp.png"
set _fileexist=

set link=https://www.internetdownloadmanager.com/images/idm_box_min.png
call :download
set link=https://www.internetdownloadmanager.com/register/IDMlib/images/idman_logos.png
call :download
set link=https://www.internetdownloadmanager.com/pictures/idm_about.png
call :download

echo:
timeout /t 3 %nul1%
%idmcheck% && call :kill_idm
if exist "%file%" del /f /q "%file%"
if defined _fileexist (call :log "���ز�����Դ�ɹ�") else (call :log "���ز�����Դʧ��")
exit /b

:download

set /a attempt=0
set "current_link=%link%"
if exist "%file%" del /f /q "%file%"
start "" /B "%IDMan%" /n /d "%link%" /p "%SystemRoot%\Temp" /f temp.png

:check_file

timeout /t 1 %nul1%
set /a attempt+=1
if exist "%file%" (set _fileexist=1&call :log "���سɹ�: %current_link%"&exit /b)
if %attempt% GEQ 20 (call :log "����ʧ��: %current_link%"&exit /b)
goto :Check_file

::========================================================================================================================================

:add_key

echo:
echo ��������ע�����...
echo:
call :log "��ʼ����ע�����"

set "reg="%HKLM%" /v "AdvIntDriverEnabled2""

reg add %reg% /t REG_DWORD /d "1" /f %nul%

:add

if "%errorlevel%"=="0" (
set "reg=%reg:"=%"
echo ������ - !reg!
call :log "������ - !reg!"
) else (
set "reg=%reg:"=%"
call :_color2 %Red% "ʧ�� - !reg!"
call :set_exit 1 "����ʧ�� - !reg!"
)
exit /b

::========================================================================================================================================

::  ������� PowerShell ������ cmd ִ�еģ����ǿ� [io.file]::ReadAllText �ѱ��ļ�
::  ������������������ǰ��ĳɶԱ���г����󽻸� iex ִ�С�ReadAllText �ĵ���������
::  ���ļ�û�� BOM ʱ�� UTF-8 ���룬�����ű����� BOM �� GBK�����������һ�����
::  ����ȫ������滻�ַ����û�������ע���ɨ��������һ�����롣����ÿһ����ȡ
::  ���ļ��ĵ��ö�������ʽ�� [Text.Encoding]::GetEncoding(936)��
::  ����������ֻ����������������καȽϻ��߼��жϡ�

:regscan:
$finalValues = @()

$arch = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').PROCESSOR_ARCHITECTURE
if ($arch -eq "x86") {
  $regPaths = @("HKCU:\Software\Classes\CLSID", "Registry::HKEY_USERS\$sid\Software\Classes\CLSID")
} else {
  $regPaths = @("HKCU:\Software\Classes\WOW6432Node\CLSID", "Registry::HKEY_USERS\$sid\Software\Classes\Wow6432Node\CLSID")
}

foreach ($regPath in $regPaths) {
    if (($regPath -match "HKEY_USERS") -and ($HKCUsync -ne $null)) {
        continue
    }

	Write-Host
	Write-Host "����ɨ�� $regPath  �е� IDM CLSID ע�����"
	Write-Host

    $subKeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue -ErrorVariable lockedKeys | Where-Object { $_.PSChildName -match '^\{[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}\}$' }

    foreach ($lockedKey in $lockedKeys) {
        $leafValue = Split-Path -Path $lockedKey.TargetObject -Leaf
        $finalValues += $leafValue
        Write-Output "$leafValue - ��������������"
    }

    if ($subKeys -eq $null) {
	continue
	}

	$subKeysToExclude = "LocalServer32", "InProcServer32", "InProcHandler32"

    $filteredKeys = $subKeys | Where-Object { !($_.GetSubKeyNames() | Where-Object { $subKeysToExclude -contains $_ }) }

    foreach ($key in $filteredKeys) {
        $fullPath = $key.PSPath
        $keyValues = Get-ItemProperty -Path $fullPath -ErrorAction SilentlyContinue
        $defaultValue = $keyValues.PSObject.Properties | Where-Object { $_.Name -eq '(default)' } | Select-Object -ExpandProperty Value

        if (($defaultValue -match "^\d+$") -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - ��Ĭ��ֵ�з������֣������֣�"
            continue
        }
        if (($defaultValue -match "\+|=") -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - ��Ĭ��ֵ�з��� + �� = �������֣�"
            continue
        }
        $versionValue = Get-ItemProperty -Path "$fullPath\Version" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty '(default)' -ErrorAction SilentlyContinue
        if (($versionValue -match "^\d+$") -and ($key.SubKeyCount -eq 1)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - �� \Version �з������֣��Ӽ�����Ϊһ��"
            continue
        }
        $keyValues.PSObject.Properties | ForEach-Object {
            if ($_.Name -match "MData|Model|scansk|Therad") {
                $finalValues += $($key.PSChildName)
                Write-Output "$($key.PSChildName) - �ҵ� MData Model scansk Therad"
                continue
            }
        }
        if (($key.ValueCount -eq 0) -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - ��ȫ�յ�"
            continue
        }
    }
}

$finalValues = @($finalValues | Select-Object -Unique)

if ($finalValues -ne $null) {
    Write-Host
    if ($lockKey -ne $null) {
        Write-Host "�������� IDM CLSID ע�����..."
    }
    if ($deleteKey -ne $null) {
        Write-Host "����ɾ�� IDM CLSID ע�����..."
    }
    Write-Host
} else {
    Write-Host "δ�ҵ� IDM CLSID ע�����"
	Exit
}

if (($finalValues.Count -gt 20) -and ($toggle -ne $null)) {
	$lockKey = $null
	$deleteKey = 1
    Write-Host "IDM ���������� 20 ������Ϊɾ�����Ƕ���������..."
	Write-Host
}

function Take-Permissions {
    param($rootKey, $regKey)
    $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule(2, $False)
    $TypeBuilder = $ModuleBuilder.DefineType(0)

    $TypeBuilder.DefinePInvokeMethod('RtlAdjustPrivilege', 'ntdll.dll', 'Public, Static', 1, [int], @([int], [bool], [bool], [bool].MakeByRefType()), 1, 3) | Out-Null
    9,17,18 | ForEach-Object { $TypeBuilder.CreateType()::RtlAdjustPrivilege($_, $true, $false, [ref]$false) | Out-Null }

    $SID = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $IDN = ($SID.Translate([System.Security.Principal.NTAccount])).Value
    $Admin = New-Object System.Security.Principal.NTAccount($IDN)

    $everyone = New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')
    $none = New-Object System.Security.Principal.SecurityIdentifier('S-1-0-0')

    $key = [Microsoft.Win32.Registry]::$rootKey.OpenSubKey($regkey, 'ReadWriteSubTree', 'TakeOwnership')

    $acl = New-Object System.Security.AccessControl.RegistrySecurity
    $acl.SetOwner($Admin)
    $key.SetAccessControl($acl)

    $key = $key.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, 'FullControl', 'ContainerInherit', 'None', 'Allow')
    $acl.ResetAccessRule($rule)
    $key.SetAccessControl($acl)

    if ($lockKey -ne $null) {
        $acl = New-Object System.Security.AccessControl.RegistrySecurity
        $acl.SetOwner($none)
        $key.SetAccessControl($acl)

        $key = $key.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, 'FullControl', 'Deny')
        $acl.ResetAccessRule($rule)
        $key.SetAccessControl($acl)
    }
}

foreach ($regPath in $regPaths) {
    if (($regPath -match "HKEY_USERS") -and ($HKCUsync -ne $null)) {
        continue
    }
    foreach ($finalValue in $finalValues) {
        $fullPath = Join-Path -Path $regPath -ChildPath $finalValue
        if ($fullPath -match 'HKCU:') {
            $rootKey = 'CurrentUser'
        } else {
            $rootKey = 'Users'
        }

        $position = $fullPath.IndexOf("\")
        $regKey = $fullPath.Substring($position + 1)

        if ($lockKey -ne $null) {
            if (-not (Test-Path -Path $fullPath -ErrorAction SilentlyContinue)) { New-Item -Path $fullPath -Force -ErrorAction SilentlyContinue | Out-Null }
            Take-Permissions $rootKey $regKey
            try {
                Remove-Item -Path $fullPath -Force -Recurse -ErrorAction Stop
                Write-Host -back 'DarkRed' -fore 'white' "ʧ�� - $fullPath"
            }
            catch {
                Write-Host "������ - $fullPath"
            }
        }

        if ($deleteKey -ne $null) {
            if (Test-Path -Path $fullPath) {
                Remove-Item -Path $fullPath -Force -Recurse -ErrorAction SilentlyContinue
                if (Test-Path -Path $fullPath) {
                    Take-Permissions $rootKey $regKey
                    try {
                        Remove-Item -Path $fullPath -Force -Recurse -ErrorAction Stop
                        Write-Host "��ɾ�� - $fullPath"
                    }
                    catch {
                        Write-Host -back 'DarkRed' -fore 'white' "ʧ�� - $fullPath"
                    }
                }
                else {
                    Write-Host "��ɾ�� - $fullPath"
                }
            }
        }
    }
}
:regscan:

::========================================================================================================================================

:kill_idm

::  taskkill /f /im ���ÿ��ͬ�����̸����һ�У�����ֹ�Ĵ�ӡ���ɹ�: ����ֹ���̡���
::  stdout����Ȩ�޵ģ������û��Ự / ���������Լ����ʵ������ӡ���ܾ����ʡ����� stderr��
::  ������ǰ��ֱ��©�������ϣ����ر� IDM ʧ�ܲ���Ӱ�켤�������û�ȴ���
::  ��䡰�ܾ����ʡ������ɼ���ʧ�ܡ�����ͳһ�տڣ����ȫ������־��
::  ���治�ٳ������ϵͳ�������̶����� 0������ taskkill ���˳�����Ⱦ���÷���

taskkill /f /im idman.exe %nul%
if "%errorlevel%"=="0" (
call :log "�ѹر��������е� IDMan.exe"
) else (
call :log "�ر� IDMan.exe δ��ȫ�ɹ���taskkill �˳��� %errorlevel%�������ڶ�ʵ�����Ự������Ӱ���������"
)
exit /b 0

:flush_input

::  pause ���������Ѽ��̻����������еİ������������̰������غ͵ȴ����û�
::  ��;�����õļ���һֱ���ڻ�����������������ִ�е� pause ʱ�����̳Ե���
::  ���־��ǡ�û���κμ�ȴ�Լ�����ȥ�ˡ�����������ʾǰ����ջ�������
::  choice ��ֻ֧����ָ�����������ܸ�����Ӱ�죬����ֻ�� pause ·�����á�
::  stdin ���ض���ʱ���ܵ����� / CI��RawUI �ᱨ����try-catch �Ե����ɡ�

%psc% -NoProfile -Command "try{$Host.UI.RawUI.FlushInputBuffer()}catch{}" %nul%
exit /b 0

:set_exit
if "%~1"=="" exit /b
if "%exit_code%"=="0" set "exit_code=%~1"
if not "%~2"=="" call :log %~2
exit /b

:extract_logpath

::  ��������������ȡ�� /log= �����·����
::  ��һ�� for �� = �У�token 2 �ǵ�һ�� = ֮���ȫ�����ݣ�"C:\x.log /silent"����
::  �ڶ��� for ���ո��У�token 1 ����·��������
::  ��������ǰ�Ѿ��� %_args:"=% ȥ�����������ţ�����·�����ܺ��ո�
::  ȡ���Ķ������� / ��ͷ��˵���û�д���� "/log= /silent" �����·�������Ե���

for /f "tokens=2 delims==" %%a in ("%_args%") do for /f "tokens=1" %%b in ("%%a") do set "_logpath=%%b"
if not defined _logpath exit /b
if "%_logpath:~0,1%"=="/" set "_logpath="
if defined _logpath set _log=1
exit /b

:init_log

::  ��������ӳ���������ִ�У���д�� if(...) ������ڣ�%_logstamp% ����
::  �������ʱһ����չ����ȡ������һ�и�д���ֵ����־�ļ������˻���
::  ������ IAS-%_logstamp%.log�����о�Ĭ���ж�׷�ӵ�ͬһ���ļ���

if not defined _logpath goto :init_log_default
call :init_logpath
if defined log_file exit /b
echo [����] ��־·�� %_logpath% ����д������Ĭ��λ�á�

:init_log_default

if not exist "%log_dir%" md "%log_dir%" 2>nul
set "_logstamp=%date%_%time%"
set "_logstamp=%_logstamp::=%"
set "_logstamp=%_logstamp: =0%"
set "_logstamp=%_logstamp:.=%"
set "_logstamp=%_logstamp:,=%"
set "_logstamp=%_logstamp:/=%"
set "_logstamp=%_logstamp:\=%"
set "log_file=%log_dir%\IAS-%_logstamp%.log"
exit /b

:init_logpath

::  �Ƚ���Ŀ¼����дһ�Σ�д����ȥ�ͷ��ؿ� log_file���ɵ��÷�����Ĭ��·����

for %%i in ("%_logpath%") do set "_lpdir=%%~dpi"
if not exist "%_lpdir%" md "%_lpdir%" 2>nul
if not exist "%_lpdir%" exit /b
(echo:)>>"%_logpath%" 2>nul
if not exist "%_logpath%" exit /b
set "log_file=%_logpath%"
exit /b

:log
if not "%_log_enabled%"=="1" exit /b
set "_log_now=%date% %time%"
>>"%log_file%" echo [%_log_now%] %*
exit /b

::========================================================================================================================================

:_color

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[0m
) else (
echo %~3
)
exit /b

:_color2

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[%~3%~4%esc%[0m
) else (
echo %~3%~6
)
exit /b

::========================================================================================================================================
:: Leave empty line below
