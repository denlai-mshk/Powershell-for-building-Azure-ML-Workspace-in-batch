# Enter your Azure subscription Id and Tenant Id
$TenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
$SubscriptionId = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyy"
# Enter number of users to be created
$seat = 1
# Enter the class name for this lab
$classname = "mlclass100"
# Enter the resource location
$location = "centralus"
#predefine resource names for shared components
$resourceGroupName = "rg-" + $classname
$sharedAKV = "$classname" + "kv"
$sharedStorageAccount = "$classname" + "sa"
$sharedAppInsight = "$classname" + "ai"
# Since mose of SKU's vCore default quota is 100, you can define more than one SKU if number of seat more than 25 (e.g. 25 x 4 vCore)
$supportedSKU = "Standard_E4ds_v4, Standard_DS3_v2" -split ", "

# Ensure the required modules are imported
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Install-Module -Name Az.Accounts -AllowClobber -Force
}
Import-Module Az.Accounts

if (-not (Get-Module -ListAvailable -Name Az.Compute)) {
    Install-Module -Name Az.Compute -AllowClobber -Force
}
Import-Module Az.Compute
if (-not (Get-Module -ListAvailable -Name Az.MachineLearningServices)) {
    Install-Module -Name Az.MachineLearningServices -AllowClobber -Force
}
Import-Module Az.MachineLearningServices



try {
    Connect-AzAccount -TenantId $TenantId -SubscriptionId $SubscriptionId -ErrorAction Stop
} catch {
    Write-Output "Failed to authenticate. Please ensure you are logged in with the correct account."
    exit
}

# Read the CSV file
$userDetails = Import-Csv -Path "$PSScriptRoot\user_details.csv"

# Check if Resource Group exists
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (-not $resourceGroup) {
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}

Write-Output "$(Get-Date -Format HH:mm:ss) Check if Key Vault exists"
# Check if Key Vault exists
$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $sharedAKV -ErrorAction SilentlyContinue
if (-not $keyVault) {
    Write-Output "$(Get-Date -Format HH:mm:ss) Creating Key Vault $sharedAKV"
    $keyVault = New-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $sharedAKV -Location $location
}
Write-Output " kv = $($keyVault.ResourceId)"

Write-Output "$(Get-Date -Format HH:mm:ss) Check if Storage Account exists"
# Check if Storage Account exists
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $sharedStorageAccount -ErrorAction SilentlyContinue
if (-not $storageAccount) {
    Write-Output "$(Get-Date -Format HH:mm:ss) Creating Storage Account $sharedStorageAccount"
    $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $sharedStorageAccount -Location $location -SkuName Standard_LRS
}
Write-Output " sa = $($storageAccount.Id)"

Write-Output "$(Get-Date -Format HH:mm:ss) Check if Application Insights exists"
# Check if Application Insights exists
$appInsights = Get-AzApplicationInsights -ResourceGroupName $resourceGroupName -Name $sharedAppInsight -ErrorAction SilentlyContinue
if (-not $appInsights) {
    Write-Output "$(Get-Date -Format HH:mm:ss) Creating appInsights $sharedAppInsight"
    $appInsights = New-AzApplicationInsights -ResourceGroupName $resourceGroupName -Name $sharedAppInsight -Location $location -Kind web
}
Write-Output " ai = $($appInsights.Id)"

Write-Output "$(Get-Date -Format HH:mm:ss) Check if Machine Learning Workspace exists"

# Create Machine Learning Workspaces and Compute Instances based on the seat variable
for ($i = 1; $i -le $seat; $i++) {
    $formattedIndex = "{0:D2}" -f $i
    $workspaceName = $classname + "user" + $formattedIndex
    $mlWorkspace = Get-AzMLWorkspace -ResourceGroupName $resourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
    if (-not $mlWorkspace) {
        Write-Output "$(Get-Date -Format HH:mm:ss) Creating workspace $workspaceName"
        $mlWorkspace = New-AzMLWorkspace -Name $workspaceName -ResourceGroupName $resourceGroupName -Location $location -ApplicationInsightId $appInsights.Id -KeyVaultId $keyVault.ResourceId -StorageAccountId $storageAccount.Id -IdentityType "SystemAssigned" -Kind 'Default'
        Write-Output "$(Get-Date -Format HH:mm:ss) workspace $workspaceName is created"
        # Assign the "AzureML Data Scientist" role to the user
        $userId = $userDetails[$i-1].UserObjectId
        $roleDefinition = Get-AzRoleDefinition -Name "AzureML Data Scientist"
        New-AzRoleAssignment -ObjectId $userId -RoleDefinitionName $roleDefinition.Name -Scope $mlWorkspace.Id
        Write-Output "$(Get-Date -Format HH:mm:ss) roleDefinition is assigned"
    }
    Write-Output " mlwk = $($mlWorkspace.name)"
    
    Write-Output "$(Get-Date -Format HH:mm:ss) Check if compute instance exists"
    # Check if compute instance exists
    $computeName = $classname + "compute" + $formattedIndex
    $computeInstance = Get-AzMLWorkspaceCompute -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name $computeName -ErrorAction SilentlyContinue
    if (-not $computeInstance) {
        Write-Output "$(Get-Date -Format HH:mm:ss) Creating compute instance $computeName"
        # Round-robin the SKU
        $skuIndex = $i % $supportedSKU.Length
        $skuName = $supportedSKU[$skuIndex]

        # Assign the UserObjectId from the CSV file
        $assignedUserObjectId = $userDetails[$i-1].UserObjectId
        # Create compute instance object
        $computeObject = New-AzMLWorkspaceComputeInstanceObject -VMSize $skuName -EnableNodePublicIP $true `
        -AssignedUserObjectId $assignedUserObjectId `
        -AssignedUserTenantId $TenantId `
        
        # Add compute instance to the workspace
        New-AzMLWorkspaceCompute -Name $computeName -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Location $location -Compute $computeObject
        Write-Output "$(Get-Date -Format HH:mm:ss) compute instance $computeName with SKU = $skuName is created"

    } else {
        Write-Output "$(Get-Date -Format HH:mm:ss) compute instance $computeName already exists"
    }
}
