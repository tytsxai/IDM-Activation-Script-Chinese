@set iasver=1.0.1
::  本脚本最后实际验证过的 IDM 版本（主菜单据此显示"已适配版本"，发版时同步更新）
@set idmsupport=6.43
@setlocal DisableDelayedExpansion
@echo off

::  强制设置代码页为 936 (GBK/简体中文)
chcp 936 >nul 2>&1


::============================================================================
::
::   IDM 激活脚本 (IAS)
::
::   项目主页: https://github.com/tytsxai/IDM-Activation-Script-Chinese
::   问题反馈: https://github.com/tytsxai/IDM-Activation-Script-Chinese/issues
::   许可证  : GPL-3.0（详见仓库根目录 LICENSE）
::
::   ----- 代码导航（便于后续维护） -----
::   001-047 行 : 头部元信息、代码页设置、默认开关（iasver 脚本版本 / idmsupport 已适配 IDM 版本）
::   047-117 行 : PATH 设置、Sysnative / SysArm32 架构重入、参数解析（/act /frz /res /noupd /reupd /silent /log[=路径]）
::   117-152 行 : 日志初始化、静默模式校验、Null 服务检测
::   152-445 行 : 环境探测（管理员权限、IDM 安装路径、CLSID 注册表项、网络连通性）
::   447-510 行 : IDM 版本探测 + 主菜单（冻结 / 激活 / 重置 / 更新开关 / 下载 / 帮助），交互分派
::   512-610 行 : 重置流程与注册表删除队列
::   615-694 行 : 禁用 / 恢复 IDM 自动更新检查（CheckUpdtVM）
::   696-945 行 : 激活与冻结核心流程、注册表备份、随机注册信息注入、收尾输出
::   948-1126 行: CLSID 扫描（PowerShell 内嵌段）
::   1128-1250 行: 退出码记账、进程与输入子程序（:kill_idm / :flush_input）、
::                日志子程序（:extract_logpath / :init_log / :log）、着色输出
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

::  /log=路径 的路径要单独提取，不能靠上面的 for 循环：for %%A in (...) 的
::  集合解析把 = 也当分隔符，"/log=C:\x.log" 在那里已经被拆成 "/log" 和
::  "C:\x.log" 两个 token，比较得到的只会是 "/log"。所以直接从完整参数串里取。
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
call :log "IAS %iasver% 启动，参数: %_args%"
call :log "日志输出: %log_file%"
if %_silent%==0 echo 日志文件: %log_file%
)

if %_silent%==1 if %_activate%==0 if %_freeze%==0 if %_reset%==0 if %_noupd%==0 if %_reupd%==0 (
call :set_exit 2 "静默模式缺少操作参数，退出"
goto done2
)

::  Check if Null service is working, it's important for the batch script

sc query Null | find /i "RUNNING" >nul 2>&1
if %errorlevel% NEQ 0 (
call :log "警告: Null 服务未运行，可能导致脚本出错"
echo:
echo Null 服务未运行，脚本可能会出错...
echo:
echo:
echo 帮助 - %mas%
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
echo 错误: 脚本包含LF换行符或脚本末尾缺少空行。
echo:
call :set_exit 2 "错误: 检测到 LF 换行符或缺少末尾空行"
if %_silent%==1 (ping 127.0.0.1 -n 2 >nul) else ping 127.0.0.1 -n 6 >nul
popd
exit /b %exit_code%
)
popd

::========================================================================================================================================

cls
chcp 936 >nul 2>&1
color 07
title  IDM 激活脚本 %iasver%

::========================================================================================================================================

set "nul1=1>nul"
set "nul2=2>nul"
set "nul6=2^>nul"
set "nul=>nul 2>&1"

::  IMPORTANT: -NoProfile -Command must NOT be omitted. Bare powershell.exe "..."
::  enters interactive mode on real consoles and hangs forever. All PS calls in
::  this file go through %psc%; never manually add -NoProfile -Command at call sites
::  (it would duplicate and silently break). See issue #4.
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
echo 检测到不支持的操作系统版本 [%winbuild%].
echo 此脚本支持 Windows 7/8/8.1/10/11 及其后续版本。
call :set_exit 2 "不支持的操作系统版本 [%winbuild%]"
goto done2
)

for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" (
%nceline%
echo 系统中找不到 powershell.exe。
call :set_exit 2 "系统中找不到 powershell.exe"
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
echo 脚本从临时文件夹中运行。
echo 你可能从压缩文件查看器中运行脚本。
echo:
echo 请解压压缩文件，然后从解压后的文件夹中运行脚本。
call :set_exit 2 "脚本从临时文件夹运行，被阻止"
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
echo PowerShell 无法正常工作，进程被阻止...
echo 你的组织可能禁用了 Powershell 应用，以防止这些情况。
echo:
echo 查看网页以获取帮助：%mas%
call :set_exit 2 "PowerShell 运行被阻止"
goto done2
)

::========================================================================================================================================

::  Elevate script as admin and pass arguments and preventing loop

%nul1% fltmc || (
if not defined _elev %psc% "start cmd.exe -arg '/c \"!_PSarg!\"' -verb runas" && exit /b
%eline%
echo 此脚本需要管理员权限。
echo 请右键此脚本，选择"以管理员身份运行"。
call :set_exit 2 "缺少管理员权限"
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
::  conhost 重入用于关闭 QuickEdit；若 start 被拒绝（安全软件/策略），回退到当前窗口继续，避免只显示“拒绝访问。”后闪退
::  注意：不要用 if (...) 包住 start 行——d1-d4 展开后含大量括号，会截断代码块。
if %winbuild% LSS 17763 goto :qeLegacy
start "" conhost.exe %psc% "%d1% %d2% %d3% %d4% & cmd.exe '/c' '!_PSarg! -qedit'"
if not errorlevel 1 exit /b
echo:
echo [警告] 无法启动 conhost 控制台（拒绝访问或被安全软件拦截），将在当前窗口继续...
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
echo 当前版本：%iasver% （本地仓库版本）
echo 如需检查更新，请访问项目主页：%mas%
echo ________________________________________________
echo:
)

::========================================================================================================================================

cls
chcp 936 >nul 2>&1
title  IDM 激活脚本 %iasver%

echo:
echo 正在初始化...

::  Check WMI（优先 CIM，失败再回退旧版 WMI；新版 Windows 上 Get-WmiObject 的 DCOM 路径可能卡死）

echo   - 检测系统信息 (WMI/CIM)...
%psc% "$c=$null;try{$c=Get-CimInstance Win32_ComputerSystem -EA Stop}catch{};if(-not $c){try{$c=Get-WmiObject Win32_ComputerSystem -EA Stop}catch{}};$c.CreationClassName" %nul2% | find /i "computersystem" %nul1% || (
%eline%
%psc% "$c=$null;try{$c=Get-CimInstance Win32_ComputerSystem -EA Stop}catch{};if(-not $c){try{$c=Get-WmiObject Win32_ComputerSystem -EA Stop}catch{}};$c.CreationClassName"
echo:
echo WMI 无法正常工作，进程被阻止...
echo:
echo 查看网页以获取帮助：%mas%
call :set_exit 2 "WMI 查询失败"
goto done2
)

::  Check user account SID

echo   - 获取用户账户 SID...
set _sid=
for /f "delims=" %%a in ('%psc% "$c=$null;try{$c=Get-CimInstance Win32_ComputerSystem -EA Stop}catch{$c=Get-WmiObject Win32_ComputerSystem};([System.Security.Principal.NTAccount]$c.UserName).Translate([System.Security.Principal.SecurityIdentifier]).Value" %nul6%') do (set _sid=%%a)

reg query HKU\%_sid%\Software %nul% || (
for /f "delims=" %%a in ('%psc% "$explorerProc = Get-Process -Name explorer | Where-Object {$_.SessionId -eq (Get-Process -Id $pid).SessionId} | Select-Object -First 1; $sid = (gwmi -Query ('Select * From Win32_Process Where ProcessID=' + $explorerProc.Id)).GetOwnerSid().Sid; $sid" %nul6%') do (set _sid=%%a)
)

reg query HKU\%_sid%\Software %nul% || (
%eline%
echo:
echo [%_sid%]
echo 未找到用户帐户 SID，进程被阻止...
echo:
echo 查看网页以获取帮助：%mas%
call :set_exit 2 "未能获取当前用户 SID"
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

echo   - 校验注册表访问权限...
%nul% reg add %CLSID2%\IAS_TEST
%nul% reg query %CLSID2%\IAS_TEST || (
%eline%
echo 无法写入 %CLSID2%
echo:
echo 查看网页以获取帮助：%mas%
call :set_exit 2 "无法写入 %CLSID2%"
goto done2
)

%nul% reg delete %CLSID2%\IAS_TEST /f

::========================================================================================================================================

if %_reset%==1 goto :_reset
if %_noupd%==1 goto :_noupdate
if %_reupd%==1 goto :_restoreupd
if %_activate%==1 (set frz=0&goto :_activate)
if %_freeze%==1 (set frz=1&goto :_activate)

::  探测本机已安装的 IDM 版本号，只读取 IDMan.exe 的文件版本信息，不写任何注册表。
::  主菜单据此显示"已适配版本 / 本机版本"，避免"支持最新版"这种模糊说法。

set "idmfound="
set "idmmm="
if exist "!IDMan!" (
for /f "delims=" %%a in ('%psc% "$v=(Get-Item -LiteralPath '!IDMan!').VersionInfo; if ($v.ProductVersion) {$v.ProductVersion.Trim()} else {$v.FileVersion}" %nul6%') do set "idmfound=%%a"
)
if defined idmfound for /f "tokens=1,2 delims=., " %%a in ("!idmfound!") do set "idmmm=%%a.%%b"
call :log "IDM 版本检测: [!idmfound!] 脚本已适配 %idmsupport%"

:MainMenu

cls
chcp 936 >nul 2>&1
title  IDM 激活脚本 %iasver%
if not defined terminal mode 75, 31

echo:
echo:
echo:                脚本 %iasver% ^| 已适配 IDM %idmsupport% 及之前的 6.x 版本
if defined idmmm (
echo:                本机检测到的 IDM：!idmfound!
if not "!idmmm!"=="%idmsupport%" echo:                注意：与已适配版本不同，异常时见 README 的 Q10
) else (
echo:                本机未检测到 IDM，请先安装 IDM 再激活
)
echo:            ___________________________________________________
echo:
echo:               [1] 冻结试用期（推荐）
echo:               [2] 激活（写入注册信息）
echo:               [3] 重置激活/试用期
echo:               _____________________________________________
echo:
echo:               [4] 禁用 IDM 更新提示
echo:               [5] 恢复 IDM 更新提示
echo:               _____________________________________________
echo:
echo:               [6] 下载 IDM
echo:               [7] 帮助
echo:               [0] 退出
echo:            ___________________________________________________
echo:
call :_color2 %_White% "        " %_Green% "在键盘上输入你的选项 [1,2,3,4,5,6,7,0]"
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

call :log "开始执行重置流程"
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
echo 正在备份 CLSID 注册表到 %SystemRoot%\Temp

reg export %CLSID% "%SystemRoot%\Temp\_Backup_HKCU_CLSID_%_time%.reg"
if not %HKCUsync%==1 reg export %CLSID2% "%SystemRoot%\Temp\_Backup_HKU-%_sid%_CLSID_%_time%.reg"
call :log "已备份注册表: _Backup_HKCU_CLSID_%_time%.reg"
if not %HKCUsync%==1 call :log "已备份注册表: _Backup_HKU-%_sid%_CLSID_%_time%.reg"

call :delete_queue
%psc% "$sid = '%_sid%'; $HKCUsync = %HKCUsync%; $lockKey = $null; $deleteKey = 1; $f=[io.file]::ReadAllText('!_batp!',[Text.Encoding]::GetEncoding(936)) -split ':regscan\:.*';iex ($f[1])"

call :add_key

echo:
echo %line%
echo:
call :_color %Green% "IDM 重置已完成。"

goto done

:delete_queue

echo:
echo 正在删除 IDM 注册表键...
echo:
call :log "开始删除 IDM 注册表键"

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
echo 已删除 - !reg!
call :log "已删除 - !reg!"
) else (
set "reg=%reg:"=%"
call :_color2 %Red% "失败 - !reg!"
call :set_exit 1 "删除失败 - !reg!"
)

exit /b

::========================================================================================================================================

::  禁用 / 恢复 IDM 的自动更新检查
::
::  原理：HKCU\Software\DownloadManager 下的 CheckUpdtVM 为 0 时，IDM 不再
::  自动检查新版本，也就不会反复弹出"发现新版本 / 请更新"的提示窗口。
::  该值只影响更新检查行为，不写序列号、不动 CLSID，随时可用菜单 [5] 改回。
::  顺带的好处：IDM 自动升级到新版后激活常常失效，关掉更新检查可以稳住当前状态。

:_noupdate

set "_updval=0"
set "_updact=禁用"
goto :_updapply

:_restoreupd

set "_updval=1"
set "_updact=恢复"

:_updapply

call :log "开始%_updact% IDM 自动更新检查，CheckUpdtVM=%_updval%"
cls
chcp 936 >nul 2>&1
if not defined terminal mode 100, 30

echo:
if not exist "%IDMan%" (
call :_color %Red% "IDM [Internet Download Manager] 未安装。"
echo 你可以从此网址下载: https://www.internetdownloadmanager.com/download.html
call :set_exit 1 "未检测到 IDM 安装"
goto done
)

echo 正在%_updact% IDM 的自动更新检查...
echo:

set "_updold="
for /f "tokens=3" %%a in ('reg query "HKCU\Software\DownloadManager" /v CheckUpdtVM %nul6%') do set "_updold=%%a"
if defined _updold (
echo 变更前 CheckUpdtVM = !_updold!
call :log "变更前 CheckUpdtVM = !_updold!"
) else (
echo 变更前未设置 CheckUpdtVM，IDM 默认会自动检查更新
call :log "变更前 CheckUpdtVM 不存在"
)

%idmcheck% && (echo: & echo 正在关闭 IDM 以便设置生效... & call :kill_idm)

echo:
set "reg="HKCU\Software\DownloadManager" /v "CheckUpdtVM" /t REG_DWORD /d "%_updval%"" & call :_updset
if not %HKCUsync%==1 (
set "reg="HKU\%_sid%\Software\DownloadManager" /v "CheckUpdtVM" /t REG_DWORD /d "%_updval%"" & call :_updset
)

echo:
echo %line%
echo:
if "%_updval%"=="0" (
call :_color %Green% "已禁用 IDM 的自动更新检查，更新弹窗不会再出现。"
echo:
call :_color %Gray% "如需恢复，请在主菜单选择 [5] 恢复 IDM 更新提示。"
call :_color %Gray% "提醒：停留在当前版本可避免更新后激活失效，但也不再获得官方修复。"
) else (
call :_color %Green% "已恢复 IDM 的自动更新检查。"
echo:
call :_color %Gray% "提醒：IDM 更新到新版本后激活可能失效，届时重新运行本脚本即可。"
)

goto done

:_updset

reg add %reg% /f %nul%

if "%errorlevel%"=="0" (
set "reg=%reg:"=%"
echo 已写入 - !reg!
call :log "已写入 - !reg!"
) else (
set "reg=%reg:"=%"
call :_color2 %Red% "失败 - !reg!"
call :set_exit 1 "写入失败 - !reg!"
)

exit /b

::========================================================================================================================================

:_activate

if %frz%==1 (call :log "开始冻结试用期流程") else (call :log "开始激活流程")
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
echo      提示：部分环境下，激活后 IDM 可能弹出虚假序列号窗口。
echo:
call :_color2 %_White% "     " %_Green% "更稳的做法是返回菜单改选 [1] 冻结试用期。"
echo %line%
echo:
choice /C:19 /N /M ">    [1] 返回 [9] 继续 : "
if !errorlevel!==1 goto :MainMenu
cls
chcp 936 >nul 2>&1
)

echo:
if not exist "%IDMan%" (
call :_color %Red% "IDM [Internet Download Manager] 未安装。"
echo 你可以从此网址下载: https://www.internetdownloadmanager.com/download.html
call :set_exit 1 "未检测到 IDM 安装"
goto done
)

:: Internet check with internetdownloadmanager.com ping and port 80 test

set _int=
for /f "delims=[] tokens=2" %%# in ('ping -n 1 internetdownloadmanager.com') do (if not [%%#]==[] set _int=1)

if not defined _int (
%psc% "$t = New-Object Net.Sockets.TcpClient;try{$t.Connect("""internetdownloadmanager.com""", 80)}catch{};$t.Connected" | findstr /i "true" %nul1% || (
call :_color %Red% "无法连接到 internetdownloadmanager.com，进程被阻止..."
call :set_exit 1 "无法连接到 internetdownloadmanager.com"
goto done
)
call :_color %Gray% "Ping 测试到 internetdownloadmanager.com 失败"
echo:
)

for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "regwinos=%%b"
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set "regarch=%%b"
for /f "tokens=6-7 delims=[]. " %%i in ('ver') do if "%%j"=="" (set fullbuild=%%i) else (set fullbuild=%%i.%%j)
for /f "tokens=2*" %%a in ('reg query "HKU\%_sid%\Software\DownloadManager" /v idmvers %nul6%') do set "IDMver=%%b"

echo 检测到信息 - [%regwinos% ^| %fullbuild% ^| %regarch% ^| IDM: %IDMver%]
call :log "检测到信息 - [%regwinos% | %fullbuild% | %regarch% | IDM: %IDMver%]"

%idmcheck% && (echo: & call :kill_idm)

set _time=
for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmssfff')"') do set _time=%%a

echo:
echo 正在备份 CLSID 注册表到 %SystemRoot%\Temp

reg export %CLSID% "%SystemRoot%\Temp\_Backup_HKCU_CLSID_%_time%.reg"
if not %HKCUsync%==1 reg export %CLSID2% "%SystemRoot%\Temp\_Backup_HKU-%_sid%_CLSID_%_time%.reg"

call :delete_queue
call :add_key

%psc% "$sid = '%_sid%'; $HKCUsync = %HKCUsync%; $lockKey = 1; $deleteKey = $null; $toggle = 1; $f=[io.file]::ReadAllText('!_batp!',[Text.Encoding]::GetEncoding(936)) -split ':regscan\:.*';iex ($f[1])"

if %frz%==0 call :register_IDM

call :download_files
if not defined _fileexist (
%eline%
echo 错误: 无法通过 IDM 下载文件。
echo:
echo 帮助: %mas%
call :set_exit 1 "IDM 下载测试失败"
goto :done
)

%psc% "$sid = '%_sid%'; $HKCUsync = %HKCUsync%; $lockKey = 1; $deleteKey = $null; $f=[io.file]::ReadAllText('!_batp!',[Text.Encoding]::GetEncoding(936)) -split ':regscan\:.*';iex ($f[1])"

echo:
echo %line%
echo:
if %frz%==0 (
call :_color %Green% "IDM 激活已完成。"
echo:
call :_color %Gray% "若 IDM 弹出虚假序列号窗口，请回到菜单改选 [1] 冻结试用期。"
) else (
call :_color %Green% "IDM 的 30 天试用期已成功设置冻结。"
echo:
call :_color %Gray% "如果 IDM 提示注册弹窗，请重新安装 IDM。"
)
echo:
call :_color %Gray% "IDM 自动更新到新版本可能让激活失效；若它频繁弹更新提示，可在主菜单选 [4] 禁用更新。"

::========================================================================================================================================

:done

echo %line%
echo:

::  收尾时把备份与日志位置显式打印出来：出错时用户能直接拿到还原入口和
::  可反馈的日志，不用去翻文档猜路径。

if defined _time call :_color %Gray% "注册表备份: %SystemRoot%\Temp\_Backup_*_%_time%.reg （还原：双击该文件导入即可）"
if "%_log_enabled%"=="1" call :_color %Gray% "日志文件: %log_file%"
if not "%exit_code%"=="0" if not "%_log_enabled%"=="1" call :_color %Gray% "反馈问题前可加 /log 参数重跑一次，会生成日志文件。"

echo:
echo:
call :log "流程结束，退出码 %exit_code%"
if %_unattended%==1 (
if %_silent%==1 exit /b %exit_code%
timeout /t 2 & exit /b %exit_code%
)

if defined terminal (
call :_color %_Yellow% "按 0 键返回..."
choice /c 0 /n
) else (
call :flush_input
call :_color %_Yellow% "按任意键返回..."
pause %nul1%
)
goto MainMenu

:done2

if "%_log_enabled%"=="1" if %_silent%==0 echo 日志文件: %log_file%
call :log "流程结束，退出码 %exit_code%"
if %_unattended%==1 (
if %_silent%==1 exit /b %exit_code%
timeout /t 2 & exit /b %exit_code%
)

if defined terminal (
echo 按 0 键退出...
choice /c 0 /n
) else (
	call :flush_input
	echo 按任意键退出...
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
echo 正在应用注册信息...
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
echo 正在下载测试资源以及锁定注册表键后...
echo:
call :log "开始下载测试资源"

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
if defined _fileexist (call :log "下载测试资源成功") else (call :log "下载测试资源失败")
exit /b

:download

set /a attempt=0
set "current_link=%link%"
if exist "%file%" del /f /q "%file%"
start "" /B "%IDMan%" /n /d "%link%" /p "%SystemRoot%\Temp" /f temp.png

:check_file

timeout /t 1 %nul1%
set /a attempt+=1
if exist "%file%" (set _fileexist=1&call :log "下载成功: %current_link%"&exit /b)
if %attempt% GEQ 20 (call :log "下载失败: %current_link%"&exit /b)
goto :Check_file

::========================================================================================================================================

:add_key

echo:
echo 正在添加注册表键...
echo:
call :log "开始添加注册表键"

set "reg="%HKLM%" /v "AdvIntDriverEnabled2""

reg add %reg% /t REG_DWORD /d "1" /f %nul%

:add

if "%errorlevel%"=="0" (
set "reg=%reg:"=%"
echo 已添加 - !reg!
call :log "已添加 - !reg!"
) else (
set "reg=%reg:"=%"
call :_color2 %Red% "失败 - !reg!"
call :set_exit 1 "添加失败 - !reg!"
)
exit /b

::========================================================================================================================================

::  下面这段 PowerShell 不是由 cmd 执行的，而是靠 [io.file]::ReadAllText 把本文件
::  自身读出来、按本段前后的成对标记切出来后交给 iex 执行。ReadAllText 的单参数重载
::  在文件没有 BOM 时按 UTF-8 解码，而本脚本是无 BOM 的 GBK，那样会把这一段里的
::  中文全部解成替换字符，用户看到的注册表扫描界面就是一屏乱码。所以每一处读取
::  本文件的调用都必须显式传 [Text.Encoding]::GetEncoding(936)。
::  这段里的中文只用于输出，不参与任何比较或逻辑判断。

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
	Write-Host "正在扫描 $regPath  中的 IDM CLSID 注册表键"
	Write-Host

    $subKeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue -ErrorVariable lockedKeys | Where-Object { $_.PSChildName -match '^\{[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}\}$' }

    foreach ($lockedKey in $lockedKeys) {
        $leafValue = Split-Path -Path $lockedKey.TargetObject -Leaf
        $finalValues += $leafValue
        Write-Output "$leafValue - 由于锁定被跳过"
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
            Write-Output "$($key.PSChildName) - 在默认值中发现数字（仅数字）"
            continue
        }
        if (($defaultValue -match "\+|=") -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - 在默认值中发现 + 或 = （仅数字）"
            continue
        }
        $versionValue = Get-ItemProperty -Path "$fullPath\Version" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty '(default)' -ErrorAction SilentlyContinue
        if (($versionValue -match "^\d+$") -and ($key.SubKeyCount -eq 1)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - 在 \Version 中发现数字（子键数量为一）"
            continue
        }
        $keyValues.PSObject.Properties | ForEach-Object {
            if ($_.Name -match "MData|Model|scansk|Therad") {
                $finalValues += $($key.PSChildName)
                Write-Output "$($key.PSChildName) - 找到 MData Model scansk Therad"
                continue
            }
        }
        if (($key.ValueCount -eq 0) -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $($key.PSChildName)
            Write-Output "$($key.PSChildName) - 完全空的"
            continue
        }
    }
}

$finalValues = @($finalValues | Select-Object -Unique)

if ($finalValues -ne $null) {
    Write-Host
    if ($lockKey -ne $null) {
        Write-Host "正在锁定 IDM CLSID 注册表键..."
    }
    if ($deleteKey -ne $null) {
        Write-Host "正在删除 IDM CLSID 注册表键..."
    }
    Write-Host
} else {
    Write-Host "未找到 IDM CLSID 注册表键"
	Exit
}

if (($finalValues.Count -gt 20) -and ($toggle -ne $null)) {
	$lockKey = $null
	$deleteKey = 1
    Write-Host "IDM 键数量大于 20 个，改为删除它们而不是锁定..."
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
                Write-Host -back 'DarkRed' -fore 'white' "失败 - $fullPath"
            }
            catch {
                Write-Host "已锁定 - $fullPath"
            }
        }

        if ($deleteKey -ne $null) {
            if (Test-Path -Path $fullPath) {
                Remove-Item -Path $fullPath -Force -Recurse -ErrorAction SilentlyContinue
                if (Test-Path -Path $fullPath) {
                    Take-Permissions $rootKey $regKey
                    try {
                        Remove-Item -Path $fullPath -Force -Recurse -ErrorAction Stop
                        Write-Host "已删除 - $fullPath"
                    }
                    catch {
                        Write-Host -back 'DarkRed' -fore 'white' "失败 - $fullPath"
                    }
                }
                else {
                    Write-Host "已删除 - $fullPath"
                }
            }
        }
    }
}
:regscan:

::========================================================================================================================================

:kill_idm

::  taskkill /f /im 会对每个同名进程各输出一行：能终止的打印“成功: 已终止进程”到
::  stdout，无权限的（其它用户会话 / 更高完整性级别的实例）打印“拒绝访问。”到 stderr。
::  两行以前都直接漏到界面上，而关闭 IDM 失败并不影响激活结果，用户却会把
::  这句“拒绝访问。”当成激活失败。这里统一收口：输出全部进日志，
::  界面不再出现裸的系统报错。固定返回 0，避免 taskkill 的退出码污染调用方。

taskkill /f /im idman.exe %nul%
if "%errorlevel%"=="0" (
call :log "已关闭正在运行的 IDMan.exe"
) else (
call :log "关闭 IDMan.exe 未完全成功（taskkill 退出码 %errorlevel%，常见于多实例或跨会话），不影响后续流程"
)
exit /b 0

:flush_input

::  pause 会立刻消费键盘缓冲区里已有的按键。激活流程包含下载和等待，用户
::  中途随手敲的键会一直留在缓冲区，等流程跑完执行到 pause 时被立刻吃掉，
::  表现就是“没按任何键却自己跳回去了”。这里在提示前先清空缓冲区。
::  choice 分支只接受指定按键，不受该问题影响，所以只在 pause 路径调用。
::  stdin 被重定向时（管道调用 / CI）RawUI 会报错，try-catch 吃掉即可。

%psc% "try{$Host.UI.RawUI.FlushInputBuffer()}catch{}" %nul%
exit /b 0

:set_exit
if "%~1"=="" exit /b
if "%exit_code%"=="0" set "exit_code=%~1"
if not "%~2"=="" call :log %~2
exit /b

:extract_logpath

::  从完整参数串里取出 /log= 后面的路径。
::  第一个 for 按 = 切，token 2 是第一个 = 之后的全部内容（"C:\x.log /silent"）；
::  第二个 for 按空格切，token 1 就是路径本身。
::  参数解析前已经用 %_args:"=% 去掉了所有引号，所以路径不能含空格。
::  取到的东西若以 / 开头，说明用户写的是 "/log= /silent" 这类空路径，忽略掉。

for /f "tokens=2 delims==" %%a in ("%_args%") do for /f "tokens=1" %%b in ("%%a") do set "_logpath=%%b"
if not defined _logpath exit /b
if "%_logpath:~0,1%"=="/" set "_logpath="
if defined _logpath set _log=1
exit /b

:init_log

::  必须放在子程序里逐行执行：若写在 if(...) 代码块内，%_logstamp% 会在
::  整块解析时一次性展开，取不到上一行刚写入的值，日志文件名会退化成
::  字面量 IAS-%_logstamp%.log，所有静默运行都追加到同一个文件。

if not defined _logpath goto :init_log_default
call :init_logpath
if defined log_file exit /b
echo [警告] 日志路径 %_logpath% 不可写，改用默认位置。

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

::  先建父目录再试写一次；写不进去就返回空 log_file，由调用方回退默认路径。

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
