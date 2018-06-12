param(
    [Parameter(Mandatory=$true)]
    [string]
    $SiteName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Path = "*",

    [Parameter()]
    [int]
    [ValidateNotNullOrEmpty()]
    $FailureTimeTakenSeconds,

    [Parameter()]
    [string]
    $FailureStatusCodes = "400-500"
)
try {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $WarningPreference = 'SilentlyContinue'
    Import-Module -Name WebAdministration
    $psPath = "IIS:\Sites\$SiteName"
    Set-ItemProperty -PsPath $psPath -Name traceFailedRequestsLogging `
        -Value @{
        enabled     = $true
        directory   = "%SystemDrive%\inetpub\logs\FailedReqLogFiles"
        maxLogFiles = 100
    }

    $pspath = "MACHINE/WEBROOT/APPHOST/$SiteName"
    # clear existing config if any otherwise it would fail
    Clear-WebConfiguration "/system.webServer/tracing/traceFailedRequests" -PSPath $pspath

    Add-WebConfigurationProperty -pspath $pspath `
        -filter "system.webServer/tracing/traceFailedRequests" -name "." -value @{path = "$Path"}

    Add-WebConfigurationProperty -pspath $pspath `
        -filter "system.webServer/tracing/traceFailedRequests/add[@path='$Path']/traceAreas" -name "." `
        -value @{provider = 'ASP'; verbosity = 'Verbose'}

    Add-WebConfigurationProperty -pspath $pspath `
        -filter "system.webServer/tracing/traceFailedRequests/add[@path='$Path']/traceAreas" -name "." `
        -value @{provider = 'ASPNET'; areas = 'Infrastructure,Module,Page,AppServices'; verbosity = 'Verbose'}

    Add-WebConfigurationProperty -pspath $pspath `
        -filter "system.webServer/tracing/traceFailedRequests/add[@path='$Path']/traceAreas" -name "." `
        -value @{provider = 'ISAPI Extension'; verbosity = 'Verbose'}

    Add-WebConfigurationProperty -pspath $pspath `
        -filter "system.webServer/tracing/traceFailedRequests/add[@path='$Path']/traceAreas" -name "." `
        -value @{provider = 'WWW Server'; areas = 'Authentication,Security,Filter,StaticFile,CGI,Compression,Cache,RequestNotifications,Module,FastCGI,WebSocket'; verbosity = 'Verbose'}

    if ($PSBoundParameters.ContainsKey("FailureTimeTaken")) {
        Write-Verbose "Setting timeTaken to $FailureTimeTaken"
        Set-WebConfigurationProperty -pspath $pspath `
            -filter "system.webServer/tracing/traceFailedRequests/add[@path='$Path']/failureDefinitions" `
            -name "timeTaken" -value (New-TimeSpan -Seconds $FailureTimeTakenSeconds).ToString()
    }

    if ($PSBoundParameters.ContainsKey("FailureStatusCodes") -or `
            $null -ne $FailureStatusCodes) {
        Set-WebConfigurationProperty -pspath $pspath `
            -filter "system.webServer/tracing/traceFailedRequests/add[@path='$Path']/failureDefinitions" `
            -name "statusCodes" -value $FailureStatusCodes
    }

} catch {
    Write-Error $_
}
