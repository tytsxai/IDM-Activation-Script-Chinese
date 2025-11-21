@echo off
chcp 936 >nul 2>&1
setlocal EnableExtensions

set "IAS=%~dp0IAS.cmd"
if not exist "%IAS%" (
    echo [错误] 未找到 IAS.cmd，请确保本文件与 IAS.cmd 位于同一文件夹。
    pause
    exit /b 1
)

fltmc >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [提示] 正在尝试以管理员身份重新运行此脚本...
    where powershell.exe >nul 2>&1 || (
        echo [×] 未找到 PowerShell，无法自动请求管理员权限；请右键以管理员身份运行本文件。
        pause
        exit /b 1
    )
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo [信息] 正在调用 IAS.cmd /frz（冻结激活模式）...
call "%IAS%" /frz %*
set "ret=%errorlevel%"
if not "%ret%"=="0" (
    echo [提示] IAS.cmd 返回代码 %ret%，可查看屏幕输出或先运行“测试脚本.cmd”排查环境。
)
endlocal & exit /b %ret%
