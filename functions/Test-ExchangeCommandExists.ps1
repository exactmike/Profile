    Function Test-ExchangeCommandExists {
        
    [cmdletbinding(DefaultParameterSetName = 'Organization')]
    param(
        [parameter(Mandatory, Position = 1)]
        [ValidateScript( {$_ -like '*-*'})]
        [string]$cmdlet
        ,
        [switch]$checkConnection
    )#Param
    DynamicParam
    {
        $Dictionary = New-ExchangeOrganizationDynamicParameter -ParameterSetName 'Organization' -Mandatory
        Write-Output -InputObject $Dictionary
    }#DynamicParam
    begin
    {
        #Dynamic Parameter to Variable Binding
        Set-DynamicParameterVariable -dictionary $Dictionary
        # Bind the dynamic parameter to a friendly variable
        $orgobj = $Script:CurrentOrgAdminProfileSystems |  Where-Object SystemType -eq 'ExchangeOrganizations' | Where-Object {$_.name -eq $ExchangeOrganization}
        $CommandPrefix = $orgobj.CommandPrefix
        if ($checkConnection -eq $true)
        {
            if ((Connect-Exchange -exchangeorganization $ExchangeOrganization) -ne $true)
            {throw ("Connection to Exchange Organization $ExchangeOrganization failed.")}
        }
    }#begin
    Process
    {
        #Build the Command String
        $commandstring = "$($cmdlet.split('-')[0])-$CommandPrefix$($cmdlet.split('-')[1])"

        #Store and Set and Restore ErrorAction Preference; Execute the command String
        Test-CommandExists -command $commandstring
    }#Process

    }
