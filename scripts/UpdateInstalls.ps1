Function Get-ManagedPackageDefinition
{

}
Function Import-ManagedPackageDefinition
{
    param(
        $Path
    )
    $ManagedPackages = @(Import-Csv -Path $Path)
    $RequiredProperties = @('Name', 'PackageManager', 'RequiredVersions', 'AutoUpgrade', 'AutoRemove', 'ExemptMachines', 'Parameters', 'Repository')
    if (
        @(
            foreach ($rp in $RequiredProperties)
            {
                Test-Member -inputobject $ManagedPackages[0] -Name $rp
            }
        ) -notcontains $false)
    {
        $Script:ManagedPackages = $ManagedPackages
    }
}