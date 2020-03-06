Function EXO 
{
    $creds = Get-Credential $env:USERNAME
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $creds -Authentication Basic -AllowRedirection
    try{Import-PSSession $Session
        $chost = [ConsoleColor]::Green 
        write-host ' Connected - Exchange Online  ' -n -f $chost
    }catch{Write-Host "Connection Failed to outlook.office365.com" -ForegroundColor Yellow}    
}

Function EXOP
{
    $creds = Get-Credential $env:USERNAME
    $EXOPSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://excas10inf1.corp.gianteagle.com/PowerShell/ -Authentication Kerberos -Credential $creds
    $chost = [ConsoleColor]::Green
    try{
        Import-PSSession $EXOPSession -AllowClobber
        write-host "Connected - Exchange On-Prem" -n -f $chost
    }
    catch{Write-Host "Connection Failed to excas10inf1.corp.gianteagle.com"}
}

function EXL($username,$param) {
    try{Get-MsolDomain -ErrorAction Stop > $null}
    catch{
            if ($cred -eq $null) {
            $UPN = Get-ADUser $env:USERNAME | select UserPrincipalName
            $cred = Get-Credential $UPN.UserPrincipalName
            }
            Write-Output "Connecting to Office 365..."
            Connect-MsolService -Credential $cred
          }
    if($param -eq $null){Get-MsolUser -SearchString "$username "}
    elseif($param -eq 'mfa' -or $param -eq '2f'){Get-MsolUser -SearchString $username | select -ExpandProperty strongauthenticationmethods}
    else{Get-MsolUser -SearchString $username, $param}
}
