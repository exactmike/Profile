function Set-VirtualizationNetAdapterToPrivate
{
    param (
        $Name = 'Unidentified network'
        ,
        $InterfaceAliasPrefix = 'vEthernet'
    )
    $MatchingConnectionProfiles = @(Get-NetConnectionProfile -InterfaceAlias "$InterfaceAliasPrefix*" -Name $Name -ErrorAction SilentlyContinue)
    $MatchingConnectionProfiles | Where-Object {$_.IPv4Connectivity -eq 'NoTraffic' -and $_.IPv6Connectivity -eq 'NoTraffic'} | Set-NetConnectionProfile -NetworkCategory Private
}