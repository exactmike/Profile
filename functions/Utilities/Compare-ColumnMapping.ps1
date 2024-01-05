function Compare-ColumnMapping
{
    [cmdletbinding(DefaultParameterSetName = 'HashMap')]
    param(
        [parameter(Mandatory)]
        [psobject[]]$DataSourceSample
        ,
        [parameter(ParameterSetName = 'HashMap',Mandatory)]
        [hashtable]$ColumnMap
        ,
        [parameter(ParameterSetName = 'HashMap',Mandatory)]
        [ValidateSet('Keys','Values')]
        [string]$KeysOrValues
        ,
        [parameter(ParameterSetName = 'Table',Mandatory)]
        [Microsoft.SqlServer.Management.Smo.Table]$Table
    )

    $DSSCompare = @(($DataSourceSample[0] | get-Member -MemberType properties | Sort-Object -Property Name).Name)

    switch ($PSCmdlet.ParameterSetName)
    {
        'HashMap'
        {
            $CMCompare = @($ColumnMap.$($KeysOrValues) | Sort-Object)
        }
        'Table'
        {
            $CMCompare = @($Table.Columns.Name | Sort-Object)
        }
    }

    Compare-Object -ReferenceObject $DSSCompare -DifferenceObject $CMCompare -IncludeEqual -CaseSensitive | Sort-Object -Property InputObject

}