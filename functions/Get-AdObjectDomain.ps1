    Function Get-AdObjectDomain {
        
    [cmdletbinding(DefaultParameterSetName = 'ADObject')]
    param
    (
        [parameter(Mandatory, ParameterSetName = 'ADObject')]
        [ValidateScript( {Test-Member -InputObject $_ -Name CanonicalName})]
        $adobject
        ,
        [parameter(Mandatory, ParameterSetName = 'ExchangeObject')]
        [ValidateScript( {Test-Member -InputObject $_ -Name Identity})]
        $ExchangeObject
    )
    switch ($PSCmdlet.ParameterSetName)
    {
        'ADObject'
        {[string]$domain = $adobject.canonicalname.split('/')[0]}
        'ExchangeObject'
        {[string]$domain = $ExchangeObject.Identity.split('/')[0]}
    }
    $domain

    }
