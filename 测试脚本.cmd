@echo off
chcp 936 >nul 2>&1
setlocal EnableExtensions EnableDelayedExpansion

set "issues=0"
echo ==========================================
echo IDM 激活环境检测
echo ==========================================
echo:

fltmc >nul 2>&1 && (
    echo [√] 已获取管理员权限
) || (
    echo [×] 当前未以管理员身份运行
    set "issues=1"
)

where powershell.exe >nul 2>&1 && (
    echo [√] PowerShell 可用
    for /f "delims=" %%a in ('powershell -NoProfile -Command "$ExecutionContext.SessionState.LanguageMode" 2^>nul') do set "psmode=%%a"
    if defined psmode (
        if /i "!psmode!"=="FullLanguage" (
            echo [√] PowerShell 语言模式: !psmode!
        ) else (
            echo [×] PowerShell 语言模式为 !psmode! （可能被组织策略限制）
            set "issues=1"
        )
    ) else (
        echo [×] 无法读取 PowerShell 语言模式（可能被禁用）
        set "issues=1"
    )
) || (
    echo [×] 系统未找到 PowerShell
    set "issues=1"
)

sc query Null | find /i "RUNNING" >nul 2>&1 && (
    echo [√] Null 服务运行正常
) || (
    echo [×] Null 服务未运行，批处理脚本可能异常
    set "issues=1"
)

set "netok="
ping -4 -n 1 internetdownloadmanager.com >nul 2>&1 && set "netok=ping"
if not defined netok if defined psmode (
    for /f "delims=" %%a in ('powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect(\"internetdownloadmanager.com\",80)}catch{};$c.Connected" 2^>nul') do set "netok=%%a"
)
if /i "!netok!"=="True" (
    echo [√] 可以访问 internetdownloadmanager.com
) else (
    if defined netok (
        echo [√] 端口 80 连通（PING 失败可忽略）
    ) else (
        echo [×] 无法连接到 internetdownloadmanager.com
        set "issues=1"
    )
)

for /f "tokens=2 delims=:." %%a in ('chcp') do set "cp=%%a"
if "!cp!"=="936" (
    echo [√] 当前代码页: !cp! （简体中文）
) else (
    echo [×] 当前代码页: !cp! （建议运行 chcp 936）
    set "issues=1"
)

if exist "%~dp0IAS.cmd" (
    echo [√] 已检测到 IAS.cmd
) else (
    echo [×] 未检测到 IAS.cmd，请确认文件在同一目录
    set "issues=1"
)

echo:
if !issues! EQU 0 (
    echo [完成] 环境检测通过，可直接运行“快速激活.cmd”或“IAS.cmd”。
    endlocal & exit /b 0
) else (
    echo [提示] 以上项目标记为 × 时请先修复后再运行激活脚本。
    pause
    endlocal & exit /b 1
)
