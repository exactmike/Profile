    Function Add-ExchangeProxyAddressToTestExchangeProxyAddress {
        
    [cmdletbinding()]
    param
    (
        [string]$ProxyAddress
        ,
        [string]$ObjectGUID #should be the AD ObjectGuid
        ,
        [parameter()]
        [ValidateSet('SMTP', 'X500')]
        [string]$ProxyAddressType = 'SMTP'
    )

    #Fix the ProxyAddress if needed
    if ($ProxyAddress -notlike "{$proxyaddresstype}:*")
    {
        $ProxyAddress = "${$proxyaddresstype}:$ProxyAddress"
    }
    #Test the Proxy Address
    if ($Script:TestExchangeProxyAddress.ContainsKey($ProxyAddress))
    {
        Write-Log -Message "ProxyAddress $ProxyAddress already exists in the TestExchangeProxyAddress Table" -EntryType Failed
        $false
    }
    else
    {
        $Script:TestExchangeProxyAddress.$ProxyAddress = @()
        $Script:TestExchangeProxyAddress.$ProxyAddress += $ObjectGUID
    }

    }
