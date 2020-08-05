#Connect-ExchangeOnline
#Get-MessageTrace 

<#
.SYNOPSIS
Get-DGMemberCounts.ps1 - Get the member count of every distribution group
.DESCRIPTION 
This PowerShell script returns the member count of every distribution group
in the Exchange organization.
.OUTPUTS
Results are output to console and CSV.
.EXAMPLE
.\Get-DGMemberCounts.ps1
Created the report of distribution group member counts.
.NOTES
Written by: Luke Encrapera
Find me on:
* Email:	luke.encrapera@gianteagle.com
* LinkedIn:	https://www.linkedin.com/in/luke-encrapera/
* Github:	https://github.com/LEnc95
* CreatedDate: 7/1/2020
#>

#requires -version 2

[CmdletBinding()]
param ()


#...................................
# Variables
#...................................

$now = Get-Date											#Used for timestamps
$date = $now.ToShortDateString()						#Short date format for email message subject

$report = @()

$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path


#...................................
# Script
#...................................

#Add Exchange 2010 snapin if not already loaded in the PowerShell session
<#
if (Test-Path $env:ExchangeInstallPath\bin\RemoteExchange.ps1)
{
	. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
	Connect-ExchangeServer -auto -AllowClobber
}
else
{
    Write-Warning "Exchange Server management tools are not installed on this computer."
    EXIT
}
#>

#Set scope to entire forest
#Set-ADServerSettings -ViewEntireForest:$true

#Get distribution groups
#$distgroups = @(Get-DistributionGroup -ResultSize Unlimited)

<#
$data = @()
$dls = "Aetos-Eviss", "IS"

foreach ($dl in $dls) {

$data += New-Object -TypeName PSObject -Property @{
Name = $dl
Count = (Get-DistributionGroupMember -Identity $dl | Measure-Object).Count
}
}

$data | Export-Csv -Path mydllist.csv -NoTypeInformation
$report | Export-CSV -Path $myDir\DistributionGroupMemberCounts.csv -NoTypeInformation -Encoding UTF8
#>

<#
Import-Module activedirectory
$data = @()            
Get-ADGroup  -filter 'GroupCategory -eq "Distribution"' -Properties MAIL|             
foreach {            
 $count = (Get-ADGroupMember -Identity $($_.DistinguishedName)).Count            
 if ($count -GT 100){}            
 $data += New-Object -TypeName PSObject -Property @{            
   Name = $($_.Name)            
   EMAIL = $($_.MAIL)            
   MemberCount = $count            
 }             
}            
$data | sort MemberCount -Descending 
#>

#Set scope to entire forest
#Set-ADServerSettings -ViewEntireForest:$true

#Get distribution groups
$distgroups = @(Get-DistributionGroup -ResultSize Unlimited)

#Process each distribution group
foreach ($dg in $distgroups)
{
    $count = @(Get-ADGroupMember -Recursive $dg.DistinguishedName).Count

    $reportObj = New-Object PSObject
    $reportObj | Add-Member NoteProperty -Name "Group Name" -Value $dg.Name
    $reportObj | Add-Member NoteProperty -Name "DN" -Value $dg.distinguishedName
    $reportObj | Add-Member NoteProperty -Name "Manager" -Value $dg.managedby.Name
    $reportObj | Add-Member NoteProperty -Name "Member Count" -Value $count

    Write-Host "$($dg.Name) has $($count) members"

    $report += $reportObj

}

$report | Export-CSV -Path $myDir\DistributionGroupMemberCounts.csv -NoTypeInformation -Encoding UTF8

#...................................
# Finished
#...................................