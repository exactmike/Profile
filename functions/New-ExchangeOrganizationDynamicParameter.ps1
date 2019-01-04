    Function New-ExchangeOrganizationDynamicParameter {
        
    [cmdletbinding()]
    param
    (
        [switch]$Mandatory
        ,
        [int]$Position
        ,
        [string]$ParameterSetName
        ,
        [switch]$Multivalued
    )
    $NewDynamicParameterParams = @{
        Name        = 'ExchangeOrganization'
        ValidateSet = @(
            Get-OneShellAvailableSystem -ServiceType ExchangeOnPremises, ExchangeOnline, ExchangeComplianceCenter |
                ForEach-Object -Process {$_.Name; $_.Identity} | Sort-Object
        )
    }
    if ($PSBoundParameters.ContainsKey('Mandatory'))
    {
        $NewDynamicParameterParams.Mandatory = $true
    }
    if ($PSBoundParameters.ContainsKey('Multivalued'))
    {
        $NewDynamicParameterParams.Type = [string[]]
    }
    if ($PSBoundParameters.ContainsKey('Position'))
    {
        $NewDynamicParameterParams.Position = $Position
    }
    if ($PSBoundParameters.ContainsKey('ParameterSetName'))
    {
        $NewDynamicParameterParams.ParameterSetName = $ParameterSetName
    }
    New-DynamicParameter @NewDynamicParameterParams

    }
