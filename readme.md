#  Powershell script for building Azure ML Workspace in batch
This Powershell scripts are designed for for building Azure ML Workspace in batch. Each lab user (seat) will be allocated with one dedicated Azure ML workspace and one dedicated Computer Instance. And all the lab users shared the same Storage Account, Azure Key Vault and Application Insight.

Verify the Powershell version and make sure the version above 5.1
```PowerShell
$PSVersionTable.PSVersion
```



##  Step 1: Install the Azure PowerShell Module
    If you haven't install the following Azure PowerShell module, please send these commands with **administator** shell:
```PowerShell
    Install-Module -Name Microsoft.Graph.Authentication -AllowClobber -Force
    Install-Module -Name Microsoft.Graph.Users -AllowClobber -Force
    Install-Module -Name Az.Accounts -AllowClobber -Force
    Install-Module -Name Az.Compute -AllowClobber -Force
    Install-Module -Name Az.MachineLearningServices -AllowClobber -Force
```

##  Step 2: Verify the Installation
Verify the modules are installed completely by sending these commands:
```PowerShell
Get-Module -ListAvailable -Name Microsoft.Graph.Authentication
Get-Module -ListAvailable -Name Microsoft.Graph.Users
Get-Module -ListAvailable -Name Az.Accounts
Get-Module -ListAvailable -Name Az.Compute
Get-Module -ListAvailable -Name Az.MachineLearningServices
```   

##  Step 3: Single sign-on with your Azure account
**This step requires M365 admin permission.**

Send "Connect-AzAccount" command to sign on with your browser, you may need to have Azure Subscription Reader role or corresponding role privilege above.

```PowerShell
Connect-AzAccount -TenantId "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyy"
``` 

##  Step 4: Create M365 users for AML workspaces access 
**This step requires M365 admin permission.**

Open the createuser.ps1 and modify the variablies below.
```PowerShell
    # Define the class name
    $classname = "mlclass100"
    # Enter your M365 tenant domain name
    $domainname = "yourM365domain.com"
    # Enter your M365 tenant Id
    $TenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
    # Enter default password for the users
    $defaultPassword = "happyhackazureML2025"
    # Enter number of users to be created
    $seat = 1
```
and then execute
```
.\createuser.ps1
``` 
After the execution is completed, you can see a new file "user_details.csv" is generated. Keep this file unchanged for Step 5 and Step 7.

##  Step 5: Create Azure ML workspaces/Computer instances resources
**This step requires Azure Subscription owner permission.**

Open the provisioning.ps1 and modify the variablies below
```PowerShell
    # Enter your Azure subscription Id and Tenant Id
    $TenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
    $SubscriptionId = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyy"
    # Enter number of users to be created
    $seat = 1
    # Enter the class name for this lab
    $classname = "mlclass100"
    # Enter the resource location
    $location = "centralus"
```
and then execute
```
.\provisioning.ps1
``` 

Azure ML workspace and computer instance takes (8-10 minutues) for one seat provision. Please be patient if seat number is high.

##  Step 6: Remove all the Azure ML workspaces resources

``` 
.\deleteworkspace.ps1
``` 

##  Optional Step: Remove computer instance only

``` 
.\deletecomputeronly.ps1
``` 

##  Step 7: Remove all M365 users

``` 
.\deleteuser.ps1
``` 

##  Step 8: Remove the shared Azure resources
Access Azure portal, select the **Resource Group**, locate your resource group name like "rg-mlclass100", and manual remove the Storage Account, Azure Key Vault, Application Insight and Resource Group as well.
