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
        ) -notcontains $false
    )
    {
        foreach ($mi in $ManagedInstalls)
        {
            switch ($mi)
            {
                { $mi.AutoUpgrade -eq 'TRUE' }
                { $mi.AutoUpgrade = $true }
                { $mi.AutoUpgrade -eq 'FALSE' }
                { $mi.AutoUpgrade = $false }
                { [string]::IsNullOrWhiteSpace($mi.AutoUpgrade) }
                { $mi.AutoUpgrade = $false }
                { $mi.AutoRemove -eq 'TRUE' }
                { $mi.AutoRemove = $true }
                { $mi.AutoRemove -eq 'FALSE' }
                { $mi.AutoRemove = $false }
                { [string]::IsNullOrWhiteSpace($mi.AutoRemove) }
                { $mi.AutoRemove = $false }
            }
        }
        $Script:ManagedInstalls = $ManagedInstalls
    }
}
