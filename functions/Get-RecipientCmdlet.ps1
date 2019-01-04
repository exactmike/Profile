    Function Get-RecipientCmdlet {
        
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
