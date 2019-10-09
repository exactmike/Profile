Function Get-InstalledByChoco {

    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Named', Position = 1)]
        [string[]]$Name
        #,
        #[string]$Repository
        #,
        #[switch]$PerInstalledVersion
    )
    begin
    {
        $ChocoOutdatedPackages = @(
            Invoke-Command -scriptblock $([scriptblock]::Create("choco outdated --LimitOutput")) | ForEach-Object {
                $packageName,$installedVersion,$latestRepositoryVersion,$pinned = $_.split('|')
                [PSCustomObject]@{
                    Name = "$packageName"
                    InstalledVersion = $installedVersion
                    LatestRepositoryVersion = $latestRepositoryVersion
                    Pinned = switch ($pinned) {'true' {$true} 'false' {$false} Default {$null}}
                }
            }
        )
        $ChocoOutdatedPackagesNames = @($ChocoOutdatedPackages.ForEach({$_.Name}))
    }
    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                $ChocoInstalledPackages = @(
                    Invoke-Command -scriptblock $([scriptblock]::Create("choco list --LocalOnly --LimitOutput")) | ForEach-Object {
                        $packageName,$installedVersion = $_.split('|')
                        [PSCustomObject]@{
                            Name = "$packageName"
                            InstalledVersion = $installedVersion
                        }
                    }
                )
            }
            'Named'
            {
                $ChocoInstalledPackages = @(
                    foreach ($n in $Name)
                    {
                        Invoke-Command -scriptblock $([scriptblock]::Create("choco list $n --LocalOnly --LimitOutput --Exact")) | ForEach-Object {
                            $packageName,$installedVersion = $_.split('|')
                            [PSCustomObject]@{
                                Name = "$packageName"
                                InstalledVersion = $installedVersion
                            }
                        }
                    }
                )
            }
        }
    }
    end
    {
        Foreach ($cip in $ChocoInstalledPackages)
        {
            if ($ChocoOutdatedPackagesNames -contains $cip.Name)
            {
                $cop = $($ChocoOutdatedPackages.Where({$_.Name -eq $cip.Name}) | Select-object -First 1)
                [PSCustomObject]@{
                    Name = $cip.Name
                    Version = $cip.InstalledVersion
                    IsLatestVersion = $false
                    #AllInstalledVersions =
                    #Repository
                    #PublishedDate
                    LatestRepositoryVersion = $cop.LatestRepositoryVersion
                    #LatestRepositoryVersionPublishedDate
                    LatestVersionInstalled = $false
                }
            }
            else
            {
                [PSCustomObject]@{
                    Name = $cip.Name
                    Version = $cip.InstalledVersion
                    IsLatestVersion = $true
                    #AllInstalledVersions =
                    #Repository
                    #PublishedDate
                    LatestRepositoryVersion = $cip.InstalledVersion
                    #LatestRepositoryVersionPublishedDate
                    LatestVersionInstalled = $true
                }
            }
        }
    }
}
