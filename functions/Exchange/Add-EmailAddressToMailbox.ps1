function Add-EmailAddressToMailbox
{
    <#
.SYNOPSIS
    Adds email address(es) to the emailaddresses attribute of a mailbox
.DESCRIPTION
    Adds email address(es) to the emailaddresses attribute of a mailbox. Preserves all the existing addresses.  Will fail with error if a duplicate address is attempted.
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
        # Email Addres(es) to add to the emailaddresses attribute in Exchange
        [parameter(Mandatory)]
        [string[]]$EmailAddress
    )

    $EmailAddresses = @{
        Add = @()
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