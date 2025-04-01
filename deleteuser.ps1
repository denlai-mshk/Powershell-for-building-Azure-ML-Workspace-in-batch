# Enter your M365 tenant Id
$TenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
# make sure user_details.csv is in the same directory as this script

# Ensure the required modules are installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Install-Module -Name Microsoft.Graph.Authentication -AllowClobber -Force
}
Import-Module Microsoft.Graph.Authentication

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
    Install-Module -Name Microsoft.Graph.Users -AllowClobber -Force
}
Import-Module Microsoft.Graph.Users



try {
    Connect-MgGraph -TenantId $TenantId -Scopes "User.ReadWrite.All" -NoWelcome
} catch {
    Write-Output "Failed to authenticate. Please ensure you are logged in with the correct account."
    exit
}

Write-Output "$(Get-Date -Format HH:mm:ss) Deleting User accounts"

# Import user details from CSV file
$userDetails = Import-Csv -Path "user_details.csv"

# Loop to delete user accounts
foreach ($user in $userDetails) {
    try {
        Remove-MgUser -UserId $user.UserObjectId -Confirm:$false
        Write-Output "$(Get-Date -Format HH:mm:ss) Deleted user: $user.UserId"
    } catch {
        Write-Output "$(Get-Date -Format HH:mm:ss) Failed to delete user: $user.UserId"
    }
}

Write-Output "$(Get-Date -Format HH:mm:ss) User deletion is completed"
