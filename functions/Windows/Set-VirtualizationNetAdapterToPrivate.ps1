    Function Set-VirtualizationNetAdapterToPrivate {
        
    param (
        $Name = 'Unidentified network'
        ,
        $InterfaceAliasPrefix = 'vEthernet'
    )
    if (-not $IsWindows) {
        throw [System.PlatformNotSupportedException]::new('Set-VirtualizationNetAdapterToPrivate requires Windows.')
    }
    $MatchingConnectionProfiles = @(Get-NetConnectionProfile -InterfaceAlias "$InterfaceAliasPrefix*" -Name $Name -ErrorAction SilentlyContinue)
    $MatchingConnectionProfiles | Where-Object {$_.IPv4Connectivity -eq 'NoTraffic' -and $_.IPv6Connectivity -eq 'NoTraffic'} | Set-NetConnectionProfile -NetworkCategory Private

    }
