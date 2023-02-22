[cmdletbinding()]
param(
    [parameter(Mandatory)]
    [validatescript( { Test-Path -Path $_ -type Leaf })]
    $InputFilePath
)

$MailboxesToModify = @(Import-Csv -Path $InputFilePath)

foreach ($m in $MailboxesToModify)
{
    $RemoveAddresses = $m.NonAcceptedEmails.split(';')
    Set-Mailbox -Identity $m.ExchangeGUID -EmailAddresses @{remove = $RemoveAddresses }
}