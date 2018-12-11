function Set-VirtualizationNetAdapterToPrivate
{
    param (
        $Name = 'Unidentified network'
        ,
        $InterfaceAliasPrefix = 'vEthernet'
    )
    $MatchingConnectionProfiles = @(Get-NetConnectionProfile -InterfaceAlias "$InterfaceAliasPrefix*" -Name $Name)
    $MatchingConnectionProfiles | Set-NetConnectionProfile -NetworkCategory Private
}