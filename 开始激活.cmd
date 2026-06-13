@echo off
chcp 936 >nul 2>&1
setlocal EnableExtensions EnableDelayedExpansion
title IDM 激活脚本 - 开始激活

set "IAS=%~dp0IAS.cmd"
set "self=%~f0"

::====================== 自动获取管理员权限 ======================
::  注意：提权用单引号包裹路径，避免安装目录含 (x86) 等特殊字符时报
::  "此时不应有 \Internet" 之类的语法错误。
fltmc >nul 2>&1
if %errorlevel% NEQ 0 goto :elevate
goto :checks

:elevate
echo [提示] 正在请求管理员权限，请在弹出的窗口中点击"是"...
where powershell.exe >nul 2>&1 || goto :noPS
powershell -NoProfile -Command "Start-Process -FilePath '%self%' -Verb RunAs"
exit /b

:noPS
echo [×] 未找到 PowerShell，无法自动提权。
echo     请右键本文件，选择"以管理员身份运行"。
pause
exit /b 1

:checks
if not exist "%IAS%" (
    echo [×] 未找到 IAS.cmd，请确认本文件与 IAS.cmd 在同一文件夹。
    echo     若从压缩包获取，请先"全部解压"再运行，不要在压缩包里直接双击。
    pause
    exit /b 1
)

::====================== 环境检测（激活前自检） ======================
set /a issues=0
set "firstFail="
cls
echo ==========================================
echo   IDM 激活 - 环境检测
echo ==========================================
echo:
echo [√] 已获取管理员权限
echo [√] 已找到 IAS.cmd

where powershell.exe >nul 2>&1 && (
    echo [√] PowerShell 可用
    for /f "delims=" %%a in ('powershell -NoProfile -Command "$ExecutionContext.SessionState.LanguageMode" 2^>nul') do set "psmode=%%a"
    if defined psmode if /i not "!psmode!"=="FullLanguage" (
        echo [×] PowerShell 语言模式为 !psmode! （可能被组织策略限制）
        set /a issues+=1
        if not defined firstFail set "firstFail=PowerShell 语言模式受限，参见 README 常见问题 Q6"
    )
) || (
    echo [×] 系统未找到 PowerShell
    set /a issues+=1
    if not defined firstFail set "firstFail=系统未找到 PowerShell，参见 README 常见问题 Q6"
)

sc query Null | find /i "RUNNING" >nul 2>&1 && (
    echo [√] Null 服务正在运行
) || (
    echo [×] Null 服务未运行（可能导致脚本运行异常）
    set /a issues+=1
    if not defined firstFail set "firstFail=Null 服务未运行，可在管理员 CMD 执行 sc start Null 后重试"
)

set "netok="
ping -4 -n 1 internetdownloadmanager.com >nul 2>&1 && set "netok=ping"
if not defined netok (
    for /f "delims=" %%a in ('powershell -NoProfile -Command "(Test-NetConnection internetdownloadmanager.com -Port 80 -WarningAction SilentlyContinue).TcpTestSucceeded" 2^>nul') do set "netok=%%a"
)
if /i "!netok!"=="True" (
    echo [√] 可连接 internetdownloadmanager.com
) else if /i "!netok!"=="ping" (
    echo [√] 网络可达 internetdownloadmanager.com
) else (
    echo [×] 无法连接 internetdownloadmanager.com（检查网络/代理/VPN；不影响本地激活）
    set /a issues+=1
    if not defined firstFail set "firstFail=无法连接 internetdownloadmanager.com，参见 README 常见问题 Q5"
)

chcp 936 >nul 2>&1
set "cpok="
chcp | find "936" >nul 2>&1 && set "cpok=ok"
if defined cpok (
    echo [√] 代码页 936 已生效（简体中文）
) else (
    echo [×] 代码页非 936（可执行 chcp 936 后重试）
    set /a issues+=1
    if not defined firstFail set "firstFail=代码页非 936，可执行 chcp 936 后重试，参见 README 常见问题 Q4"
)

set "wmiok="
for /f "delims=" %%a in ('powershell -NoProfile -Command "try{$null=Get-CimInstance Win32_OperatingSystem -ErrorAction Stop;Write-Output 1}catch{Write-Output 0}" 2^>nul') do if "%%a"=="1" set "wmiok=ok"
if not defined wmiok wmic path Win32_OperatingSystem get Caption /value >nul 2>&1 && set "wmiok=ok"
if defined wmiok (
    echo [√] WMI/CIM 可用
) else (
    echo [×] WMI/CIM 不可用（部分系统信息读取受限；通常不影响激活）
    set /a issues+=1
    if not defined firstFail set "firstFail=WMI/CIM 不可用，请检查 Windows Management Instrumentation 服务是否启用"
)

set "idmPath="
for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SOFTWARE\Internet Download Manager" /v InstallFolder 2^>nul') do set "idmPath=%%a %%b"
if not defined idmPath (
    for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Internet Download Manager" /v InstallFolder 2^>nul') do set "idmPath=%%a %%b"
)
if not defined idmPath (
    set "IDManPath="
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\DownloadManager" /v ExePath 2^>nul') do set "IDManPath=%%b"
    if defined IDManPath if exist "!IDManPath!" (
        for %%i in ("!IDManPath!") do set "idmPath=%%~dpi"
        if "!idmPath:~-1!"=="\" set "idmPath=!idmPath:~0,-1!"
    )
)
if not defined idmPath (
    if exist "%ProgramFiles(x86)%\Internet Download Manager\IDMan.exe" set "idmPath=%ProgramFiles(x86)%\Internet Download Manager"
    if not defined idmPath if exist "%ProgramFiles%\Internet Download Manager\IDMan.exe" set "idmPath=%ProgramFiles%\Internet Download Manager"
)
if defined idmPath (
    if exist "!idmPath!\IDMan.exe" (
        echo [√] 已检测到 IDM 安装路径: !idmPath!
    ) else (
        echo [×] 注册表中的 IDM 路径无效: !idmPath!
        set /a issues+=1
        if not defined firstFail set "firstFail=IDM 路径无效，请重新安装 IDM，参见 README 常见问题 Q2"
    )
) else (
    echo [×] 未在注册表找到 IDM 安装路径
    set /a issues+=1
    if not defined firstFail set "firstFail=未安装 IDM，请先安装 IDM，参见 README 常见问题 Q2"
)

set "writeTest=%~dp0.__ias_write_test.tmp"
(echo test)> "!writeTest!" 2>nul
if exist "!writeTest!" (
    del /f /q "!writeTest!" >nul 2>&1
    echo [√] 脚本目录可写
) else (
    echo [×] 脚本目录不可写（请移出受限目录，如 Program Files）
    set /a issues+=1
    if not defined firstFail set "firstFail=脚本目录不可写，请移出 Program Files 等受限目录后重试"
)

echo:
echo ------------------------------------------
if !issues! GTR 0 (
    echo [注意] 检测到 !issues! 个可能影响激活的问题，首个为：
    echo        !firstFail!
    echo        详细排查请查阅 README.md 的"常见问题"章节。
    echo:
    choice /C YN /N /M "仍要继续进入激活菜单吗？  [Y]继续  [N]退出 "
    if errorlevel 2 goto :abort
    echo:
) else (
    echo [完成] 环境检测全部通过，即将进入激活菜单...
    echo:
)

::====================== 进入 IAS 激活菜单 ======================
::  无参数 = 弹出菜单（[1]冻结激活  [2]激活  [3]重置）
::  高级用户也可加 /act /frz /res 参数直接执行
call "%IAS%" %*
set "ret=%errorlevel%"
endlocal & exit /b %ret%

:abort
echo 已取消。
endlocal & exit /b 1
