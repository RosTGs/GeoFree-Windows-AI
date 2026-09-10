[CmdletBinding()]
param(
    [string[]]$Domains = @(
        "chatgpt.com",
        "api.openai.com",
        "claude.ai",
        "gemini.google.com",
        "copilot.microsoft.com",
        "grok.com",
        "elevenlabs.io"
    )
)

$hostsPath = Join-Path $env:SystemRoot "System32\drivers\etc\hosts"
$hosts = Get-Content -LiteralPath $hostsPath -Raw

foreach ($domain in $Domains) {
    $hostsLine = Select-String -InputObject $hosts -Pattern "(?im)^\s*(\d{1,3}(?:\.\d{1,3}){3})\s+$([regex]::Escape($domain))\s*$"
    $resolved = try {
        Resolve-DnsName $domain -Type A -ErrorAction Stop |
            Where-Object { $_.IPAddress } |
            Select-Object -First 1 -ExpandProperty IPAddress
    }
    catch {
        "resolve failed"
    }

    [pscustomobject]@{
        Domain = $domain
        HostsEntry = if ($hostsLine) { $hostsLine.Matches[0].Groups[1].Value } else { "missing" }
        CurrentResolve = $resolved
    }
}
