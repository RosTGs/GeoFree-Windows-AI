[CmdletBinding()]
param(
    [switch]$NoElevate
)

$ErrorActionPreference = "Stop"

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    if ($NoElevate) {
        throw "Administrator rights are required to edit the Windows hosts file."
    }

    $process = Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$PSCommandPath`""
    ) -Wait -PassThru
    exit $process.ExitCode
}

$hostsPath = Join-Path $env:SystemRoot "System32\drivers\etc\hosts"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = "$hostsPath.backup.$timestamp"
$startMarker = "# --- GEOFREE START ---"
$endMarker = "# --- GEOFREE END ---"
$startPattern = [regex]::Escape($startMarker)
$endPattern = [regex]::Escape($endMarker)

Copy-Item -LiteralPath $hostsPath -Destination $backupPath -Force

$existing = [IO.File]::ReadAllText($hostsPath)
$newContent = [regex]::Replace(
    $existing,
    "(?ms)^\s*$startPattern.*?^\s*$endPattern\r?\n?",
    ""
).TrimEnd() + [Environment]::NewLine

[IO.File]::WriteAllText($hostsPath, $newContent, [Text.Encoding]::ASCII)

ipconfig /flushdns | Out-Null

Write-Host "GeoFree hosts block removed." -ForegroundColor Green
Write-Host "Backup: $backupPath"
