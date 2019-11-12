    Function Get-ADAttributeSchema {
        
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory = $true, ParameterSetName = 'LDAPDisplayName')]
        [string]$LDAPDisplayName
        ,
        [parameter(Mandatory = $true, ParameterSetName = 'CommonName')]
        [string]$CommonName
        ,
        [string[]]$properties = @()
    )
    if (-not ((Test-ForInstalledModule -Name ActiveDirectory) -and (Test-ForImportedModule -Name ActiveDirectory)))
    {throw "Module ActiveDirectory must be installed and imported to use $($MyInvocation.MyCommand)."}
    if ((Get-ADDrive).count -lt 1) {throw "An ActiveDirectory PSDrive must be connected to use $($MyInvocation.MyCommand)."}
    try
    {
        if (-not (Test-Path -path variable:script:LoggedOnUserActiveDirectoryForest))
        {$script:LoggedOnUserActiveDirectoryForest = Get-ADForest -Current LoggedOnUser -ErrorAction Stop}
    }
    catch
    {
        $_
        throw 'Could not find AD Forest'
    }
    $schemalocation = "CN=Schema,$($script:LoggedOnUserActiveDirectoryForest.PartitionsContainer.split(',',2)[1])"
    $GetADObjectParams = @{
        ErrorAction = 'Stop'
    }
    if ($properties.count -ge 1) {$GetADObjectParams.Properties = $properties}
    switch ($PSCmdlet.ParameterSetName)
    {
        'LDAPDisplayName'
        {
            $GetADObjectParams.Filter = "lDAPDisplayName -eq `'$LDAPDisplayName`'"
            $GetADObjectParams.SearchBase = $schemalocation
        }
        'CommonName'
        {
            $GetADObjectParams.Identity = "CN=$CommonName,$schemalocation"
        }
    }
    try
    {
        $ADObjects = @(Get-ADObject @GetADObjectParams)
        if ($ADObjects.Count -eq 0)
        {Write-Warning -Message "Failed: Find AD Attribute with name/Identifier: $($LDAPDisplayName,$GetADObjectParams.Identity)"}
        else
        {
            Write-Output -InputObject $ADObjects[0]
        }
    }
    catch
    {
    }

    }
