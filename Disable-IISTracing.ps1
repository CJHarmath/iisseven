param(
    [Parameter(Mandatory=$true)]
    [string]
    $SiteName
)
try {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $WarningPreference = 'SilentlyContinue'
    Import-Module -Name WebAdministration
    $psPath = "IIS:\Sites\$SiteName"
    # disable site level trace
    Set-ItemProperty -PsPath $psPath -Name traceFailedRequestsLogging -Value @{enabled = $false}
    # Remove tracing rules
    Clear-WebConfiguration "/system.webServer/tracing/traceFailedRequests" -PSPath $pspath
} catch {
    Write-Error $_
}
