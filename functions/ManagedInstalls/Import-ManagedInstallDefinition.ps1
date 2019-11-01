Function Import-ManagedInstallDefinition
{

    [cmdletbinding()]
    param(
        $Path
    )
    $ManagedInstalls = @(Import-Csv -Path $Path)
    $RequiredProperties = @('Name', 'InstallManager', 'RequiredVersion', 'AutoUpgrade', 'AutoRemove', 'ExemptMachine', 'Parameter', 'Repository')
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
            Convert-StringBoolToBool -object $mi -IncludeProperty 'AutoUpgrade', 'AutoRemove'
        }
        $Script:ManagedInstalls = $ManagedInstalls
    }
}
