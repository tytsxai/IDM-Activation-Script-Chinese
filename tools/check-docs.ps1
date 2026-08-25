$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

<#
.SYNOPSIS
校验文档与脚本是否同步。

.DESCRIPTION
本仓库的文档里直接写着命令行参数、退出码、菜单编号、内部标签和版本号。脚本一改、
文档不改，用户就会照着一份不存在的说明操作——历史上真实发生过「文档教用户选的选项，
菜单里根本没有」。

这个脚本把「能机械验证的事实」从脚本里提取出来，和文档比对。它不判断文字是否通顺，
只守住六件事：

  1. 脚本接受的每一个命令行参数，文档里都有记录；
  2. 脚本用到的每一个退出码，docs/reference/cli.md 的退出码表里都有一行；
  3. 主菜单的编号集合与 choice /C 字符串一致，README 的菜单示意框也列出同一套编号；
  4. IAS.cmd 的每个标签在 docs/reference/internals.md 里有条目，反过来也不多记；
  5. iasver / idmsupport 与 README、llms.txt、llms-full.txt 里写的版本一致；
  6. 所有 Markdown 里的仓库内相对链接都指向真实存在的文件。

同步规则的完整说明见 docs/doc-sync.md。

本脚本不依赖 cmd.exe、注册表或 Windows 专有组件，在 macOS / Linux 的 PowerShell 里也能跑。

.EXAMPLE
pwsh -NoProfile -File tools/check-docs.ps1
#>

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# IAS.cmd 是无 BOM 的 GBK，必须显式按 936 解码，否则中文全是替换字符
[System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)

$script:Failures = @()

function Add-Failure {
    param(
        [string]$Message,
        [string]$File = ''
    )

    $script:Failures += [PSCustomObject]@{
        Message = $Message
        File    = $File
    }
}

function Emit-Failures {
    foreach ($failure in $script:Failures) {
        if ($failure.File) {
            Write-Host "::error file=$($failure.File)::$($failure.Message)"
        }
        else {
            Write-Host "::error::$($failure.Message)"
        }
    }

    throw "文档与脚本不同步。修复方式见 docs/doc-sync.md。"
}

function Read-RepoText {
    param(
        [string]$RelativePath,
        [int]$CodePage = 0
    )

    $full = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $full)) {
        Add-Failure -File $RelativePath -Message "check-docs.ps1 需要这个文件，但它不存在。"
        return ''
    }

    $bytes = [System.IO.File]::ReadAllBytes($full)
    if ($CodePage -gt 0) {
        return [System.Text.Encoding]::GetEncoding($CodePage).GetString($bytes)
    }

    return (New-Object System.Text.UTF8Encoding($false)).GetString($bytes)
}

function Get-Captures {
    param(
        [string]$Text,
        [string]$Pattern
    )

    $values = @()
    foreach ($match in [regex]::Matches($Text, $Pattern)) {
        $values += $match.Groups[1].Value
    }

    return @($values | Sort-Object -Unique)
}

# ---------------------------------------------------------------------------
# 读入被比对的文件
# ---------------------------------------------------------------------------

$ias       = Read-RepoText -RelativePath 'IAS.cmd' -CodePage 936
$readme    = Read-RepoText -RelativePath 'README.md'
$cli       = Read-RepoText -RelativePath 'docs/reference/cli.md'
$internals = Read-RepoText -RelativePath 'docs/reference/internals.md'
$llms      = Read-RepoText -RelativePath 'llms.txt'
$llmsFull  = Read-RepoText -RelativePath 'llms-full.txt'

if ($script:Failures) {
    Emit-Failures
}

# ---------------------------------------------------------------------------
# 1. 命令行参数
# ---------------------------------------------------------------------------
#
# 参数解析写成一串 `if /i "%%A"=="/xxx"`（架构重入与 QuickEdit 用的是 %%#）。
# 从这些字面量里提取脚本真正接受的参数集合。

$flags = Get-Captures -Text $ias -Pattern 'if /i "%%[A-Za-z#]"=="([^"]+)"'

if ($flags.Count -eq 0) {
    Add-Failure -File 'IAS.cmd' -Message "没能从 IAS.cmd 里解析出任何命令行参数。参数解析的写法变了吗？请同步更新 tools/check-docs.ps1。"
}

# 面向用户的文档：只要求覆盖 / 开头的参数。-el / -qedit / r1 / r2 是脚本重入时
# 自己附加的内部标记，不属于对外契约，只需要在 cli.md 里说明。
$userFacingDocs = @(
    @{ Path = 'README.md';    Text = $readme },
    @{ Path = 'llms.txt';     Text = $llms },
    @{ Path = 'llms-full.txt'; Text = $llmsFull }
)

foreach ($flag in $flags) {
    if (-not $cli.Contains('`' + $flag + '`')) {
        Add-Failure -File 'docs/reference/cli.md' -Message "IAS.cmd 接受参数 $flag，但 docs/reference/cli.md 里没有 ``$flag`` 这一项。"
    }

    if (-not $flag.StartsWith('/')) {
        continue
    }

    foreach ($doc in $userFacingDocs) {
        if (-not $doc.Text.Contains($flag)) {
            Add-Failure -File $doc.Path -Message "IAS.cmd 接受参数 $flag，但 $($doc.Path) 里没有提到它。"
        }
    }
}

# ---------------------------------------------------------------------------
# 2. 退出码
# ---------------------------------------------------------------------------

$exitCodes = Get-Captures -Text $ias -Pattern 'call :set_exit\s+(\d+)'
# 0 不需要显式设置（默认值），但同样必须在退出码表里有说明
$exitCodes = @(@($exitCodes) + @('0') | Sort-Object -Unique)

foreach ($code in $exitCodes) {
    $rowPattern = '(?m)^\| `' + $code + '` \|'
    if ([regex]::Matches($cli, $rowPattern).Count -eq 0) {
        Add-Failure -File 'docs/reference/cli.md' -Message "IAS.cmd 会返回退出码 $code，但 docs/reference/cli.md 的退出码表里没有对应行（期望形如 '| ``$code`` | ... |'）。"
    }
}

# ---------------------------------------------------------------------------
# 3. 主菜单编号
# ---------------------------------------------------------------------------
#
# 菜单里的 [N] 与 choice /C 字符串必须一一对应：choice 返回的是按键在 /C 里的位置，
# 改了其中一个而没改另一个，整张菜单就会错位。

$menuStart = $ias.IndexOf(':MainMenu')
$choiceIndex = -1
if ($menuStart -ge 0) {
    $choiceIndex = $ias.IndexOf('choice /C:', $menuStart)
}

if ($menuStart -lt 0 -or $choiceIndex -lt 0) {
    Add-Failure -File 'IAS.cmd' -Message "没能在 IAS.cmd 里定位 :MainMenu 与其后的 choice /C: 语句。菜单结构变了吗？请同步更新 tools/check-docs.ps1。"
}
else {
    $menuBlock = $ias.Substring($menuStart, $choiceIndex - $menuStart)
    $menuNumbers = Get-Captures -Text $menuBlock -Pattern '\[(\d)\]'

    $choiceMatch = [regex]::Match($ias.Substring($choiceIndex), '^choice /C:(\d+)')
    $choiceNumbers = @()
    if ($choiceMatch.Success) {
        foreach ($ch in $choiceMatch.Groups[1].Value.ToCharArray()) {
            $choiceNumbers += [string]$ch
        }
        $choiceNumbers = @($choiceNumbers | Sort-Object -Unique)
    }

    if ($choiceNumbers.Count -eq 0) {
        Add-Failure -File 'IAS.cmd' -Message "没能解析 choice /C: 后面的按键字符串。"
    }
    elseif (($menuNumbers -join ',') -ne ($choiceNumbers -join ',')) {
        Add-Failure -File 'IAS.cmd' -Message "主菜单列出的编号 [$($menuNumbers -join ' ')] 与 choice /C 接受的按键 [$($choiceNumbers -join ' ')] 不一致。choice 返回的是按键在 /C 里的位置，两者必须同步。"
    }

    foreach ($number in $menuNumbers) {
        if (-not $readme.Contains('[' + $number + ']')) {
            Add-Failure -File 'README.md' -Message "主菜单有 [$number] 这一项，但 README.md 里没有提到它。"
        }
    }
}

# ---------------------------------------------------------------------------
# 4. 内部标签
# ---------------------------------------------------------------------------

$labels = Get-Captures -Text $ias -Pattern '(?m)^:([A-Za-z_][A-Za-z0-9_]*)'

if ($labels.Count -eq 0) {
    Add-Failure -File 'IAS.cmd' -Message "没能从 IAS.cmd 里解析出任何标签。"
}

foreach ($label in $labels) {
    if (-not $internals.Contains('`:' + $label + '`')) {
        Add-Failure -File 'docs/reference/internals.md' -Message "IAS.cmd 里有标签 :$label，但 docs/reference/internals.md 里没有 ``:$label`` 的条目。"
    }
}

$documentedLabels = Get-Captures -Text $internals -Pattern '`:([A-Za-z_][A-Za-z0-9_]*)`'
foreach ($documented in $documentedLabels) {
    if ($labels -notcontains $documented) {
        Add-Failure -File 'docs/reference/internals.md' -Message "docs/reference/internals.md 记录了标签 :$documented，但 IAS.cmd 里没有这个标签。"
    }
}

# ---------------------------------------------------------------------------
# 5. 版本号
# ---------------------------------------------------------------------------
#
# iasver 与 CHANGELOG 顶部的一致性由 tools/verify-release.ps1 负责，这里只管文档一侧。

$iasverMatch = [regex]::Match($ias, '(?m)^@set iasver=(.+)$')
$idmsupportMatch = [regex]::Match($ias, '(?m)^@set idmsupport=(.+)$')

if (-not $iasverMatch.Success) {
    Add-Failure -File 'IAS.cmd' -Message "没能解析 IAS.cmd 头部的 iasver。"
}
if (-not $idmsupportMatch.Success) {
    Add-Failure -File 'IAS.cmd' -Message "没能解析 IAS.cmd 头部的 idmsupport。"
}

if ($iasverMatch.Success -and $idmsupportMatch.Success) {
    $iasver = $iasverMatch.Groups[1].Value.Trim()
    $idmsupport = $idmsupportMatch.Groups[1].Value.Trim()

    $versionExpectations = @(
        @{ Path = 'README.md';     Text = $readme;   Needle = 'badge/version-' + $iasver + '-'; What = "版本徽章" },
        @{ Path = 'README.md';     Text = $readme;   Needle = '脚本 ' + $iasver;                What = "菜单示意框里的脚本版本" },
        @{ Path = 'README.md';     Text = $readme;   Needle = '已适配 IDM ' + $idmsupport;      What = "菜单示意框里的已适配 IDM 版本" },
        @{ Path = 'llms.txt';      Text = $llms;     Needle = '脚本版本 / Script version: ' + $iasver; What = "脚本版本" },
        @{ Path = 'llms-full.txt'; Text = $llmsFull; Needle = '当前版本 / Version: ' + $iasver; What = "当前版本" }
    )

    foreach ($expectation in $versionExpectations) {
        if (-not $expectation.Text.Contains($expectation.Needle)) {
            Add-Failure -File $expectation.Path -Message "$($expectation.Path) 的$($expectation.What)与 IAS.cmd 不一致，期望出现字符串 '$($expectation.Needle)'（iasver=$iasver, idmsupport=$idmsupport）。"
        }
    }
}

# ---------------------------------------------------------------------------
# 6. Markdown 站内链接
# ---------------------------------------------------------------------------

$separator = [System.IO.Path]::DirectorySeparatorChar
$gitDirFragment = "$separator.git$separator"

$markdownFiles = @(
    Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.md' -File |
        Where-Object { -not $_.FullName.Contains($gitDirFragment) }
)

foreach ($markdownFile in $markdownFiles) {
    $relativePath = $markdownFile.FullName.Substring($repoRoot.Length).TrimStart($separator).Replace([string]$separator, '/')
    $text = (New-Object System.Text.UTF8Encoding($false)).GetString([System.IO.File]::ReadAllBytes($markdownFile.FullName))

    foreach ($match in [regex]::Matches($text, '\]\(([^)\s]+)\)')) {
        $target = $match.Groups[1].Value

        if ($target.StartsWith('#') -or
            $target.StartsWith('http://') -or
            $target.StartsWith('https://') -or
            $target.StartsWith('mailto:')) {
            continue
        }

        $anchorIndex = $target.IndexOf('#')
        if ($anchorIndex -ge 0) {
            $target = $target.Substring(0, $anchorIndex)
        }
        if (-not $target) {
            continue
        }

        $target = [uri]::UnescapeDataString($target)
        $candidate = Join-Path $markdownFile.DirectoryName $target

        if (-not (Test-Path -LiteralPath $candidate)) {
            Add-Failure -File $relativePath -Message "链接指向的文件不存在: $($match.Groups[1].Value)"
        }
    }
}

# ---------------------------------------------------------------------------

if ($script:Failures) {
    Emit-Failures
}

Write-Host "文档与脚本同步校验通过：$($flags.Count) 个参数、$($exitCodes.Count) 个退出码、$($labels.Count) 个标签、$($markdownFiles.Count) 个 Markdown 文件。"
exit 0
