[CmdletBinding()]
param(
    [string]$SourceUrl = "https://raw.githubusercontent.com/Internet-Helper/GeoHideDNS/refs/heads/main/hosts/hosts",
    [string[]]$ExtraIPs = @("80.74.24.165"),
    [switch]$NoElevate
)

$ErrorActionPreference = "Stop"

$TargetDomains = @(
    "chatgpt.com",
    "ab.chatgpt.com",
    "webrtc.chatgpt.com",
    "tcr9i.chat.openai.com",
    "auth.openai.com",
    "platform.openai.com",
    "api.openai.com",
    "cdn.oaistatic.com",
    "files.oaiusercontent.com",
    "auth0.openai.com",
    "cdn.auth0.com",
    "gemini.google.com",
    "aistudio.google.com",
    "labs.google.com",
    "generativelanguage.googleapis.com",
    "aisandbox-pa.googleapis.com",
    "alkalimakersuite-pa.clients6.google.com",
    "aitestkitchen.withgoogle.com",
    "copilot.microsoft.com",
    "sydney.bing.com",
    "edgeservices.bing.com",
    "claude.ai",
    "api.claude.ai",
    "platform.claude.ai",
    "anthropic.com",
    "api.anthropic.com",
    "x.ai",
    "grok.com",
    "accounts.x.ai",
    "elevenlabs.io",
    "api.elevenlabs.io"
)

$ProbeUrls = @(
    "https://chatgpt.com/",
    "https://api.openai.com/v1/models",
    "https://claude.ai/",
    "https://gemini.google.com/"
)

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SourceHosts {
    param([string]$Url)

    Write-Host "Downloading hosts source: $Url"
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 30
    return $response.Content -split "`r?`n"
}

function Get-CandidateIPs {
    param([string[]]$Lines)

    $domainSet = @{}
    foreach ($domain in $TargetDomains) {
        $domainSet[$domain.ToLowerInvariant()] = $true
    }

    $ips = New-Object System.Collections.Generic.List[string]
    foreach ($line in $Lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match "^\s*#|^\s*$") {
            continue
        }

        if ($trimmed -match "^(?<ip>\d{1,3}(?:\.\d{1,3}){3})\s+(?<domain>[^\s#]+)") {
            $ip = $matches.ip
            $domain = $matches.domain.ToLowerInvariant()
            if ($domainSet.ContainsKey($domain) -and $ip -notmatch "^(0\.0\.0\.0|127\.0\.0\.1)$" -and -not $ips.Contains($ip)) {
                $ips.Add($ip)
            }
        }
    }

    foreach ($ip in $ExtraIPs) {
        if ($ip -and -not $ips.Contains($ip)) {
            $ips.Add($ip)
        }
    }

    return $ips.ToArray()
}

function Test-HttpsEndpoint {
    param(
        [string]$Url,
        [int]$Attempts = 3
    )

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            $request = [Net.WebRequest]::Create($Url)
            $request.Method = "GET"
            $request.Timeout = 12000
            $request.AllowAutoRedirect = $false
            $request.UserAgent = "GeoFree-AutoProbe/2.0"
            $response = $request.GetResponse()
            $response.Close()
            return $true
        }
        catch [Net.WebException] {
            if ($_.Exception.Response) {
                $_.Exception.Response.Close()
                return $true
            }
        }
        catch {
        }

        if ($attempt -lt $Attempts) {
            Start-Sleep -Seconds 2
        }
    }

    return $false
}

function Test-Candidate {
    param([string]$IP)

    $resolved = Resolve-DnsName chatgpt.com -Type A -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress } |
        Select-Object -First 1 -ExpandProperty IPAddress

    $tcpOk = Test-NetConnection -ComputerName chatgpt.com -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
    $httpsResults = foreach ($url in $ProbeUrls) {
        [pscustomobject]@{
            Url = $url
            Ok = Test-HttpsEndpoint $url
        }
    }

    $httpsOkCount = @($httpsResults | Where-Object { $_.Ok }).Count
    [pscustomobject]@{
        IP = $IP
        Resolved = $resolved
        Tcp443Ok = [bool]$tcpOk
        HttpsOkCount = $httpsOkCount
        HttpsResults = $httpsResults
        Ok = (($resolved -eq $IP) -and $tcpOk -and ($httpsOkCount -eq $ProbeUrls.Count))
    }
}

if (-not (Test-IsAdmin)) {
    if ($NoElevate) {
        throw "Administrator rights are required to edit the Windows hosts file."
    }

    $command = "& `"$PSCommandPath`" -SourceUrl `"$SourceUrl`""
    foreach ($ip in $ExtraIPs) {
        $command += " -ExtraIPs `"$ip`""
    }
    $command += "; exit `$LASTEXITCODE"

    $process = Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-Command", $command
    ) -Wait -PassThru
    exit $process.ExitCode
}

$lines = Get-SourceHosts $SourceUrl
$candidateIPs = Get-CandidateIPs $lines
if (-not $candidateIPs) {
    throw "Candidate IP list is empty: $SourceUrl"
}

Write-Host "Candidate IPs: $($candidateIPs -join ', ')"
foreach ($candidate in $candidateIPs) {
    Write-Host ""
    Write-Host "Trying $candidate ..."
    & "$PSScriptRoot\Apply-GeoFree.ps1" -IP $candidate -NoElevate
    Start-Sleep -Seconds 2

    $result = Test-Candidate $candidate
    Write-Host "DNS: $($result.Resolved), TCP 443: $($result.Tcp443Ok), HTTPS: $($result.HttpsOkCount)/$($ProbeUrls.Count)"
    foreach ($probe in $result.HttpsResults) {
        Write-Host "  $($probe.Url) -> $($probe.Ok)"
    }

    if ($result.Ok) {
        Write-Host ""
        Write-Host "GeoFree AI access is ready with $candidate" -ForegroundColor Green
        exit 0
    }
}

Write-Error "Candidate verification finished. Run the script again to refresh the source list."
exit 1
