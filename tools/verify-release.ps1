$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

<#
.SYNOPSIS
校验 release/ 发布包与仓库工作树是否一致，以及版本号是否自洽。

.DESCRIPTION
发布包用的是固定文件名 `IDM-Activation-Script.zip`，README 里的
下载链接永远指向它。好处是链接不用改，代价是「只改了仓库、忘了
重新打包」不会有任何征兆 —— 用户下载到的仍然是旧脚本，而 CI 一路绿灯。

本脚本在 CI 里守住四件事：

  1. `.sha256` 记录的哈希与 zip 实际哈希一致（否则 README 里教用户做的校验是假的）；
  2. 包内**会被执行**的文件与仓库根目录逐字节一致 —— 不一致直接失败；
  3. 包内文档类文件与仓库不一致时只发警告 —— 文档旧一点不影响运行，
     若也设成硬失败，任何一次文档改动都会卡住 CI 直到重新打包；
  4. `IAS.cmd` 的 `iasver` 与 `CHANGELOG.md` 顶部版本号一致（历史上出现过
     发完版才补「版本号 x.y.z -> x.y.z+1」的提交）。

zip 里的中文文件名是按 GBK 存的、没有 UTF-8 标志位，所以必须显式用代码页 936
打开条目名，否则会取到乱码文件名、误判成「包内多了文件」。
#>

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$zipPath = Join-Path $repoRoot 'release/IDM-Activation-Script.zip'
$shaPath = Join-Path $repoRoot 'release/IDM-Activation-Script.zip.sha256'

# 这些文件在用户机器上会被真的执行 / 打开，包内版本必须等于仓库版本
$runtimeFiles = @('IAS.cmd', '开始激活.cmd', '使用说明.txt')

[System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)

$script:Failures = @()
$script:Warnings = @()

function Add-Failure {
    param([string]$Message)
    $script:Failures += $Message
}

function Add-Warning {
    param([string]$Message)
    $script:Warnings += $Message
}

function Get-Sha256 {
    param([byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($Bytes)) -replace '-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

if (-not (Test-Path -LiteralPath $zipPath)) {
    Write-Host "::error::找不到发布包 release/IDM-Activation-Script.zip"
    exit 1
}
if (-not (Test-Path -LiteralPath $shaPath)) {
    Write-Host "::error::找不到校验值文件 release/IDM-Activation-Script.zip.sha256"
    exit 1
}

# ---- 1. sha256 ----------------------------------------------------------

$actualHash = Get-Sha256 ([System.IO.File]::ReadAllBytes($zipPath))
$shaLine = (Get-Content -LiteralPath $shaPath -Raw).Trim()
$recordedHash = ($shaLine -split '\s+')[0].ToLowerInvariant()

if ($recordedHash -ne $actualHash) {
    Add-Failure ".sha256 与发布包实际哈希不一致：记录 $recordedHash，实际 $actualHash。重新打包后请同时更新 .sha256。"
}
else {
    Write-Host "SHA256 校验通过：$actualHash"
}

# ---- 2/3. 包内文件与仓库比对 --------------------------------------------

Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
$gbk = [System.Text.Encoding]::GetEncoding(936)
$archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Read, $gbk)

try {
    $entryNames = @()

    foreach ($entry in $archive.Entries) {
        if (-not $entry.Name) { continue }   # 目录条目
        $entryNames += $entry.FullName

        $repoFile = Join-Path $repoRoot $entry.FullName
        if (-not (Test-Path -LiteralPath $repoFile)) {
            Add-Failure "发布包里的 $($entry.FullName) 在仓库中不存在；发布包不应包含仓库外的文件。"
            continue
        }

        $stream = $entry.Open()
        try {
            $buffer = New-Object System.IO.MemoryStream
            $stream.CopyTo($buffer)
            $zipHash = Get-Sha256 $buffer.ToArray()
        }
        finally {
            $stream.Dispose()
        }

        $repoHash = Get-Sha256 ([System.IO.File]::ReadAllBytes($repoFile))

        if ($zipHash -eq $repoHash) { continue }

        if ($runtimeFiles -contains $entry.FullName) {
            Add-Failure "发布包里的 $($entry.FullName) 与仓库版本不一致。这是会被执行的文件，用户下载到的将是旧脚本 —— 请在 Windows 上重新打包并更新 .sha256。"
        }
        else {
            Add-Warning "发布包里的 $($entry.FullName) 与仓库版本不一致（文档类文件，不阻断）。发版前请重新打包。"
        }
    }

    foreach ($required in $runtimeFiles) {
        if ($entryNames -notcontains $required) {
            Add-Failure "发布包缺少运行时必需文件 $required。"
        }
    }
}
finally {
    $archive.Dispose()
}

# ---- 4. 版本号自洽 ------------------------------------------------------

$iasLine = Select-String -LiteralPath (Join-Path $repoRoot 'IAS.cmd') -Pattern '^@set iasver=(.+)$' -Encoding ascii | Select-Object -First 1
if (-not $iasLine) {
    Add-Failure "无法在 IAS.cmd 中解析 iasver。"
}
else {
    $iasver = $iasLine.Matches[0].Groups[1].Value.Trim()
    $changelogTop = Select-String -LiteralPath (Join-Path $repoRoot 'CHANGELOG.md') -Pattern '^##\s+v(\d+\.\d+(\.\d+)?)' | Select-Object -First 1

    if (-not $changelogTop) {
        Add-Failure "无法在 CHANGELOG.md 中找到形如 '## vX.Y.Z — 日期' 的版本标题。"
    }
    elseif ($changelogTop.Matches[0].Groups[1].Value -ne $iasver) {
        Add-Failure "版本号不一致：IAS.cmd 的 iasver=$iasver，CHANGELOG.md 顶部是 v$($changelogTop.Matches[0].Groups[1].Value)。发版时两处必须同步。"
    }
    else {
        Write-Host "版本号自洽：iasver=$iasver 与 CHANGELOG 顶部一致。"
    }
}

# ---- 汇总 ---------------------------------------------------------------

foreach ($warning in $script:Warnings) {
    Write-Host "::warning::$warning"
}

if ($script:Failures) {
    foreach ($failure in $script:Failures) {
        Write-Host "::error::$failure"
    }
    throw "发布包校验失败。"
}

Write-Host '发布包校验通过。'
exit 0
