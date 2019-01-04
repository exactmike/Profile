    Function Find-ADContact {
        
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true, valuefrompipeline = $true, valuefrompipelinebypropertyname = $true)]
        [string]$Identity
        ,
        [parameter(Mandatory = $true)]
        [validateset('ProxyAddress', 'Mail', 'Name', 'extensionattribute5', 'extensionattribute11', 'extensionattribute13', 'DistinguishedName', 'CanonicalName', 'ObjectGUID', 'mS-DS-ConsistencyGuid')]
        $IdentityType
        ,

        [switch]$DoNotPreserveLocation #use this switch when you are already running the commands from the correct AD Drive
        ,
        $properties = $ADContactAttributes
        ,
        [switch]$AmbiguousAllowed
        ,
        [switch]$ReportExceptions
    )#param
    DynamicParam
    {
        $NewDynamicParameterParams = @{
            Name        = 'ActiveDirectoryInstance'
            ValidateSet = @($Script:CurrentOrgAdminProfileSystems | Where-Object SystemType -eq 'ActiveDirectoryInstances' | Select-Object -ExpandProperty Name)
            Alias       = @('AD', 'Instance')
            Position    = 2
        }
        $Dictionary = New-DynamicParameter @NewDynamicParameterParams
        Write-Output -InputObject $Dictionary
    }#DynamicParam
    Begin
    {
        #Dynamic Parameter to Variable Binding
        Set-DynamicParameterVariable -dictionary $Dictionary
        $ADInstance = $ActiveDirectoryInstance
        if ($DoNotPreserveLocation -ne $true) {Push-Location -StackName 'Find-ADContact'}
        try
        {
            #Write-Log -Message "Attempting: Set Location to AD Drive $("$ADInstance`:")" -Verbose
            Set-Location -Path $("$ADInstance`:") -ErrorAction Stop
            #Write-Log -Message "Succeeded: Set Location to AD Drive $("$ADInstance`:")" -Verbose
        }#try
        catch
        {
            Write-Log -Message "Succeeded: Set Location to AD Drive $("$ADInstance`:")" -ErrorLog
            Write-Log -Message $_.tostring() -ErrorLog
            $ErrorRecord = New-ErrorRecord -Exception 'System.Exception' -ErrorId ADDriveNotAvailable -ErrorCategory NotSpecified -TargetObject $ADInstance -Message 'Required AD Drive not available'
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        }
        $GetADObjectParams = @{ErrorAction = 'Stop'}
        if ($properties.count -ge 1)
        {
            #Write-Log -Message "Using Property List: $($properties -join ",") with Get-ADObject"
            $GetADObjectParams.Properties = $Properties
        }
        if ($ReportExceptions)
        {
            $Script:LookupADContactNotFound = @()
            $Script:LookupADContactAmbiguous = @()
        }
    }#Begin
    Process
    {
        if ($IdentityType -eq 'mS-DS-ConsistencyGuid')
        {
            $Identity = $Identity -join ' '
        }
        foreach ($ID in $Identity)
        {
            try
            {
                Write-Log -Message "Attempting: Get-ADObject with identifier $ID for Attribute $IdentityType"
                switch ($IdentityType)
                {
                    'ProxyAddress'
                    {
                        #$wildcardID = "*$ID*"
                        $ADContact = @(Get-ADObject -filter {objectclass -eq 'contact' -and proxyaddresses -like $ID} @GetADObjectParams)
                    }
                    'Mail'
                    {
                        $ADContact = @(Get-ADObject -filter {objectclass -eq 'contact' -and Mail -eq $ID}  @GetADObjectParams)
                    }
                    'extensionattribute5'
                    {
                        $ADContact = @(Get-ADObject -filter {objectclass -eq 'contact' -and extensionattribute5 -eq $ID} @GetADObjectParams)
                    }
                    'extensionattribute11'
                    {
                        $ADContact = @(Get-ADObject -filter {objectclass -eq 'contact' -and extensionattribute11 -eq $ID} @GetADObjectParams)
                    }
                    'extensionattribute13'
                    {
                        $ADContact = @(Get-ADObject -filter {objectclass -eq 'contact' -and extensionattribute13 -eq $ID} @GetADObjectParams)
                    }
                    'DistinguishedName'
                    {
                        $ADContact = @(Get-ADObject -filter {objectclass -eq 'contact' -and DistinguishedName -eq $ID} @GetADObjectParams)
                    }
                    'CanonicalName'
                    {
                        $ADContact = @(Get-ADObject -filter {objectclass -eq 'contact' -and CanonicalName -eq $ID} @GetADObjectParams)
                    }
                    'ObjectGUID'
                    {
                        $ADContact = @(Get-ADObject -filter {objectclass -eq 'contact' -and ObjectGUID -eq $ID} @GetADObjectParams)
                    }
                    'mS-DS-ConsistencyGuid'
                    {
                        $ID = [byte[]]$ID.split(' ')
                        $ADContact = @(Get-ADObject -filter {objectclass -eq 'contact' -and mS-DS-ConsistencyGuid -eq $ID} @GetADObjectParams)
                    }
                }#switch
                Write-Log -Message "Succeeded: Get-ADObject with identifier $ID for Attribute $IdentityType"
            }#try
            catch
            {
                Write-Log -Message "FAILED: Get-ADObject with identifier $ID for Attribute $IdentityType" -Verbose -ErrorLog
                Write-Log -Message $_.tostring() -ErrorLog
                if ($ReportExceptions) {$Script:LookupADContactNotFound += $ID}
            }
            switch ($ADContact.Count)
            {
                1
                {
                    $TrimmedADObject = $ADContact | Select-Object -property * -ExcludeProperty Item, PropertyNames, *Properties, PropertyCount
                    Write-Output -InputObject $TrimmedADObject
                }#1
                0
                {
                    if ($ReportExceptions) {$Script:LookupADContactNotFound += $ID}
                }#0
                Default
                {
                    if ($AmbiguousAllowed)
                    {
                        $TrimmedADObject = $ADContact | Select-Object -property * -ExcludeProperty Item, PropertyNames, *Properties, PropertyCount
                        Write-Output -InputObject $TrimmedADObject
                    }
                    else
                    {
                        if ($ReportExceptions) {$Script:LookupADContactAmbiguous += $ID}
                    }
                }#Default
            }#switch
        }#foreach
    }#Process
    end
    {
        if ($ReportExceptions)
        {
            if ($Script:LookupADContactNotFound.count -ge 1)
            {
                Write-Log -Message 'Review logs or OneShell variable $LookupADObjectNotFound for exceptions' -Verbose -ErrorLog
                Write-Log -Message "$($Script:LookupADContactNotFound -join "`n`t")" -ErrorLog
            }#if
            if ($Script:LookupADContactAmbiguous.count -ge 1)
            {
                Write-Log -Message 'Review logs or OneShell variable $LookupADObjectAmbiguous for exceptions' -Verbose -ErrorLog
                Write-Log -Message "$($Script:LookupADContactAmbiguous -join "`n`t")" -ErrorLog
            }#if
        }#if
        if ($DoNotPreserveLocation -ne $true) {Pop-Location -StackName 'Find-ADContact'}#if
    }#end

    }
