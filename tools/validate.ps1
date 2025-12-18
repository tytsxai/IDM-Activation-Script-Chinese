$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

<#
.SYNOPSIS
Validates repository text hygiene (EOL + encoding) on Windows runners.

.DESCRIPTION
This script is intended to run in CI (GitHub Actions) and fail fast when:
  - A tracked file violates the expected line-ending declared by `.gitattributes`.
  - Any tracked `.cmd` / `.txt` file is not decodable as GBK (code page 936), or contains a BOM.
  - Basic `cmd.exe` invocation fails (sanity check for runner/tooling issues).

Notes:
  - Markdown is expected to be LF; batch/text helpers are expected to be CRLF.
  - The GBK requirement exists to keep Windows console output readable for Chinese text.
#>

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
# Ensure legacy code pages (e.g., 936/GBK) are available on .NET Core/PowerShell 7
[System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance)

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
    if (-not $script:Failures) {
        return
    }

    foreach ($failure in $script:Failures) {
        if ($failure.File) {
            Write-Host "::error file=$($failure.File)::$($failure.Message)"
        }
        else {
            Write-Host "::error::$($failure.Message)"
        }
    }

    throw "Validation failed."
}

function Get-EolExpectation {
    param(
        [string]$Path
    )

    $attr = git -C $repoRoot -c core.quotePath=false check-attr eol -- $Path 2>$null
    if (-not $attr) {
        return $null
    }

    if ($attr -match ':\s*eol:\s*(\S+)\s*$') {
        $value = $matches[1]
        if ($value -eq 'unspecified') {
            return $null
        }

        return $value
    }

    return $null
}

function Validate-LineEndings {
    param(
        [string]$Path,
        [string]$Expected
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if (-not $bytes.Length) {
        return
    }

    switch ($Expected.ToLower()) {
        'crlf' {
            for ($i = 0; $i -lt $bytes.Length; $i++) {
                if ($bytes[$i] -eq 0x0A) {
                    if ($i -eq 0 -or $bytes[$i - 1] -ne 0x0D) {
                        Add-Failure -File $Path -Message 'Expected CRLF line endings per .gitattributes but found LF.'
                        return
                    }
                }

                if ($bytes[$i] -eq 0x0D -and ($i -eq $bytes.Length - 1 -or $bytes[$i + 1] -ne 0x0A)) {
                    Add-Failure -File $Path -Message 'Found CR without following LF; normalize to CRLF per .gitattributes.'
                    return
                }
            }
        }
        'lf' {
            if ($bytes -contains 0x0D) {
                Add-Failure -File $Path -Message 'Expected LF line endings per .gitattributes but found CR characters.'
            }
        }
    }
}

function Validate-Encoding {
    param(
        [string]$Path
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)

    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Add-Failure -File $Path -Message 'Detected UTF-8 BOM. Save the file as GBK/ASCII without BOM.'
        return
    }

    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        Add-Failure -File $Path -Message 'Detected UTF-16 LE BOM. Save the file as GBK/ASCII.'
        return
    }

    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        Add-Failure -File $Path -Message 'Detected UTF-16 BE BOM. Save the file as GBK/ASCII.'
        return
    }

    $gbk = [System.Text.Encoding]::GetEncoding(936, [System.Text.EncoderFallback]::ExceptionFallback, [System.Text.DecoderFallback]::ExceptionFallback)
    try {
        $null = $gbk.GetString($bytes)
    }
    catch {
        Add-Failure -File $Path -Message 'Content is not valid GBK/ASCII. Convert the file to GBK (code page 936).'
        return
    }

    $hasNonAscii = $bytes | Where-Object { $_ -gt 0x7F } | ForEach-Object { $true } | Select-Object -First 1

    if ($hasNonAscii) {
        $utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
        $isUtf8 = $true

        try {
            $null = $utf8Strict.GetString($bytes)
        }
        catch {
            $isUtf8 = $false
        }

        if ($isUtf8) {
            Add-Failure -File $Path -Message 'File looks UTF-8 encoded. Keep batch/text helpers in GBK (code page 936).'
        }
    }
}

function Probe-CmdSyntax {
    # Keep this probe minimal and robust across runner images.
    # Avoid commands that may produce locale-dependent output or huge help text.
    $probe = @(
        'echo probe-cmd',
        'setlocal EnableExtensions & ver >nul'
    )

    foreach ($command in $probe) {
        $process = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $command" -NoNewWindow -PassThru -Wait
        if ($process.ExitCode -ne 0) {
            Add-Failure -Message "cmd syntax probe failed: $command (exit $($process.ExitCode))"
        }
    }
}

$script:Failures = @()

$trackedFiles = (git -C $repoRoot -c core.quotePath=false ls-files -z) -split "`0" | Where-Object { $_ }

foreach ($file in $trackedFiles) {
    $expectedEol = Get-EolExpectation -Path $file
    if ($expectedEol) {
        Validate-LineEndings -Path $file -Expected $expectedEol
    }
}

$cmdAndText = (git -C $repoRoot -c core.quotePath=false ls-files -z -- '*.cmd' '*.txt') -split "`0" | Where-Object { $_ }
foreach ($file in $cmdAndText) {
    Validate-Encoding -Path $file
}

Probe-CmdSyntax

if (-not $Failures) {
    Write-Host 'All checks passed.'
    exit 0
}

Emit-Failures
