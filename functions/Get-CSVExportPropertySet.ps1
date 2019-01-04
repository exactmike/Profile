    Function Get-CSVExportPropertySet {
        
    <#
            .SYNOPSIS
            Creates an array of property definitions to be used with Select-Object to prepare data with multi-valued attributes for export to a flat file such as csv.

            .DESCRIPTION
            From existing input arrays of scalar and multi-valued properties, creates an array of property definitions to be used with Select-Object or Format-Table. Automates the creation of the @{n=name;e={expression}} syntax for the multi-valued properties then outputs the whole list as a single array.

            .PARAMETER  Delimiter
            Used to specify the custom delimiter to be used between multi-valued entries in the multi-valued attributes input array.  Default is "|" if not specified.  Avoid using a "," if exporting data to a csv file later in your pipeline.

            .PARAMETER  MultiValuedAttributes
            An array of attributes from your source data which you expect to contain multiple values.  These will be converted to @{n=[PropertyName];e={$_.$propertyname -join $Delimiter} in the output of the function.

            .PARAMETER  ScalarAttributes
            An array of attributes from your source data which you expect to contain scalar values.  These will be passed through directly in the output of the function.


            .EXAMPLE
            Get-CSVExportPropertySet -Delimiter ';' -MultiValuedAttributes proxyaddresses,memberof -ScalarAttributes userprincipalname,samaccountname,targetaddress,primarysmtpaddress
            Name                           Value
            ----                           -----
            n                              proxyaddresses
            e                              $_.proxyaddresses -join ';'
            n                              memberof
            e                              $_.memberof -join ';'
            userprincipalname
            samaccountname
            targetaddress
            primarysmtpaddress

            .OUTPUTS
            [array]

        #>
    param
    (
        $Delimiter = '|'
        ,
        [string[]]$MultiValuedAttributes
        ,
        [string[]]$ScalarAttributes
        ,
        [switch]$SuppressCommonADProperties
    )
    $ADUserPropertiesToSuppress = @('CanonicalName', 'DistinguishedName')
    $CSVExportPropertySet = @()
    foreach ($mv in $MultiValuedAttributes)
    {
        $ExpressionString = "`$_." + $mv + " -join '$Delimiter'"
        $CSVExportPropertySet +=
        @{
            n = $mv
            e = [scriptblock]::Create($ExpressionString)
        }
    }#foreach
    if ($SuppressCommonADProperties) {$CSVExportPropertySet += ($ScalarAttributes | Where-Object {$ADUserPropertiesToSuppress -notcontains $_})}
    else {$CSVExportPropertySet += $ScalarAttributes}
    $CSVExportPropertySet

    }
