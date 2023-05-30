#$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://excas11inf2.corp.gianteagle.com/powershell/ -Credential $LiveCred
#Import-PSSession $Session

#Get-Recipient -ResultSize Unlimited | Where-Object {$_.PrimarySmtpAddress -ne $_.UserPrincipalName} | Select-Object Export-Csv -Path C:\Temp\mismatch.csv -NoTypeInformation

Get-