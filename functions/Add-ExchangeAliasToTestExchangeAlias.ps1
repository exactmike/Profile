    Function Add-ExchangeAliasToTestExchangeAlias {
        
    [cmdletbinding()]
    param
    (
        [string]$Alias
        ,
        [string[]]$ObjectGUID #should be the AD ObjectGuid
    )
    if ($Script:TestExchangeAlias.ContainsKey($alias))
    {
        throw("Alias $Alias already exists in the TestExchangeAlias Table")
    }
    else
    {
        $Script:TestExchangeAlias.$alias = @()
        $Script:TestExchangeAlias.$alias += $ObjectGUID
    }

    }
