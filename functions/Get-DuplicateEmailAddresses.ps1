    Function Get-DuplicateEmailAddresses {
        
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $ExchangeOrganization
    )
    Write-Verbose -Message "Building Exchange Proxy Address Hashtable with New-TestExchangeProxyAddress"
    New-TestExchangeProxyAddress -ExchangeOrganization $ExchangeOrganization
    #$TestExchangeProxyAddress = Get-OneShellVariableValue -Name TestExchangeProxyAddress
    Write-Verbose -Message "Filtering Exchange Proxy Address Hashtable for Addresses Assigned to Multiple Recipients"
    $duplicateAddresses = $TestExchangeProxyAddress.GetEnumerator() | Where-Object -FilterScript {$_.Value.count -gt 1}
    Write-Verbose -Message "Iterating through duplicate addresses and creating output"
    $duplicatnum = 0
    foreach ($dup in $duplicateAddresses)
    {
        $duplicatnum++
        foreach ($val in $dup.value)
        {
            $splat = @{
                cmdlet               = 'get-recipient'
                ExchangeOrganization = $ExchangeOrganization
                ErrorAction          = 'Stop'
                splat                = @{
                    Identity    = $val
                    ErrorAction = 'Stop'
                }#innersplat
            }#outersplat
            try
            {
                $Recipient = Invoke-ExchangeCommand @splat
            }#try
            catch
            {
                $message = "Get-Recipient $val in Exchange Organization $ExchangeOrganization"
                Write-Log -Message $message -EntryType Failed -ErrorLog
            }#catch
            $duplicateobject = [pscustomobject]@{
                DuplicateAddress            = $dup.Name
                DuplicateNumber             = $duplicatnum
                DuplicateRecipientCount     = $dup.Value.Count
                RecipientDN                 = $Recipient.distinguishedName
                RecipientAlias              = $recipient.alias
                RecipientPrimarySMTPAddress = $recipient.primarysmtpaddress
                RecipientGUID               = $Recipient.guid
                RecipientTypeDetails        = $Recipient.RecipientTypeDetails
            }
            $duplicateobject
        }#Foreach
    }

    }
