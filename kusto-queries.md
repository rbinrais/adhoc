## Setup Azure AD Monitoring B2C 
Complete the one time setup following the instructions available [here](https://docs.microsoft.com/en-us/azure/active-directory-b2c/azure-monitor). Please make sure you have account(s) with following permissions for a successful setup. 


| Subscription   |      Permissions     
|----------|:-------------:|------:|
| Azure Monitoring | Subscription Owner 
| Azure AD B2C | Global Adminisstrator
 
## Logs Schema

* SignIn Logs: https://docs.microsoft.com/en-us/azure/active-directory/reports-monitoring/reference-azure-monitor-sign-ins-log-schema

```
{ 
    "time": "2019-03-12T16:02:15.5522137Z", 
    "resourceId": "/tenants/<TENANT ID>/providers/Microsoft.aadiam",
    "operationName": "Sign-in activity", 
    "operationVersion": "1.0", 
    "category": "SignInLogs", 
    "tenantId": "<TENANT ID>", 
    "resultType": "50140", 
    "resultSignature": "None", 
    "resultDescription": "This error occurred due to 'Keep me signed in' interrupt when the user was signing-in.", 
    "durationMs": 0, 
    "callerIpAddress": "<CALLER IP ADDRESS>", 
    "correlationId": "a75a10bd-c126-486b-9742-c03110d36262", 
    "identity": "Timothy Perkins", 
    "Level": 4, 
    "location": "US", 
    "properties": 
        {
            "id":"0231f922-93fa-4005-bb11-b344eca03c01",
            "createdDateTime":"2019-03-12T16:02:15.5522137+00:00",
            "userDisplayName":"Timothy Perkins",
            "userPrincipalName":"<USER PRINCIPAL NAME>",
            "userId":"<USER ID>",
            "appId":"<APPLICATION ID>",
            "appDisplayName":"Azure Portal",
            "ipAddress":"<IP ADDRESS>",
            "status":
            {
                "errorCode":50140,
                "failureReason":"This error occurred due to 'Keep me signed in' interrupt when the user was signing-in."
            },
            "clientAppUsed":"Browser",
            "deviceDetail":
            {
                "operatingSystem":"Windows 10",
                "browser":"Chrome 72.0.3626"
            },
            "location":
                {
                    "city":"Bellevue",
                    "state":"Washington",
                    "countryOrRegion":"US",
                    "geoCoordinates":
                    {
                        "latitude":45,
                        "longitude":122
                    }
                },
            "correlationId":"a75a10bd-c126-486b-9742-c03110d36262",
            "conditionalAccessStatus":"notApplied",
            "appliedConditionalAccessPolicies":
            [
                {
                    "id":"ae11ffaa-9879-44e0-972c-7538fd5c4d1a",
                    "displayName":"Hr app access policy",
                    "enforcedGrantControls":
                    [
                        "Mfa"
                    ],
                    "enforcedSessionControls":
                    [
                    ],
                    "result":"notApplied"
                },
                {
                    "id":"b915a70b-2eee-47b6-85b6-ff4f4a66256d",
                    "displayName":"MFA for all but global support access",
                    "enforcedGrantControls":[],
                    "enforcedSessionControls":[],
                    "result":"notEnabled"
                },
                {
                    "id":"830f27fa-67a8-461f-8791-635b7225caf1",
                    "displayName":"Header Based Application Control",
                    "enforcedGrantControls":["Mfa"],
                    "enforcedSessionControls":[],
                    "result":"notApplied"
                },
                {
                    "id":"8ed8d7f7-0a2e-437b-b512-9e47bed562e6",
                    "displayName":"MFA for everyones",
                    "enforcedGrantControls":[],
                    "enforcedSessionControls":[],
                    "result":"notEnabled"
                },
                {
                    "id":"52924e0f-798b-4afd-8c42-49055c7d6395",
                    "displayName":"Device compliant",
                    "enforcedGrantControls":[],
                    "enforcedSessionControls":[],
                    "result":"notEnabled"
                },
             ],
            "isInteractive":true,
            "tokenIssuerType":"AzureAD",
            "authenticationProcessingDetails":[],
            "networkLocationDetails":[],
            "processingTimeInMilliseconds":0,
            "riskDetail":"hidden",
            "riskLevelAggregated":"hidden",
            "riskLevelDuringSignIn":"hidden",
            "riskState":"none",
            "riskEventTypes":[],
            "resourceDisplayName":"windows azure service management api",
            "resourceId":"797f4846-ba00-4fd7-ba43-dac1f8f63013",
            "authenticationMethodsUsed":[]
        }
}
```
 
## Reporting
This section shows how to create and run the reports on Azure AD B2C logs. 

To create a new report, frist navigate to the resource group that you have created in the previous step, and then select the Log Analytics workspace.

* Select "Logs", and then press "Get Started" button. Next time you may not be asked to press the button.

![Logs](/Users/razi/Desktop/azb2c/Azure-Monitor-B2C-Configuration.md)

* To confirm that the Audit and Signin logs from Azure AD B2C are getting synced properly, expand "Log Management" option available under the "Tables" tab. You should see both AuditLogs and SigninLogs are available.

![Logs](/Users/razi/Desktop/azb2c/Azure-Monitor-B2C-Configuration.md)

* You are now ready to create your first report. The reports are authored in Kusto query langauge [Kusto](). All queries provides here are fully functional and do not requiere you to have prior knownledge of Kusto. 


* <b> Failed User Signins: </b> : This query list failed user signins for the past 30 days.

```
let duration = ago(90d);
SigninLogs
| where TimeGenerated >= duration
| extend OS= DeviceDetail.operatingSystem
| extend Browser =extract("([a-zA-Z]+)",1,tostring(DeviceDetail.browser))
| where OS!=""
| where Browser !=""
| where ResultType !~ "0" 
| summarize  by UserPrincipalName, ResultDescription, tostring(OS), tostring(Browser), IPAddress, TimeGenerated
| sort by TimeGenerated asc   
```


* <b> Requets Per IP Address: </b> This query list IP Addresses along with the number of requests send by them in the past 30 days.
```
SigninLogs
| where TimeGenerated >= ago(180d)
| extend OS= DeviceDetail.operatingSystem
| extend Browser =extract("([a-zA-Z]+)",1,tostring(DeviceDetail.browser))
| where OS!=""
| where Browser !=""
| UserPrincipalName, ClientAppUsed, IPAddress
| summarize signInCount = count() by IPAddress
| sort by signInCount desc       
```

* <b> B2C Policy Usage</b> This query list policy usage based on token issued in the past 30 days.
```
let duration = ago(30d);
AuditLogs 
| where TimeGenerated  > duration
| where OperationName contains "issue"
| extend  UserId=extractjson("$.[0].id",tostring(TargetResources))
| extend Policy=extractjson("$.[1].value",tostring(AdditionalDetails))
| summarize SignInCount = count() by Policy
| order by SignInCount desc  nulls last 
| render table        
```


* <b> Failed User Signins: </b> : This query displays list of policies called and issued a token .

```
SigninLogs
| where ResultType !~ "0" 
| summarize  by UserPrincipalName, ResultDescription, ResultType, tostring( DeviceDetail), IPAddress
| sort by ResultType asc         
```

* <b> Signins by Location: </b> This query displays list of signins by location in the past 30 days.
```
let duration = ago(30d);
SigninLogs
| where TimeGenerated  >= duration
| where AppDisplayName != ""
| summarize signInCount = count() by Location
```

* <b> Signins Per Browser: </b> This query displays list of signins per browser agent in the past 30 days.

```
let duration = ago(30d);
SigninLogs
|where TimeGenerated  > duration
|extend OS= DeviceDetail.operatingSystem
|extend Browser =extract("([a-zA-Z]+)",1,tostring(DeviceDetail.browser))
|where OS!=""
|where Browser !=""
|where AppDisplayName !=""
|summarize signInCount = count() by tostring(DeviceDetail.browser)
```

* <b> Signins Per Operating System: </b> This query displays list of signins per browser agent in the past 30 days.
```
let duration = ago(30d);
SigninLogs
|where TimeGenerated  > duration
|extend OS= DeviceDetail.operatingSystem
|where OS!=""
|where AppDisplayName !=""
|summarize signInCount = count() by tostring(OS)
```


## Alerts
This section shows how to create, test and run the reports. 

