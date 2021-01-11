#Installs exchange online and updates module on run. 
Set-ExecutionPolicy RemoteSigned -scope CurrentUser
Install-Module -Name ExchangeOnlineManagement -scope CurrentUser
Import-Module ExchangeOnlineManagement; Get-Module ExchangeOnlineManagement
Update-Module -Name ExchangeOnlineManagement
#Uninstall-Module -Name ExchangeOnlineManagement