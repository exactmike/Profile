    Function New-TestExchangeProxyAddress {
        
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]$ExchangeSession
    )
    $AllRecipients = Invoke-Command -Session $ExchangeSession -ScriptBlock {Get-Recipient -ResultSize Unlimited -ErrorAction Stop -WarningAction Continue} -ErrorAction Stop -WarningAction Continue
    $RecordCount = $AllRecipients.count
    $cr = 0
    $Script:TestExchangeProxyAddress = @{}
    foreach ($r in $AllRecipients)
    {
        $cr++
        $writeProgressParams = @{
            Activity         = 'Processing Recipient Proxy Addresses for Test-ExchangeProxyAddress.  Building Global Variable which future uses of Test-ExchangeProxyAddress will use unless the -RefreshProxyAddressData parameter is used.'
            Status           = "Record $cr of $RecordCount"
            PercentComplete  = $cr / $RecordCount * 100
            CurrentOperation = "Processing Recipient: $($r.GUID.tostring())"
        }
        Write-Progress @writeProgressParams
        $ProxyAddresses = $r.EmailAddresses
        foreach ($ProxyAddress in $ProxyAddresses)
        {
            if ($Script:TestExchangeProxyAddress.ContainsKey($ProxyAddress))
            {
                $Script:TestExchangeProxyAddress.$ProxyAddress += $r.guid.tostring()
            }
            else
            {
                $Script:TestExchangeProxyAddress.$ProxyAddress = @()
                $Script:TestExchangeProxyAddress.$ProxyAddress += $r.guid.tostring()
            }
        }
    }
    Write-Progress @writeProgressParams -Completed

    }
