@echo off
chcp 936 >nul 2>&1
setlocal EnableExtensions

set "TARGET=%~dp0IAS.cmd"
if not exist "%TARGET%" (
    echo [错误] 未找到 IAS.cmd，请确保本文件与 IAS.cmd 位于同一文件夹。
    exit /b 1
)

call "%TARGET%" %*
set "ret=%errorlevel%"
endlocal & exit /b %ret%
