$dl = Get-DistributionGroup -ResultSize Unlimited
$dl | Export-CSV -Path $myDir\DistributionGroup.csv -NoTypeInformation -Encoding UTF8