    Function Get-ADAttributeRangeUpper {
        
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory = $true, ParameterSetName = 'LDAPDisplayName')]
        [string]$LDAPDisplayName
        ,
        [parameter(Mandatory = $true, ParameterSetName = 'CommonName')]
        [string]$CommonName
    )
    $GetADAttributeSchemaParams = @{
        ErrorAction = 'Stop'
        Properties  = 'RangeUpper'
    }
    switch ($PSCmdlet.ParameterSetName)
    {
        'LDAPDisplayName'
        {
            $GetADAttributeSchemaParams.lDAPDisplayName = $LDAPDisplayName
        }
        'CommonName'
        {
            $GetADAttributeSchemaParams.CommonName = $CommonName
        }
    }
    try
    {
        $AttributeSchema = @(Get-ADAttributeSchema @GetADAttributeSchemaParams)
        if ($AttributeSchema.Count -eq 1)
        {
            if ($AttributeSchema[0].RangeUpper -eq $null) {Write-Output -InputObject 'Unlimited'}
            else {Write-Output -InputObject $AttributeSchema[0].RangeUpper}
        }
        else
        {
            Write-Warning -Message 'AD Attribute Not Found'
        }
    }
    catch
    {
        $myerror = $_
        Write-Error $myerror
    }

    }
