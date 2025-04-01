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
#Check the URL for the valid regional value if you want to change this 
$usageLocation = "US"  # Adjust as needed (https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.users/new-mguser?view=graph-powershell-1.0#-usagelocation)

# Increase function capacity
$maximumfunctioncount = 32768

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

Write-Output "$(Get-Date -Format HH:mm:ss) Creating User accounts"

# Initialize an array to store user details
$userDetails = @()

# Loop to create user accounts
for ($i = 1; $i -le $seat; $i++) {
    # Generate the username
    $username = $classname + "user" + "{0:D2}" -f $i
    
    # Create the password profile
    $PasswordProfile = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphPasswordProfile
    $PasswordProfile.Password = $defaultPassword
    $PasswordProfile.ForceChangePasswordNextSignIn = $false
    
    # Create the user account
    $user = New-MgUser -DisplayName $username -GivenName $username -Surname "User" -UserPrincipalName "$username@$domainname" -UsageLocation $usageLocation -MailNickname $username -PasswordProfile $PasswordProfile -AccountEnabled
    
    # Retrieve the user object ID
    $userId = $user.UserPrincipalName
    $userObjectId = $user.Id
    
    # Add user details to the array
    $userDetails += [PSCustomObject]@{
        UserId = $userId
        UserObjectId = $userObjectId
    }
    
    Write-Output "$(Get-Date -Format HH:mm:ss) Created user: $username"
}

# Save user details to a CSV file
$userDetails | Export-Csv -Path "user_details.csv" -NoTypeInformation

Write-Output "$(Get-Date -Format HH:mm:ss) User creation is completed"
