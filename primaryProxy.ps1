$groups = @()
$groupsPath = "C:\Temp\groupsout.csv"
$groups = Import-Csv -Path $groupsPath

$groups = $groups | ForEach-Object {
    $displayName = $_.DisplayName
    Get-ADGroup -Filter "DisplayName -like '$displayName'" -Properties ProxyAddresses, Mail, DisplayName |
    Select-Object DistinguishedName, DisplayName, 
    @{n = "proxyAddress"; e = { $_.proxyAddresses -cmatch '^SMTP:' } }
}

foreach ($group in $groups) {
    $prefix = "SMTP:"
    $mail = $group.proxyAddress
    $emailWithoutPrefix = $mail.Substring($prefix.Length)
    Set-ADGroup -Identity $group.DistinguishedName -Replace @{mail = "$emailWithoutPrefix"}
}