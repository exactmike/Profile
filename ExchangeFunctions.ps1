##########################################################################################################
#Exchange Related Functions
##########################################################################################################
function New-ExchangeOrganizationDynamicParameter
{
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
#end function New-ExchangeOrganizationDynamicParameter
function Get-RecipientCmdlet
{
    [cmdletbinding()]
    param
    (
        [parameter(ParameterSetName = 'RecipientObject')]
        [psobject]$Recipient
        ,
        [parameter(ParametersetName = 'IdentityString')]
        [string]$Identity
        ,
        [parameter(Mandatory = $true)]
        [ValidateSet('Set', 'Get', 'Remove', 'Disable')]
        $verb
        ,
        [parameter(ParameterSetName = 'IdentityString')]
        $ExchangeSession
    )
    switch ($PSCmdlet.ParameterSetName)
    {
        'RecipientObject'
        {
            #add some code to validate the object
        }
        'IdentityString'
        {
            #get the recipient object
            $Recipient = Invoke-Command -Session $ExchangeSession -ScriptBlock {Get-Recipient -Identity $using:Identity -ErrorAction Stop} -ErrorAction Stop
        }
    }#switch ParameterSetName
    #Return the cmdlet based on recipient type and requested verb
    switch ($verb)
    {
        'Get'
        {
            switch ($Recipient.recipienttypedetails)
            {
                'LinkedMailbox' {$cmdlet = 'Get-Mailbox'}
                'RemoteRoomMailbox' {$cmdlet = 'Get-RemoteMailbox'}
                'RemoteSharedMailbox' {$cmdlet = 'Get-RemoteMailbox'}
                'RemoteUserMailbox' {$cmdlet = 'Get-RemoteMailbox'}
                'RemoteEquipmentMailbox' {$cmdlet = 'Get-RemoteMailbox'}
                'RoomMailbox' {$cmdlet = 'Get-Mailbox'}
                'SharedMailbox' {$cmdlet = 'Get-Mailbox'}
                'DiscoveryMailbox' {$cmdlet = 'Get-Mailbox'}
                'ArbitrationMailbox' {$cmdlet = 'Get-Mailbox'}
                'UserMailbox' {$cmdlet = 'Get-Mailbox'}
                'LegacyMailbox' {$cmdlet = 'Get-Mailbox'}
                'EquipmentMailbox' {$cmdlet = 'Get-Mailbox'}
                'MailContact' {$cmdlet = 'Get-MailContact'}
                'MailForestContact' {$cmdlet = 'Get-MailContact'}
                'MailUser' {$cmdlet = 'Get-MailUser'}
                'MailUniversalDistributionGroup' {$cmdlet = 'Get-DistributionGroup'}
                'MailUniversalSecurityGroup' {$cmdlet = 'Get-DistributionGroup'}
                'DynamicDistributionGroup' {$cmdlet = 'Get-DynamicDistributionGroup'}
                'PublicFolder' {$cmdlet = 'Get-MailPublicFolder'}
            }#switch RecipientTypeDetails
        }#Get
        'Set'
        {
            switch ($Recipient.recipienttypedetails)
            {
                'LinkedMailbox' {$cmdlet = 'Set-Mailbox'}
                'RemoteRoomMailbox' {$cmdlet = 'Set-RemoteMailbox'}
                'RemoteSharedMailbox' {$cmdlet = 'Set-RemoteMailbox'}
                'RemoteUserMailbox' {$cmdlet = 'Set-RemoteMailbox'}
                'RemoteEquipmentMailbox' {$cmdlet = 'Set-RemoteMailbox'}
                'RoomMailbox' {$cmdlet = 'Set-Mailbox'}
                'SharedMailbox' {$cmdlet = 'Set-Mailbox'}
                'DiscoveryMailbox' {$cmdlet = 'Set-Mailbox'}
                'ArbitrationMailbox' {$cmdlet = 'Set-Mailbox'}
                'UserMailbox' {$cmdlet = 'Set-Mailbox'}
                'LegacyMailbox' {$cmdlet = 'Set-Mailbox'}
                'EquipmentMailbox' {$cmdlet = 'Set-Mailbox'}
                'MailContact' {$cmdlet = 'Set-MailContact'}
                'MailForestContact' {$cmdlet = 'Set-MailContact'}
                'MailUser' {$cmdlet = 'Set-MailUser'}
                'MailUniversalDistributionGroup' {$cmdlet = 'Set-DistributionGroup'}
                'MailUniversalSecurityGroup' {$cmdlet = 'Set-DistributionGroup'}
                'DynamicDistributionGroup' {$cmdlet = 'Set-DynamicDistributionGroup'}
                'PublicFolder' {$cmdlet = 'Set-MailPublicFolder'}
            }#switch RecipientTypeDetails
        }
        'Remove'
        {
            switch ($Recipient.recipienttypedetails)
            {
                'LinkedMailbox' {$cmdlet = 'Remove-Mailbox'}
                'RemoteRoomMailbox' {$cmdlet = 'Remove-RemoteMailbox'}
                'RemoteSharedMailbox' {$cmdlet = 'Remove-RemoteMailbox'}
                'RemoteUserMailbox' {$cmdlet = 'Remove-RemoteMailbox'}
                'RemoteEquipmentMailbox' {$cmdlet = 'Remove-RemoteMailbox'}
                'RoomMailbox' {$cmdlet = 'Remove-Mailbox'}
                'SharedMailbox' {$cmdlet = 'Remove-Mailbox'}
                'DiscoveryMailbox' {$cmdlet = 'Remove-Mailbox'}
                'ArbitrationMailbox' {$cmdlet = 'Remove-Mailbox'}
                'UserMailbox' {$cmdlet = 'Remove-Mailbox'}
                'LegacyMailbox' {$cmdlet = 'Remove-Mailbox'}
                'EquipmentMailbox' {$cmdlet = 'Remove-Mailbox'}
                'MailContact' {$cmdlet = 'Remove-MailContact'}
                'MailForestContact' {$cmdlet = 'Remove-MailContact'}
                'MailUser' {$cmdlet = 'Remove-MailUser'}
                'MailUniversalDistributionGroup' {$cmdlet = 'Remove-DistributionGroup'}
                'MailUniversalSecurityGroup' {$cmdlet = 'Remove-DistributionGroup'}
                'DynamicDistributionGroup' {throw 'No Remove Cmdlet for DynamicDistributionGroup. Use Disable instead.'}
                'PublicFolder' {throw 'No Remove Cmdlet for MailPublicFolder. Use Disable instead.'}
            }#switch RecipientTypeDetails
        }
        'Disable'
        {
            switch ($Recipient.recipienttypedetails)
            {
                'LinkedMailbox' {$cmdlet = 'Disable-Mailbox'}
                'RemoteRoomMailbox' {$cmdlet = 'Disable-RemoteMailbox'}
                'RemoteSharedMailbox' {$cmdlet = 'Disable-RemoteMailbox'}
                'RemoteUserMailbox' {$cmdlet = 'Disable-RemoteMailbox'}
                'RemoteEquipmentMailbox' {$cmdlet = 'Disable-RemoteMailbox'}
                'RoomMailbox' {$cmdlet = 'Disable-Mailbox'}
                'SharedMailbox' {$cmdlet = 'Disable-Mailbox'}
                'DiscoveryMailbox' {$cmdlet = 'Disable-Mailbox'}
                'ArbitrationMailbox' {$cmdlet = 'Disable-Mailbox'}
                'UserMailbox' {$cmdlet = 'Disable-Mailbox'}
                'LegacyMailbox' {$cmdlet = 'Disable-Mailbox'}
                'EquipmentMailbox' {$cmdlet = 'Disable-Mailbox'}
                'MailContact' {$cmdlet = 'Disable-MailContact'}
                'MailForestContact' {$cmdlet = 'Disable-MailContact'}
                'MailUser' {$cmdlet = 'Disable-MailUser'}
                'MailUniversalDistributionGroup' {$cmdlet = 'Disable-DistributionGroup'}
                'MailUniversalSecurityGroup' {$cmdlet = 'Disable-DistributionGroup'}
                'DynamicDistributionGroup' {$cmdlet = 'Disable-DynamicDistributionGroup'}
                'PublicFolder' {$cmdlet = 'Disable-MailPublicFolder'}
            }#switch RecipientTypeDetails
        }
    }#switch Verb
    $cmdlet
}
#end function Get-RecipientCmdlet
function Find-PrimarySMTPAddress
{
    [cmdletbinding()]
    Param
    (
        [parameter(mandatory = $true)]
        [Alias('EmailAddresses')]
        [string[]]$ProxyAddresses
    )
    $PrimaryAddresses = @($ProxyAddresses | Where-Object {$_ -clike 'SMTP:*'} | ForEach-Object {($_ -split ':')[1]})
    switch ($PrimaryAddresses.count)
    {
        1
        {
            $PrimarySMTPAddress = $PrimaryAddresses[0]
            $PrimarySMTPAddress
        }#1
        0
        {
            $null
        }#0
        Default
        {
            $false
        }#Default
    }#switch
}
#end function Find-PrimarySMTPAddress
function New-TestExchangeAlias
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]$ExchangeSession
    )
    $Script:TestExchangeAlias = @{}
    $AllRecipients = Invoke-Command -Session $ExchangeSession -scriptblock {Get-Recipient -ResultSize Unlimited -ErrorAction Stop}
    $RecordCount = $AllRecipients.count
    $cr = 0
    foreach ($r in $AllRecipients)
    {
        $cr++
        $writeProgressParams = @{
            Activity         = 'Processing Recipient Alias for Test-ExchangeAlias.  Building Global Variable which future uses of Test-ExchangeAlias will use unless the -RefreshAliasData parameter is used.'
            Status           = "Record $cr of $RecordCount"
            PercentComplete  = $cr / $RecordCount * 100
            CurrentOperation = "Processing Recipient: $($r.GUID.tostring())"
        }
        Write-Progress @writeProgressParams
        $alias = $r.alias
        if ($Script:TestExchangeAlias.ContainsKey($alias))
        {
            $Script:TestExchangeAlias.$alias += $r.guid.tostring()
        }
        else
        {
            $Script:TestExchangeAlias.$alias = @()
            $Script:TestExchangeAlias.$alias += $r.guid.tostring()
        }
    }
    Write-Progress @writeProgressParams -Completed
}
#end function New-TestExchangeAlias
Function Test-ExchangeAlias
{
    [cmdletbinding()]
    param(
        [string]$Alias
        ,
        [string[]]$ExemptObjectGUIDs
        ,
        [switch]$ReturnConflicts
        ,
        [parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]$ExchangeSession
    )

    #Test the Alias
    $ReturnedObjects = @(
        try
        {
            invoke-command -Session $ExchangeSession -ScriptBlock {Get-Recipient -identity $using:Alias -ErrorAction Stop} -ErrorAction Stop
            Write-Verbose -Message "Existing object(s) Found for Alias $Alias"
        }
        catch
        {
            if ($_.categoryinfo -like '*ManagementObjectNotFoundException*')
            {
                Write-Verbose -Message "No existing object(s) Found for Alias $Alias"
            }
            else
            {
                throw($_)
            }
        }
    )
    if ($ReturnedObjects.Count -ge 1)
    {
        $ConflictingGUIDs = @($ReturnedObjects | ForEach-Object {$_.guid.guid} | Where-Object {$_ -notin $ExemptObjectGUIDs})
        if ($ConflictingGUIDs.count -gt 0)
        {
            if ($ReturnConflicts)
            {
                Return $ConflictingGUIDs
            }
            else
            {
                $false
            }
        }
        else
        {
            $true
        }
    }
    else
    {
        $true
    }
}
#end function Test-ExchangeAlias
Function Add-ExchangeAliasToTestExchangeAlias
{
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
#end function Add-ExchangeAliasToTestExchangeAlias
function New-TestExchangeProxyAddress
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]$ExchangeSession
    )
    $AllRecipients = Invoke-Command -Session $ExchangeSession -ScriptBlock {Get-Recipient -ResultSize Unlimited -ErrorAction Stop -WarningAction Continue} -ErrorAction Stop -WarningAction Continue
    $RecordCount = $AllRecipients.count
    $cr = 0
    $Script:TestExchangeProxyAddress = @{}
    foreach ($r in $AllRecipients)
    {
        $cr++
        $writeProgressParams = @{
            Activity         = 'Processing Recipient Proxy Addresses for Test-ExchangeProxyAddress.  Building Global Variable which future uses of Test-ExchangeProxyAddress will use unless the -RefreshProxyAddressData parameter is used.'
            Status           = "Record $cr of $RecordCount"
            PercentComplete  = $cr / $RecordCount * 100
            CurrentOperation = "Processing Recipient: $($r.GUID.tostring())"
        }
        Write-Progress @writeProgressParams
        $ProxyAddresses = $r.EmailAddresses
        foreach ($ProxyAddress in $ProxyAddresses)
        {
            if ($Script:TestExchangeProxyAddress.ContainsKey($ProxyAddress))
            {
                $Script:TestExchangeProxyAddress.$ProxyAddress += $r.guid.tostring()
            }
            else
            {
                $Script:TestExchangeProxyAddress.$ProxyAddress = @()
                $Script:TestExchangeProxyAddress.$ProxyAddress += $r.guid.tostring()
            }
        }
    }
    Write-Progress @writeProgressParams -Completed
}
#end function New-TestExchangeProxyAddress
Function Test-ExchangeProxyAddress
{
    [cmdletbinding()]
    param
    (
        [string]$ProxyAddress
        ,
        [string[]]$ExemptObjectGUIDs
        ,
        [switch]$ReturnConflicts
        ,
        [parameter()]
        [System.Management.Automation.Runspaces.PSSession]$ExchangeSession
        ,
        [parameter()]
        [ValidateSet('SMTP', 'X500')]
        [string]$ProxyAddressType = 'SMTP'
    )
    #Populate the Global TestExchangeProxyAddress Hash Table if needed
    <# if (Test-Path -Path variable:Script:TestExchangeProxyAddress)
            {
                if ($RefreshProxyAddressData)
                {
                    if ($null -eq $ExchangeSession)
                    {
                        throw('You must include the Exchange Session to use the RefreshProxyAddressData switch')
                    }
                    Write-Log -message 'Running New-TestExchangeProxyAddress'
                    New-TestExchangeProxyAddress -ExchangeSession $ExchangeSession
                }
            }
            else
            {
                Write-Log -message 'Running New-TestExchangeProxyAddress'
                New-TestExchangeProxyAddress -ExchangeSession $ExchangeSession
            }
        #>

    #Fix the ProxyAddress if needed
    if ($ProxyAddress -like "$($proxyaddresstype):*")
    {
        $ProxyAddress = $ProxyAddress.Split(':')[1]
    }
    #Test the ProxyAddress
    $ReturnedObjects = @(
        try
        {
            invoke-command -Session $ExchangeSession -ScriptBlock {Get-Recipient -identity $using:ProxyAddress -ErrorAction Stop} -ErrorAction Stop
            Write-Verbose -Message "Existing object(s) Found for Alias $ProxyAddress"
        }
        catch
        {
            if ($_.categoryinfo -like '*ManagementObjectNotFoundException*')
            {
                Write-Verbose -Message "No existing object(s) Found for Alias $ProxyAddress"
            }
            else
            {
                throw($_)
            }
        }
    )
    if ($ReturnedObjects.Count -ge 1)
    {
        $ConflictingGUIDs = @($ReturnedObjects | ForEach-Object {$_.guid.guid} | Where-Object {$_ -notin $ExemptObjectGUIDs})
        if ($ConflictingGUIDs.count -gt 0)
        {
            if ($ReturnConflicts)
            {
                Return $ConflictingGUIDs
            }
            else
            {
                $false
            }
        }
        else
        {
            $true
        }
    }
    else
    {
        $true
    }
}
#end function Test-ExchangeProxyAddress
Function Add-ExchangeProxyAddressToTestExchangeProxyAddress
{
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
#end function Add-ExchangeProxyAddressToTestExchangeProxyAddress
function Test-RecipientObjectForUnwantedSMTPAddresses
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$WantedDomains
        ,
        [Parameter(Mandatory)]
        [ValidateScript( {($_ | Test-Member -name 'EmailAddresses') -or ($_ | Test-Member -name 'ProxyAddresses')})]
        [psobject[]]$Recipient
        ,
        [Parameter()]
        [ValidateSet('ReportUnwanted', 'ReportAll', 'TestOnly')]
        [string]$Operation = 'TestOnly'
        ,
        [bool]$ValidateSMTPAddress = $true
    )
    foreach ($R in $Recipient)
    {
        Switch ($R)
        {
            {$R | Test-Member -Name 'EmailAddresses'}
            {$AddrAtt = 'EmailAddresses'}
            {$R | Test-Member -Name 'ProxyAddresses'}
            {$AddrAtt = 'ProxyAddresses'}
        }
        $Addresses = @($R.$addrAtt)
        $TestedAddresses = @(
            foreach ($A in $Addresses)
            {
                if ($A -like 'smtp:*')
                {
                    $RawA = $A.split(':')[1]
                    $ADomain = $RawA.split('@')[1]
                    $IsSupportedDomain = $ADomain -in $WantedDomains
                    $outputRecord =
                    [pscustomobject]@{
                        DistinguishedName  = $R.DistinguishedName
                        Identity           = $R.Identity
                        Address            = $RawA
                        Domain             = $ADomain
                        IsSupportedDomain  = $IsSupportedDomain
                        IsValidSMTPAddress = $null
                    }
                    if ($ValidateSMTPAddress)
                    {
                        $IsValidSMTPAddress = Test-EmailAddress -EmailAddress $RawA
                        $outputRecord.IsValidSMTPAddress = $IsValidSMTPAddress
                    }
                }
                $outputRecord
            }
        )
        switch ($Operation)
        {
            'TestOnly'
            {
                if ($TestedAddresses.IsSupportedDomain -contains $false -or $TestedAddresses.IsValidSMTPAddress -contains $false)
                {$false}
                else
                {$true}
            }
            'ReportUnwanted'
            {
                $UnwantedAddresses = @($TestedAddresses | Where-Object -FilterScript {$_.IsSupportedDomain -eq $false -or $_.IsValidSMTPAddress -eq $false})
                if ($UnwantedAddresses.Count -ge 1)
                {
                    $UnwantedAddresses
                }
            }
            'ReportAll'
            {
                $TestedAddresses
            }
        }
    }#foreach R in Recipient
}
#end function Test-RecipientObjectForUnwantedSMTPAddresses

######################################################
#Need Updates
######################################################
function Get-DuplicateEmailAddresses
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $ExchangeOrganization
    )
    Write-Verbose -Message "Building Exchange Proxy Address Hashtable with New-TestExchangeProxyAddress"
    New-TestExchangeProxyAddress -ExchangeOrganization $ExchangeOrganization
    #$TestExchangeProxyAddress = Get-OneShellVariableValue -Name TestExchangeProxyAddress
    Write-Verbose -Message "Filtering Exchange Proxy Address Hashtable for Addresses Assigned to Multiple Recipients"
    $duplicateAddresses = $TestExchangeProxyAddress.GetEnumerator() | Where-Object -FilterScript {$_.Value.count -gt 1}
    Write-Verbose -Message "Iterating through duplicate addresses and creating output"
    $duplicatnum = 0
    foreach ($dup in $duplicateAddresses)
    {
        $duplicatnum++
        foreach ($val in $dup.value)
        {
            $splat = @{
                cmdlet               = 'get-recipient'
                ExchangeOrganization = $ExchangeOrganization
                ErrorAction          = 'Stop'
                splat                = @{
                    Identity    = $val
                    ErrorAction = 'Stop'
                }#innersplat
            }#outersplat
            try
            {
                $Recipient = Invoke-ExchangeCommand @splat
            }#try
            catch
            {
                $message = "Get-Recipient $val in Exchange Organization $ExchangeOrganization"
                Write-Log -Message $message -EntryType Failed -ErrorLog
            }#catch
            $duplicateobject = [pscustomobject]@{
                DuplicateAddress            = $dup.Name
                DuplicateNumber             = $duplicatnum
                DuplicateRecipientCount     = $dup.Value.Count
                RecipientDN                 = $Recipient.distinguishedName
                RecipientAlias              = $recipient.alias
                RecipientPrimarySMTPAddress = $recipient.primarysmtpaddress
                RecipientGUID               = $Recipient.guid
                RecipientTypeDetails        = $Recipient.RecipientTypeDetails
            }
            $duplicateobject
        }#Foreach
    }
}
#end function Get-DuplicateEmailAddresses
function Get-ExchangeRecipient
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Identity
        ,
        [parameter(Mandatory)]
        [System.Management.Automation.Runspaces.PSSession[]]$ExchangeSession
    )
    DynamicParam
    {
        $dictionary = New-ExchangeOrganizationDynamicParameter -Mandatory -Multivalued
        $dictionary
    }
    begin
    {
        #Test the ExchangeSession(s)
    }
    process
    {
        foreach ($id in $Identity)
        {
            $InvokeCommandParams = @{
                #ErrorAction = 'Stop'
                WarningAction = 'SilentlyContinue'
                ErrorAction   = 'Continue'
                scriptblock   = [scriptblock] {Get-Recipient -Identity $id -WarningAction SilentlyContinue -ErrorAction Continue}
                Cmdlet        = 'Get-Recipient'
            }
            foreach ($s in $ExchangeSession)
            {
                $InvokeCommandParams.Session = $s
                Invoke-Command @InvokeCommandParams
            }
        }
    }#process
}
#end function Get-ExchangeRecipient

function Test-ExchangeCommandExists
{
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
#End Function Test-ExchangeCommandExists

function Convert-MailboxToMailUser
{
    [cmdletbinding(SupportsShouldProcess)]
    param
    (
        [parameter(Mandatory)]
        $Identity
        ,
        [parameter(Mandatory)]
        $ExchangeOrganization
    )
    $ExchangeSystem = Get-OneShellSystem -identity $ExchangeOrganization -ErrorAction Stop
    Connect-OneShellSystem -Identity $ExchangeOrganization -ErrorAction Stop
    $ExchangeSession = Get-OneShellSystemPSSession -identity $ExchangeOrganization -ErrorAction Stop

    $OriginalMailbox = Invoke-Command -Session $ExchangeSession -ScriptBlock {Get-Mailbox -identity $using:Identity -erroraction Stop} -ErrorAction Stop
    #Build Intermediate MEU object
    $MailUserObject = [PSCustomObject]@{
        Identity = $OriginalMailbox.guid.guid
        Alias = $OriginalMailbox.Alias
        DisplayName = $OriginalMailbox.DisplayName
        PrimarySMTPAddress = $OriginalMailbox.PrimarySMTPAddress
        ExternalEmailAddress = $OriginalMailbox.ForwardingSmtpAddress
        EmailAddresses = Get-DesiredProxyAddresses -DesiredOrCurrentAlias $OriginalMailbox.Alias -LegacyExchangeDNs $OriginalMailbox.LegacyExchangeDN  -CurrentProxyAddresses $OriginalMailbox.EmailAddresses
        AcceptMessagesOnlyFrom = $OriginalMailbox.AcceptMessagesOnlyFrom
        BypassModerationFromSendersOrMembers = $OriginalMailbox.BypassModerationFromSendersOrMembers
        CustomAttribute1 = $OriginalMailbox.CustomAttribute1
        CustomAttribute2 = $OriginalMailbox.CustomAttribute2
        CustomAttribute3 = $OriginalMailbox.CustomAttribute3
        CustomAttribute4 = $OriginalMailbox.CustomAttribute4
        CustomAttribute5 = $OriginalMailbox.CustomAttribute5
        CustomAttribute6 = $OriginalMailbox.CustomAttribute6
        CustomAttribute7 = $OriginalMailbox.CustomAttribute7
        CustomAttribute8 = $OriginalMailbox.CustomAttribute8
        CustomAttribute9 = $OriginalMailbox.CustomAttribute9
        CustomAttribute10 = $OriginalMailbox.CustomAttribute10
        CustomAttribute11 = $OriginalMailbox.CustomAttribute11
        CustomAttribute12 = $OriginalMailbox.CustomAttribute12
        CustomAttribute13 = $OriginalMailbox.CustomAttribute13
        CustomAttribute14 = $OriginalMailbox.CustomAttribute14
        CustomAttribute15 = $OriginalMailbox.CustomAttribute15
        ExtensionCustomAttribute1 = $OriginalMailbox.ExtensionCustomAttribute1
        ExtensionCustomAttribute2 = $OriginalMailbox.ExtensionCustomAttribute2
        ExtensionCustomAttribute3 = $OriginalMailbox.ExtensionCustomAttribute3
        ExtensionCustomAttribute4 = $OriginalMailbox.ExtensionCustomAttribute4
        ExtensionCustomAttribute5 = $OriginalMailbox.ExtensionCustomAttribute5
        ExchangeGUID = $OriginalMailbox.ExchangeGUID
        GrantSendOnBehalfTo = $OriginalMailbox.GrantSendOnBehalfTo
        HiddenFromAddressListsEnabled = $OriginalMailbox.HiddenFromAddressListsEnabled
        MailTip = $OriginalMailbox.MailTip
        MailTipTranslations = $OriginalMailbox.MailTipTranslations
        MaxReceiveSize = $OriginalMailbox.MaxReceiveSize
        MaxSendSize = $OriginalMailbox.MaxSendSize
        ModeratedBy = $OriginalMailbox.ModeratedBy
        ModerationEnabled = $OriginalMailbox.ModerationEnabled
        Name = $OriginalMailbox.Name
        RecipientLimits = $OriginalMailbox.RecipientLimits
        RejectMessagesFrom = $OriginalMailbox.RejectMessagesFrom
        RequireSenderAuthenticationEnabled = $OriginalMailbox.RequireSenderAuthenticationEnabled
        SimpleDisplayName = $OriginalMailbox.SimpleDisplayName
        UsageLocation = $OriginalMailbox.UsageLocation
    }
    Export-OneShellData -DataToExport $OriginalMailbox -DataToExportTitle $($OriginalMailbox.guid.guid + 'MailboxObjectBackup') -DataType clixml -Depth 4 -ErrorAction Stop
    #disable the original mailbox
    Invoke-Command -Session $ExchangeSession -ScriptBlock {Disable-Mailbox -identity $($Using:MailUserObject).Identity -confirm:$false -erroraction Stop} -ErrorAction Stop
    #enable the replacement mailuser
    $EnableParamsList = 'Identity','ExternalEmailAddress','Alias','DisplayName','PrimarySmtpAddress'
    $EnableParams = @{
        ErrorAction = 'Stop'
        Identity = $MailUserObject.Identity
        Alias = $MailUserObject.Alias
        ExternalEmailAddress = $MailUserObject.ExternalEmailAddress
        PrimarySmtpAddress = $MailUserObject.PrimarySMTPAddress
        DisplayName = $MailUserObject.DisplayName
    }
    Invoke-Command -Session $ExchangeSession -ScriptBlock {Enable-MailUser @using:EnableParams} -ErrorAction Stop
    $SetParams = @{ErrorAction = 'Stop';ForceUpgrade = $true}
    foreach ($m in $(Get-Member -InputObject $MailUserObject -MemberType Properties | Select-Object -ExpandProperty Name))
    {
        if ($null -ne $MailUserObject.$m -and -not [string]::IsNullOrWhiteSpace($MailUserObject.$m))
        {
            if ($m -notin @('PrimarySmtpAddress'))
            {
                $SetParams.$m = $MailUserObject.$m
            }
        }
    }
    Invoke-Command -Session $ExchangeSession -ScriptBlock {Set-MailUser @using:SetParams} -ErrorAction Stop
}