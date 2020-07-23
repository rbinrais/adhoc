 # This script requires an application registration that's granted Microsoft Graph API permission
# https://docs.microsoft.com/azure/active-directory-b2c/microsoft-graph-get-started

# NOTE: Application requires GraphAPI permission --> https://graph.microsoft.com/AuditLog.Read.All

function Download-B2CSignInLogs {
        [CmdletBinding()]
        param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [System.String]
        $ClientID,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [System.String]
        $ClientSecret,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [System.String]
        $tenantdomain,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [System.String]
        $filePath
        )

$loginURL       = "https://login.microsoftonline.com"
$resource       = "https://graph.microsoft.com"           # Microsoft Graph API resource URI
#$xdaysago       = "{0:s}" -f (get-date).AddDays(-7) + "Z" # Use 'AddMinutes(-5)' to decrement minutes, for example

$startDate = (get-date).AddDays(-1)
$startDateStr = $startDate.ToString("yyyy-MM-dd")

$endDate = $startDate.AddDays(1)
$endDateStr = $endDate.ToString("yyyy-MM-dd")

Write-Output "-----------------------------------------"
Write-Output "Downloading signin logs for $startDateStr"
Write-Output "-----------------------------------------"


# Create HTTP header, get an OAuth2 access token based on client id, secret and tenant domain
$body       = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}
$oauth      = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body

# Parse audit report items, save output to file(s): auditX.json, where X = 0 through n for number of nextLink pages
if ($oauth.access_token -ne $null) {
    $i=0
    $headerParams = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}
  
    #Use following url for Sign-In Logs
    $url = "https://graph.microsoft.com/beta/auditLogs/signIns?&`$filter=createdDateTime ge "+ $startDateStr + " and createdDateTime le " + $endDateStr
    $filePath = "$filePath\signinlogs"
    
    # loop through each query page (1 through n)
    Do {
        # display each event on the console window
        # Write-Output "Connecting to Uri ==> $url"
        $myReport = (Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $url)
        foreach ($event in ($myReport.Content | ConvertFrom-Json).value) {
           # Write-Output ($event | ConvertTo-Json)
        }

        # save the query page to an output file
        Write-Output "Saving logs to a file ==> $filePath$i.json"
        $myReport.Content | Out-File -FilePath $filePath$i.json -Force
        $url = ($myReport.Content | ConvertFrom-Json).'@odata.nextLink'
        $i = $i+1
    } while($url -ne $null)
} 
else {
    Write-Host "ERROR: No Access Token"
} 
Write-Output "-----------------------------------------"

}

# $args[0]     Your application's client ID, a GUID
# $args[1]     Your application's client secret
# $args[2]     Your Azure AD B2C tenant domain name
# $args[3]     File Path to save the SignInlogs

# Download SignIn user logs for last 1 day (24hrs) for a B2C tenant
# Example: .\Download-B2CSignInLogs.ps1 "Your application's client ID, a GUID" "Your application's client secret" "Your Azure AD B2C tenant domain name" "File Path to save the SignInlogs, e.g. C:\Logs"
# Sample Output: 
# -----------------------------------------
# Downloading signin logs for 2020-07-22
# -----------------------------------------
# Connecting to Uri ==> https://graph.microsoft.com/beta/auditLogs/signIns?&$filter=
# createdDateTime ge 2020-07-22 and createdDateTime le 2020-07-23
# Saving logs to a file ==> Z:\Desktop\certs\signinlogs0.json
# -----------------------------------------

Download-B2CSignInLogs $args[0] $args[1] $args[2] $args[3]