Function Import-ManagedInstallDefinition
{
    
    [cmdletbinding()]
    param(
        $Path
    )
    $ManagedInstalls = @(Import-Csv -Path $Path)
    $RequiredProperties = @('Name', 'InstallManager', 'RequiredVersions', 'AutoUpgrade', 'AutoRemove', 'ExemptMachines', 'Parameters', 'Repository')
    if (
        @(
            foreach ($rp in $RequiredProperties)
            {
                Test-Member -inputobject $ManagedInstalls[0] -Name $rp
            }
        ) -notcontains $false)
    {
        $Script:ManagedInstalls = $ManagedInstalls
    }

}

