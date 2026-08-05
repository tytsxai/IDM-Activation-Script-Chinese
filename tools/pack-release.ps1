$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

<#
.SYNOPSIS
在 Windows 上重新生成 release/IDM-Activation-Script.zip 与对应的 .sha256。

.DESCRIPTION
以前发版靠手工压缩，结果是「改了仓库、忘了重新打包」没有任何征兆——用户下载
到的还是旧脚本。这个脚本把打包变成一条可重复的命令：文件清单固定、条目名编码
固定、sha256 自动重算，跑完再跑 tools/verify-release.ps1 就能确认包与仓库一致。

关于文件名编码：现有发布包里的中文文件名是按 GBK（代码页 936）存的，且没有置
UTF-8 标志位。.NET 的 ZipArchive 在显式传入非 UTF-8 的 entryNameEncoding 时，
正好就是这个行为，所以这里显式传 936 来保持与历史发布包一致的约定。**不要**改用
Compress-Archive 或在 macOS / Linux 上打包，那会写成 UTF-8 + 标志位，破坏约定。

.EXAMPLE
pwsh -NoProfile -File tools/pack-release.ps1
pwsh -NoProfile -File tools/verify-release.ps1
#>

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$zipPath = Join-Path $repoRoot 'release/IDM-Activation-Script.zip'
$shaPath = Join-Path $repoRoot 'release/IDM-Activation-Script.zip.sha256'

# 发布包内容清单。顺序即包内顺序；改动这里等于改动对外发布的文件集合，
# 请同步更新 README「文件说明」与 tools/verify-release.ps1 的 runtimeFiles。
$payload = @(
    '开始激活.cmd',
    'IAS.cmd',
    '使用说明.txt',
    'README.md',
    'CHANGELOG.md',
    'SECURITY.md',
    'LICENSE'
)

[System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

foreach ($name in $payload) {
    $source = Join-Path $repoRoot $name
    if (-not (Test-Path -LiteralPath $source)) {
        throw "发布包清单里的 $name 在仓库中不存在。"
    }
}

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

$gbk = [System.Text.Encoding]::GetEncoding(936)
$archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create, $gbk)

try {
    foreach ($name in $payload) {
        $source = Join-Path $repoRoot $name
        # CreateEntryFromFile 会原样复制字节，不做任何换行/编码转换——
        # IAS.cmd 的 CRLF 与 GBK 编码必须原封不动地进包。
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive, $source, $name, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
        Write-Host "已打包: $name"
    }
}
finally {
    $archive.Dispose()
}

$sha = [System.Security.Cryptography.SHA256]::Create()
try {
    $hash = ([BitConverter]::ToString($sha.ComputeHash([System.IO.File]::ReadAllBytes($zipPath))) -replace '-', '').ToLowerInvariant()
}
finally {
    $sha.Dispose()
}

# 与历史文件保持同样的格式：<哈希><两个空格><相对路径>，LF 结尾、无 BOM。
$shaContent = "$hash  release/IDM-Activation-Script.zip`n"
[System.IO.File]::WriteAllText($shaPath, $shaContent, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host "发布包已重新生成: $zipPath"
Write-Host "SHA256: $hash"
Write-Host ''
Write-Host '下一步：运行 pwsh -NoProfile -File tools/verify-release.ps1 确认包与仓库一致。'
