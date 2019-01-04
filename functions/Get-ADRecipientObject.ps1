    Function Get-ADRecipientObject {
        
    [cmdletbinding()]
    param
    (
        [int]$ResultSetSize = 10000
        ,
        [switch]$Passthrough
        ,
        [switch]$ExportData
        ,
        [parameter(Mandatory = $true)]
        $ADInstance
    )
    Set-Location -Path "$($ADInstance):\"
    $AllGroups = Get-ADGroup -ResultSetSize $ResultSetSize -Properties @($AllADAttributesToRetrieve + 'Members') -Filter * | Select-Object -Property * -ExcludeProperty Property*, Item
    $AllMailEnabledGroups = $AllGroups | Where-Object -FilterScript {$_.legacyExchangeDN -ne $NULL -or $_.mailNickname -ne $NULL -or $_.proxyAddresses -ne $NULL}
    $AllContacts = Get-ADObject -Filter {objectclass -eq 'contact'} -Properties $AllADContactAttributesToRetrieve -ResultSetSize $ResultSetSize | Select-Object -Property * -ExcludeProperty Property*, Item
    $AllMailEnabledContacts = $AllContacts | Where-Object -FilterScript {$_.legacyExchangeDN -ne $NULL -or $_.mailNickname -ne $NULL -or $_.proxyAddresses -ne $NULL}
    $AllUsers = Get-ADUser -ResultSetSize $ResultSetSize -Filter * -Properties $AllADAttributesToRetrieve | Select-Object -Property * -ExcludeProperty Property*, Item
    $AllMailEnabledUsers = $AllUsers  | Where-Object -FilterScript {$_.legacyExchangeDN -ne $NULL -or $_.mailNickname -ne $NULL -or $_.proxyAddresses -ne $NULL}
    $AllPublicFolders = Get-ADObject -Filter {objectclass -eq 'publicFolder'} -ResultSetSize $ResultSetSize -Properties $AllADAttributesToRetrieve | Select-Object -Property * -ExcludeProperty Property*, Item
    $AllMailEnabledPublicFolders = $AllPublicFolders  | Where-Object -FilterScript {$_.legacyExchangeDN -ne $NULL -or $_.mailNickname -ne $NULL -or $_.proxyAddresses -ne $NULL}
    $AllMailEnabledADObjects = $AllMailEnabledGroups + $AllMailEnabledContacts + $AllMailEnabledUsers + $AllMailEnabledPublicFolders
    if ($Passthrough) {$AllMailEnabledADObjects}
    if ($ExportData) {Export-Data -DataToExport $AllMailEnabledADObjects -DataToExportTitle 'AllADRecipientObjects' -Depth 3 -DataType xml}

    }
