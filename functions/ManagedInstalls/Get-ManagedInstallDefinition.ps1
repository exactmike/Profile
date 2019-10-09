Function Get-ManagedInstallDefinition
{

    [cmdletbinding()]
    param(
        [string]$Name
        ,
        [InstallManager[]]$InstallManager
    )
    #$InstallManagers = @($InstallManager.foreach('ToString'))
    $Script:ManagedInstalls.where( { ([string]::IsNullOrEmpty($Name) -or $_.Name -like $Name) }).where( { $InstallManager.count -eq 0 -or $_.InstallManager -in $InstallManager })
}
