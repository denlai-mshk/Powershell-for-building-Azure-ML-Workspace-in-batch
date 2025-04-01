# Enter your Azure subscription Id and Tenant Id
$TenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
$SubscriptionId = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyy"
# Enter number of users to be created
$seat = 1
# Enter the class name for this lab
$classname = "mlclass100"
#predefine resource names for shared components
$resourceGroupName = "rg-" + $classname

# Increase function capacity
$maximumfunctioncount = 32768

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

# Create dependent resources

# Delete resources
for ($i = 1; $i -le $seat; $i++) {
    $formattedIndex = "{0:D2}" -f $i
    $workspaceName = $classname + "user" + $formattedIndex
    $computeName = $classname + "compute" + $formattedIndex

    Write-Output "$(Get-Date -Format HH:mm:ss) Check if compute instance exists"
    # Check if compute instance exists
    $computeInstance = Get-AzMLWorkspaceCompute -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name $computeName -ErrorAction SilentlyContinue
    if ($computeInstance) {
        Write-Output "$(Get-Date -Format HH:mm:ss) Deleting compute instance $computeName"
        Remove-AzMLWorkspaceCompute -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -Name $computeName -UnderlyingResourceAction 'Delete'
        Write-Output "$(Get-Date -Format HH:mm:ss) Compute instance $computeName is deleted"
        
    } 
    Write-Output "$(Get-Date -Format HH:mm:ss) Check if workspace exists"
    # Check if workspace exists
    $workspace = Get-AzMLWorkspace -ResourceGroupName $resourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
    if ($workspace) {
        Write-Output "$(Get-Date -Format HH:mm:ss) Deleting workspace $workspaceName"
        Remove-AzMLWorkspace -ResourceGroupName $resourceGroupName -Name $workspaceName -ForceToPurge
        Write-Output "$(Get-Date -Format HH:mm:ss) workspace $workspaceName is deleted"
    } else {
        Write-Output "$(Get-Date -Format HH:mm:ss) Workspace $workspaceName does not exist"
    }

}
