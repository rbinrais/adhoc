## Setup Azure AD Monitoring B2C 
Complete the one time setup following the instructions available [here](https://docs.microsoft.com/en-us/azure/active-directory-b2c/azure-monitor). Please make sure you have account(s) with following permissions for a successful setup. 


| Subscription   |      Permissions     
|----------|:-------------:|------:|
| Azure Monitoring | Subscription Owner 
| Azure AD B2C | Global Adminisstrator
 
 
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

* <b> B2C Policy Usage</b> This query list policy usage in the past 30 days.
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

* <b> B2C policies and token issued count</b> : This query displays list of policies called and issued a token .

```
let duration = ago(180d);
AuditLogs 
| where TimeGenerated  > duration
| where OperationName contains "issue"
| extend  UserId=extractjson("$.[0].id",tostring(TargetResources))
| extend Policy=extractjson("$.[1].value",tostring(AdditionalDetails))
| summarize Token_Issued_Count = count() by Policy
| order by Token_Issued_Count desc  nulls last 
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
let duration = ago(30);
SigninLogs
| where TimeGenerated  >= duration
| where AppDisplayName != ""
| summarize signInCount = count() by Location
```

## Alerts
This section shows how to create, test and run the reports. 

