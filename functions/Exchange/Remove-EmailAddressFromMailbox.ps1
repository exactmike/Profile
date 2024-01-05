function Remove-EmailAddressFromMailbox
{
    <#
.SYNOPSIS
    Removes email address(es) from the emailaddresses attribute of a mailbox
.DESCRIPTION
    Removes email address(es) from the emailaddresses attribute of a mailbox. Preserves all the other existing addresses.
.EXAMPLE
    Add-EmailAddressToMailbox -Identity dave@contoso.com -emailaddress @('dave@wingtiptoys.com','dave@woodgrovebank.com')
    Adds the two addresses provided to mailbox dave@contoso.com
#>

    [cmdletbinding(SupportsShouldProcess)]
    param(
        # An identifier for the target mailbox which Set-Mailbox -Identity parameter will accept.
        [parameter(Mandatory)]
        [string]$Identity
        ,
        # Email Addres(es) to remove from the emailaddresses attribute in Exchange
        [parameter(Mandatory)]
        [string[]]$EmailAddress
    )

    $EmailAddresses = @{
        Remove = @()
    }

    foreach ($e in $EmailAddress)
    {
        $EmailAddresses.Add += $e
    }

    $SetMailboxParams = @{
        Identity       = $Identity
        EmailAddresses = $EmailAddresses
    }

    if ($PSCmdlet.ShouldProcess($Identity,"Set-Mailbox -EmailAddresses $($SetMailboxParams.EmailAddresses | ConvertTo-JSON -Compress)"))
    {
        Set-Mailbox @SetMailboxParams
    }
}
