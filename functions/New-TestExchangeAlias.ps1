    Function New-TestExchangeAlias {
        
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]$ExchangeSession
    )
    $Script:TestExchangeAlias = @{}
    $AllRecipients = Invoke-Command -Session $ExchangeSession -scriptblock {Get-Recipient -ResultSize Unlimited -ErrorAction Stop}
    $RecordCount = $AllRecipients.count
    $cr = 0
    foreach ($r in $AllRecipients)
    {
        $cr++
        $writeProgressParams = @{
            Activity         = 'Processing Recipient Alias for Test-ExchangeAlias.  Building Global Variable which future uses of Test-ExchangeAlias will use unless the -RefreshAliasData parameter is used.'
            Status           = "Record $cr of $RecordCount"
            PercentComplete  = $cr / $RecordCount * 100
            CurrentOperation = "Processing Recipient: $($r.GUID.tostring())"
        }
        Write-Progress @writeProgressParams
        $alias = $r.alias
        if ($Script:TestExchangeAlias.ContainsKey($alias))
        {
            $Script:TestExchangeAlias.$alias += $r.guid.tostring()
        }
        else
        {
            $Script:TestExchangeAlias.$alias = @()
            $Script:TestExchangeAlias.$alias += $r.guid.tostring()
        }
    }
    Write-Progress @writeProgressParams -Completed

    }
