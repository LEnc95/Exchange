# Activate Echange Admin to remove MSOL group. 
Enable-DCAzureADPIMRole -RolesToActivate "Global Administrator" -Reason "Script removal of mail enabled objects with 50+ members" -UseMaximumTimeAllowed

# Connect to Exchange Online (Exchange Online PowerShell module required)
Connect-ExchangeOnline 
Connect-MsolService

# Get all mail-enabled security and distribution groups with over 50 members
# $groups = Get-DistributionGroup -ResultSize Unlimited | Where-Object { $_.RecipientTypeDetails -eq 'MailUniversalSecurityGroup' -or $_.RecipientTypeDetails -eq 'MailUniversalDistributionGroup' -and $_.MemberCount -gt 50 }
$groups = 'MIM_App_GEAC_CMA_User','MIM_APP_MWG_CorpOfficer','MIM_APP_MWG_Managers','MIM_App_SOP_Adjustments'
$groups = $groups | ForEach-Object {Get-DistributionGroup -Identity $_ | Select-Object DisplayName, ExternalDirectoryObjectId, DistinguishedName}

foreach ($group in $groups) {
    # Step 1: Clear the mail attribute of the group
    Set-ADGroup -Identity $group.DisplayName -Clear 'mail'

    # Step 2: Remove the group from Exchange Online
    Remove-MsolGroup -ObjectId $group.ExternalDirectoryObjectId -Force

    Write-Host "Disabled and removed mail attributes for group: $($group.DisplayName)"
}

