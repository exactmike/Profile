    Function Test-ExchangeProxyAddress {
        
    [cmdletbinding()]
    param
    (
        [string]$ProxyAddress
        ,
        [string[]]$ExemptObjectGUIDs
        ,
        [switch]$ReturnConflicts
        ,
        [parameter()]
        [System.Management.Automation.Runspaces.PSSession]$ExchangeSession
        ,
        [parameter()]
        [ValidateSet('SMTP', 'X500')]
        [string]$ProxyAddressType = 'SMTP'
    )
    #Populate the Global TestExchangeProxyAddress Hash Table if needed
    <# if (Test-Path -Path variable:Script:TestExchangeProxyAddress)
            {
                if ($RefreshProxyAddressData)
                {
                    if ($null -eq $ExchangeSession)
                    {
                        throw('You must include the Exchange Session to use the RefreshProxyAddressData switch')
                    }
                    Write-Log -message 'Running New-TestExchangeProxyAddress'
                    New-TestExchangeProxyAddress -ExchangeSession $ExchangeSession
                }
            }
            else
            {
                Write-Log -message 'Running New-TestExchangeProxyAddress'
                New-TestExchangeProxyAddress -ExchangeSession $ExchangeSession
            }
        #>

    #Fix the ProxyAddress if needed
    if ($ProxyAddress -like "$($proxyaddresstype):*")
    {
        $ProxyAddress = $ProxyAddress.Split(':')[1]
    }
    #Test the ProxyAddress
    $ReturnedObjects = @(
        try
        {
            invoke-command -Session $ExchangeSession -ScriptBlock {Get-Recipient -identity $using:ProxyAddress -ErrorAction Stop} -ErrorAction Stop
            Write-Verbose -Message "Existing object(s) Found for Alias $ProxyAddress"
        }
        catch
        {
            if ($_.categoryinfo -like '*ManagementObjectNotFoundException*')
            {
                Write-Verbose -Message "No existing object(s) Found for Alias $ProxyAddress"
            }
            else
            {
                throw($_)
            }
        }
    )
    if ($ReturnedObjects.Count -ge 1)
    {
        $ConflictingGUIDs = @($ReturnedObjects | ForEach-Object {$_.guid.guid} | Where-Object {$_ -notin $ExemptObjectGUIDs})
        if ($ConflictingGUIDs.count -gt 0)
        {
            if ($ReturnConflicts)
            {
                Return $ConflictingGUIDs
            }
            else
            {
                $false
            }
        }
        else
        {
            $true
        }
    }
    else
    {
        $true
    }

    }
