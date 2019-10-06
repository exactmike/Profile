Function Get-ManagedInstallDefinition
{
    
    [cmdletbinding()]
    param(
        [string]$Name
        ,
        [InstallManager[]]$InstallManager
    )
    $Script:ManagedInstalls.where( { ($null -eq $Name -or $Name -like $_.Name) -and ($null -eq $InstallManager -or $_.InstallManager -in $InstallManager) })

}

