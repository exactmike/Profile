Function Edit-ManagedInstallDefinitionFile
{
    [cmdletbinding()]

    param
    (
        [parameter()]
        [string]$path
    )

    Invoke-Item $path

}
