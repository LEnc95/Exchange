<#
    Create Shared Mailbox

    Authored : RC-7201

#>

#Variables
$Date = Get-Date -Format "yyyy-MM-dd"
$DC = "gianteagle"
$OU = "OU=Shared Mailbox,DC=gianteagle,DC=com"
Add-Type -AssemblyName PresentationCore,PresentationFramework
$Error.Clear()

#Clean up PSSessions
Get-PSSession | Remove-PSSession

#Import AD Module, exit script if RSAT is not installed
$Module = Get-Module -ListAvailable | Select -ExpandProperty Name
if($module -match "ActiveDirectory"){
    Write-Host "Starting Create-SharedMailbox"
    $Error.Clear()}
    
else{
    Write-Host "Importing the AD PowerShell module"
    Import-Module -Name ActiveDirectory
    
    if($Error[0] -match "The specified module 'ActiveDirectory'"){
        $null = [System.Windows.MessageBox]::Show("The AD Module could not be imported and is required to run this script. The script will now exit.","Create-SharedMailbox")
        exit}
}

#Create O365 Exchange Function
function Start-Exchange365

  {
  $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $MSOCred -Authentication Basic -AllowRedirection
  Import-PSSession $Session -AllowClobber
  }

#Create On-Prem Exchange Function
function Start-Exchange

  {
  $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://excas10inf1.corp.gianteagle.com/PowerShell -Credential $OnPremCred -Authentication Kerberos
  Import-PSSession $Session -AllowClobber
  }
  

function Map-Domain

{
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Server
  )

  New-PSDrive -Name $Name -PSProvider ActiveDirectory -Server $Server -Root "//RootDSE/" -Scope Global
  }
  
Map-Domain Name$DC

Set-Location Name:

#Create Force-ADSync function
function Force-ADSync
{

  Invoke-Command -ComputerName Server.With.AADC -Credential $OnPremCred -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta}

}
  
#Prompt for Domain Admin account
Write-Host "Enter your Admin username/password"
$OnPremCred = Get-Credential
$CreatedBy = ($OnPremCred.UserName).Split("\")[1]

#Ask for Info
$Mailbox = Read-Host "Enter the mailbox name (no spaces)"
$DisplayName = Read-Host "Enter the mailbox display name"
$PrimarySMTP = Read-Host "Enter the mailbox email address"
$Ticket = Read-host "Enter the ticket number of this request"

#Confirm settings before continuing operation, if no, exit the script.
$ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
$MessageBody = "Please confirm the following settings. If not, click No or Cancel and run the script again;

                Email Address : $PrimarySMTP
                SAMAccountName/Alias : $Mailbox
                Display Name : $DisplayName
                Ticket Number : $ticket
                "
$MessageTitle = "Confirm Shared Mailbox Settings"
$MessageBox = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType)
$EndScript = $MessageBox -eq "Yes"

If($EndScript -eq $false){
    exit}

$Error.Clear()
$null = Start-Exchange
if($Error -match "Logon failure: unknown user name or bad password."){
  Write-Host "Logon failed. Please re-enter admin account credentials"
  $OnPremCred = Get-Credential
  $null = Start-Exchange
}

#Create Shared Mailbox user account
Write-Host "Creating $Mailbox"
$Info = "Created by $CreatedBy on $Date from ticket $ticket"
New-RemoteMailbox -Name $DisplayName -SamAccountName $Mailbox -DisplayName $DisplayName -PrimarySmtpAddress $PrimarySMTP -RemoteRoutingAddress $Mailbox@tenant.mail.onmicrosoft.com -OnPremisesOrganizationalUnit $OU -UserPrincipalName $PrimarySMTP -AccountDisabled
Write-host "Pausing for 1 minute"
start-sleep -seconds 60
Set-ADUser -Identity $Mailbox -Replace @{Info=$Info}
if($Error -match "Logon failure: unknown user name or bad password."){
  Write-Host "Logon failed. Please re enter Domain credentials"
  $OnPremCred = Get-Credential
  New-RemoteMailbox -Name $DisplayName -SamAccountName $Mailbox -DisplayName $DisplayName -PrimarySmtpAddress $PrimarySMTP -RemoteRoutingAddress $Mailbox@tenant.mail.onmicrosoft.com -OnPremisesOrganizationalUnit $OU -UserPrincipalName $PrimarySMTP -AccountDisabled
  Write-host "Pausing for 1 minute"
  start-sleep -seconds 60
  $error.clear()
  }


#Force AD Sync
$null = Force-ADSync

#Prompt for O365 Creds
$ButtonTypeOK = [System.Windows.MessageBoxButton]::OKCancel
$MessageBody = "Forcing an AD sync...keep in mind this does take a few minutes and the sync has already started. You can continue to progress. There is error checking in place to continue to attempt the commands until the mailbox is found.
                
In order to continue, when prompted, please enter your Global Admin/Exchange Online Admin account username/password."
$MessageTitle = "On-Prem actions completed!"
$MessageBoxOK = [System.Windows.Messagebox]::show($MessageBody,$MessageTitle,$ButtonTypeOK)
if($MessageBoxOk -eq "Cancel"){
  Exit
  }
$MSOCred = Get-Credential

Write-Host "Pausing for 30 seconds"
Start-Sleep -Seconds 30

#Clean up PSSessions
Get-PSSession | Remove-PSSession

$null = Start-Exchange365
if($Error -match "Logon failure: unknown user name or bad password."){
  Write-Host "Logon failed. Please re enter O365 credentials"
  $OnPremCred = Get-Credential
  $null = Start-Exchange365
  }
  
if($Error -match "Access is denied"){
  $ButtonTypeOK = [System.Windows.MessageBoxButton]::OKCancel
  $MessageBody = "Access is denied. If this is an error, please contact person@domain.com. 
  The created user account will now be deleted and AD will resync. Click OK to exit the script."
  $MessageTitle = "Access Denied"
  $MessageBoxOK = [System.Windows.Messagebox]::show($MessageBody,$MessageTitle,$ButtonTypeOK)
  Remove-ADUser $Mailbox -Confirm:$false
  Force-ADSync
  exit
  }
  
$Error.Clear()
Write-Host "Converting to shared mailbox..."
Write-Host "Forcing another AD Sync and pausing for 1 minute"
$null = Force-ADSync
Start-Sleep -Seconds 60
Set-Mailbox -Identity $Mailbox -Type Shared
if($Error[0] -match "The operation couldn't be performed because object '$Mailbox' couldn't be found on"){
  Write-Host "Mailbox wasn't found. Waiting 30 seconds..."
  Start-Sleep -Seconds 30
  do{
    $Error.Clear()
    Write-Host "Trying again..."
    Set-Mailbox -Identity $Mailbox -Type Shared
    Start-Sleep -Seconds 5
  }

  until(
    $Error.Count -eq "0"
  )
}

Write-Host "Setting AD Attribute to account"
Set-ADUser $Mailbox -Replace @{msExchRemoteRecipientType=100}
$msExchAttribute = Get-ADUser $Mailbox -Properties msExchRemoteRecipientType | Select -ExpandProperty msExchRemoteRecipientType
if($msExchAttribute -ne "100"){
  Set-ADUser $Mailbox -Replace @{msExchRemoteRecipientType=100}
}
Write-Host "Disabling account"
Disable-ADAccount $Mailbox

#Clean up PSSessions
Get-PSSession | Remove-PSSession

#Mailbox has been created
$ButtonTypeOK = [System.Windows.MessageBoxButton]::OKCancel
$MessageBody = "Shared mailbox has been created! Click OK to exit."
$MessageTitle = "O365 actions completed!"
$MessageBoxOK = [System.Windows.Messagebox]::show($MessageBody,$MessageTitle,$ButtonTypeOK)

