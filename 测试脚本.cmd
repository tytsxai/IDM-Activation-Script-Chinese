@echo off
chcp 936 >nul 2>&1
setlocal EnableExtensions EnableDelayedExpansion

set "ERR_ADMIN=1"
set "ERR_PS_MISSING=2"
set "ERR_PS_MODE=4"
set "ERR_NULL_SERVICE=8"
set "ERR_NETWORK=16"
set "ERR_CODEPAGE=32"
set "ERR_IAS=64"
set "ERR_WMI=128"
set "ERR_IDM_PATH=256"
set "ERR_DIR_PERM=512"

set /a "issues=0"
set "firstFail="
echo ==========================================
echo IDM 激活环境检测
echo ==========================================
echo:

fltmc >nul 2>&1 && (
    echo [√] 已获取管理员权限
) || (
    echo [×] 当前未以管理员身份运行
    set /a issues^|=ERR_ADMIN
    if not defined firstFail set "firstFail=管理员权限未获取 ^| 右键脚本 → 以管理员身份运行（参见 README 常见问题 Q1）"
)

where powershell.exe >nul 2>&1 && (
    echo [√] PowerShell 可用
    for /f "delims=" %%a in ('powershell -NoProfile -Command "$ExecutionContext.SessionState.LanguageMode" 2^>nul') do set "psmode=%%a"
    if defined psmode (
        if /i "!psmode!"=="FullLanguage" (
            echo [√] PowerShell 语言模式: !psmode!
        ) else (
            echo [×] PowerShell 语言模式为 !psmode! ^(可能被组织策略限制^)
            set /a issues^|=ERR_PS_MODE
            if not defined firstFail set "firstFail=PowerShell 语言模式受限 ^| 组织策略限制（参见 README 常见问题 Q6）"
        )
    ) else (
        echo [×] 无法读取 PowerShell 语言模式（可能被禁用）
        set /a issues^|=ERR_PS_MODE
        if not defined firstFail set "firstFail=无法读取 PowerShell 语言模式 ^| PowerShell 可能被禁用（参见 README 常见问题 Q6）"
    )
) || (
    echo [×] 系统未找到 PowerShell
    set /a issues^|=ERR_PS_MISSING
    if not defined firstFail set "firstFail=系统未找到 PowerShell ^| 系统组件缺失（参见 README 常见问题 Q6）"
)

sc query Null | find /i "RUNNING" >nul 2>&1 && (
    echo [√] Null 服务运行正常
) || (
    echo [×] Null 服务未运行，批处理脚本可能异常
    set /a issues^|=ERR_NULL_SERVICE
    if not defined firstFail set "firstFail=Null 服务未运行 ^| 管理员 CMD 下执行 sc start Null 后重试"
)

set "netok="
ping -4 -n 1 internetdownloadmanager.com >nul 2>&1 && set "netok=ping"
if not defined netok if defined psmode (
    for /f "delims=" %%a in ('powershell -NoProfile -Command "$c=New-Object Net.Sockets.TcpClient;try{$c.Connect("internetdownloadmanager.com",80)}catch{};$c.Connected" 2^>nul') do set "netok=%%a"
)
if /i "!netok!"=="True" (
    echo [√] 可以访问 internetdownloadmanager.com
) else if /i "!netok!"=="ping" (
    echo [√] 端口 80 连通（PING 失败可忽略）
) else (
    echo [×] 无法连接到 internetdownloadmanager.com
    set /a issues^|=ERR_NETWORK
    if not defined firstFail set "firstFail=无法连接 internetdownloadmanager.com ^| 检查网络/代理/VPN（参见 README 常见问题 Q5）"
)

for /f "tokens=2 delims=:." %%a in ('chcp') do set "cp=%%a"
if "!cp!"=="936" (
    echo [√] 当前代码页: !cp! （简体中文）
) else (
    echo [×] 当前代码页: !cp! （建议运行 chcp 936）
    set /a issues^|=ERR_CODEPAGE
    if not defined firstFail set "firstFail=代码页非 936 ^| 运行 chcp 936 后重试（参见 README 常见问题 Q4）"
)

if exist "%~dp0IAS.cmd" (
    echo [√] 已检测到 IAS.cmd
) else (
    echo [×] 未检测到 IAS.cmd，请确认文件在同一目录
    set /a issues^|=ERR_IAS
    if not defined firstFail set "firstFail=未检测到 IAS.cmd ^| 把本脚本和 IAS.cmd 放同一目录后重试"
)

set "wmiok="
wmic path Win32_OperatingSystem get Caption /value >nul 2>&1 && set "wmiok=ok"
if not defined wmiok if defined psmode (
    for /f "delims=" %%a in ('powershell -NoProfile -Command "Try{Get-CimInstance Win32_OperatingSystem ^| Out-Null;$true}catch{$false}" 2^>nul') do if /i "%%a"=="True" set "wmiok=ok"
)
if defined wmiok (
    echo [√] WMI 可用
) else (
    echo [×] WMI 不可用，无法读取系统信息
    set /a issues^|=ERR_WMI
    if not defined firstFail set "firstFail=WMI 不可用 ^| 检查 Windows Management Instrumentation 服务是否启用"
)

set "idmPath="
for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SOFTWARE\Internet Download Manager" /v InstallFolder 2^>nul') do set "idmPath=%%a %%b"
if not defined idmPath (
    for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Internet Download Manager" /v InstallFolder 2^>nul') do set "idmPath=%%a %%b"
)
if defined idmPath (
    if exist "!idmPath!\IDMan.exe" (
        echo [√] 已检测到 IDM 安装路径: !idmPath!
    ) else (
        echo [×] 注册表中的 IDM 路径无效: !idmPath!
        set /a issues^|=ERR_IDM_PATH
        if not defined firstFail set "firstFail=IDM 路径无效 ^| 重新安装 IDM（参见 README 常见问题 Q2）"
    )
) else (
    echo [×] 未在注册表找到 IDM 安装路径
    set /a issues^|=ERR_IDM_PATH
    if not defined firstFail set "firstFail=未安装 IDM ^| 请先安装 IDM（参见 README 常见问题 Q2）"
)

set "writeTest=%~dp0.__ias_write_test.tmp"
> "!writeTest!" echo test >nul 2>&1
if exist "!writeTest!" (
    del /f /q "!writeTest!" >nul 2>&1
    echo [√] 脚本目录可写: %~dp0
) else (
    echo [×] 脚本目录不可写: %~dp0 （请移出受限目录）
    set /a issues^|=ERR_DIR_PERM
    if not defined firstFail set "firstFail=脚本目录不可写 ^| 请移出 Program Files 等受限目录后重试"
)

echo:
echo ------------------------------------------
if !issues! EQU 0 (
    echo [完成] 环境检测通过，可直接运行"快速激活.cmd"、"普通激活.cmd"或"重置激活.cmd"。
    echo:
    pause
    endlocal ^& exit /b 0
) else (
    echo [首个未通过项] !firstFail!
    echo:
    echo [提示] 以上项目标记为 × 时请先修复后再运行激活脚本。（合计退出码: !issues!）
    echo        详细排查建议请查阅 README.md 的"常见问题"章节。
    echo:
    pause
    endlocal ^& exit /b !issues!
)
