function Export-ExchangeConfiguration
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [ValidateScript( { Test-Path -type Container -Path $_ })]
        [string]$OutputFolderPath
        ,
        [switch]$ExchangeOnline
    )

    $ErrorActionPreference = 'Continue'

    switch ($ExchangeOnline)
    {
        $true { }
        default
        { $Servers = Get-ExchangeServer }
    }

    $ExchangeConfiguration = [PSCustomObject]@{
        OrganizationConfig              = Get-OrganizationConfig
        AdminAuditLogConfig             = Get-AdminAuditLogConfig
        SettingOverride                 = $null
        ExchangeServer                  = $Null
        NetworkConnectionInfo           = $Null
        PartnerApplication              = Get-PartnerApplication
        AuthConfig                      = $null
        AuthServer                      = Get-AuthServer
        CmdletExtensionAgent            = $null
        FederatedOrganizationIdentifier = Get-FederatedOrganizationIdentifier
        FederationTrust                 = Get-FederationTrust
        HybridConfiguration             = $null
        IntraOrganizationConfiguration  = Get-IntraOrganizationConfiguration
        IntraOrganizationConnector      = Get-IntraOrganizationConnector
        PendingFederatedDomain          = $null
        AvailabilityAddressSpace        = Get-AvailabilityAddressSpace
        AvailabilityConfig              = Get-AvailabilityConfig
        OrganizationRelationship        = Get-OrganizationRelationship
        SharingPolicy                   = Get-SharingPolicy
        MigrationConfig                 = Get-MigrationConfig
        MigrationEndpoint               = Get-MigrationEndpoint
        DatabaseAvailabilityGroup       = $Null
        MailboxDatabase                 = $null
        MailboxServer                   = $null
        AcceptedDomain                  = Get-AcceptedDomain
        DeliveryAgentConnector          = $null
        ForeignConnector                = $null
        FrontEndTransportService        = $null
        MailboxTransportService         = $null
        ReceiveConnector                = switch ($exchangeOnline) { $true { Get-InboundConnector } default { Get-ReceiveConnector } }
        SendConnector                   = switch ($exchangeOnline) { $true { Get-OutboundConnector } default { Get-SendConnector } }
        TransportAgent                  = $null
        TransportConfig                 = Get-TransportConfig
        TransportPipeline               = $null
        TransportRule                   = Get-TransportRule
        ExchangeCertificate             = $null
        SMIMEConfig                     = Get-SmimeConfig
        UPNSuffix                       = $null
        ClientAccessServer              = $null
        ClientAccessArray               = $null
        PowershellVirtualDirectory      = $null
        ActiveSyncVirtualDirectory      = $null
        OABVirtualDirectory             = $null
        OWAVirtualDirectory             = $null
        ECPVirtualDirectory             = $null
        WebServicesVirtualDirectory     = $null
        MAPIVirtualDirectory            = $null
        OutlookProvider                 = $null
        OutlookAnywhere                 = $null
        RPCClientAccess                 = $null
        EmailAddressPolicy              = Get-EmailAddressPolicy
        AddressBookPolicy               = Get-AddressBookPolicy
        AddressList                     = $null
        GlobalAddressList               = $null
        OfflineAddressBook              = $null
        OWAMailboxPolicy                = Get-OWAMailboxPolicy
        MobileDeviceMailboxPolicy       = Get-MobileDeviceMailboxPolicy
        ActiveSyncDeviceClass           = Get-ActiveSyncDeviceClass | Select-Object -Property DeviceModel, DeviceType -Unique
        ActiveSyncDeviceAccessRule      = Get-ActiveSyncDeviceAccessRule
        RetentionPolicy                 = Get-RetentionPolicy
        RetentionTag                    = Get-RetentionPolicyTag
    }

    switch ($ExchangeOnline)
    {
        $true { }
        Default
        {
            $ExchangeConfiguration.ExchangeServer = $Servers
            $ExchangeConfiguration.NetworkConnectionInfo = foreach ($s in $Servers) { Get-NetworkConnectionInfo -Identity $s.fqdn }
            $ExchangeConfiguration.ExchangeCertificate = foreach ($s in $Servers) { Get-ExchangeCertificate -Server $s.fqdn }
            $ExchangeConfiguration.SettingOverride = Get-SettingOverride
            $ExchangeConfiguration.AuthConfig = Get-AuthConfig
            $ExchangeConfiguration.CmdletExtensionAgent = Get-CmdletExtensionAgent
            $ExchangeConfiguration.HybridConfiguration = Get-HybridConfiguration
            $ExchangeConfiguration.PendingFederatedDomain = Get-PendingFederatedDomain
            $ExchangeConfiguration.DatabaseAvailabilityGroup = Get-DatabaseAvailabilityGroup
            $ExchangeConfiguration.MailboxDatabase = Get-MailboxDatabase
            $ExchangeConfiguration.MailboxServer = Get-MailboxServer
            $ExchangeConfiguration.TransportAgent = Get-TransportAgent
            $ExchangeConfiguration.TransportPipeline = Get-TransportPipeline
            $ExchangeConfiguration.UPNSuffix = Get-UserPrincipalNamesSuffix
            $ExchangeConfiguration.ClientAccessServer = Get-ClientAccessServer
            $ExchangeConfiguration.ClientAccessArray = Get-ClientAccessArray
            $ExchangeConfiguration.PowershellVirtualDirectory = Get-PowershellVirtualDirectory -adpropertiesonly
            $ExchangeConfiguration.ActiveSyncVirtualDirectory = Get-ActiveSyncVirtualDirectory -adpropertiesonly
            $ExchangeConfiguration.OABVirtualDirectory = Get-OabVirtualDirectory -adpropertiesonly
            $ExchangeConfiguration.OWAVirtualDirectory = Get-OwaVirtualDirectory -adpropertiesonly
            $ExchangeConfiguration.ECPVirtualDirectory = Get-EcpVirtualDirectory -adpropertiesonly
            $ExchangeConfiguration.WebServicesVirtualDirectory = Get-WebServicesVirtualDirectory -adpropertiesonly
            $ExchangeConfiguration.MAPIVirtualDirectory = Get-MapiVirtualDirectory -adpropertiesonly
            $ExchangeConfiguration.OutlookProvider = Get-OutlookProvider
            $ExchangeConfiguration.OutlookAnywhere = Get-OutlookAnywhere
            $ExchangeConfiguration.RPCClientAccess = Get-RPCClientAccess
            $ExchangeConfiguration.AddressList = Get-AddressList
            $ExchangeConfiguration.GlobalAddressList = Get-GlobalAddressList
            $ExchangeConfiguration.DeliveryAgentConnector = Get-DeliveryAgentConnector
            $ExchangeConfiguration.ForeignConnector = Get-ForeignConnector
            $ExchangeConfiguration.FrontEndTransportService = Get-FrontendTransportService
            $ExchangeConfiguration.MailboxTransportService = Get-MailboxTransportService
        }
    }

    $DateString = Get-Date -Format yyyyMMddHHmmss

    $OutputFileName = 'ExchangeConfigurationAsOf' + $DateString + '.xml'
    $OutputFilePath = Join-Path $OutputFolderPath $OutputFileName

    $ExchangeConfiguration | Export-Clixml -Path $OutputFilePath -Encoding utf8 -Depth 5
}