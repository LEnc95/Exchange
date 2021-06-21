<#
PS C:\temp> $oldmbxguid = (Get-Mailbox -Identity Jordan.Kay@gianteagle.com -SoftDeletedMailbox).exchangeguid
PS C:\temp> $oldmbxguid

Guid
----
f85d6b8c-b048-4d04-84aa-525c6ca2f99b


PS C:\temp> $newmbxguid = (Get-Mailbox -identity Jordan.Kay@gianteagle.com).exchangeguid
PS C:\temp> $newmbxguid

Guid
----
f4026498-903c-46ba-b588-771a41ad7d54

PS C:\temp> New-MailboxRestoreRequest -SourceMailbox $oldmbxguid -TargetMailbox $newmbxguid -AllowLegacyDNMismatch
#>
$oldmbxguid = (Get-Mailbox -Identity Jordan.Kay@gianteagle.com -SoftDeletedMailbox).exchangeguid
$oldmbxguid

$newmbxguid = (Get-Mailbox -identity Jordan.Kay@gianteagle.com).exchangeguid
$newmbxguid

New-MailboxRestoreRequest -SourceMailbox $oldmbxguid -TargetMailbox $newmbxguid -AllowLegacyDNMismatch