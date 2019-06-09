Function Get-InstalledModuleInfo {

    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Named', Position = 1)]
        [string[]]$Name
        ,
        [string]$Repository
        ,
        [switch]$PerInstalledVersion
    )
    begin
    {
        [System.Collections.ArrayList]$LocalModules = @()
        [System.Collections.ArrayList]$LocalPowerShellGetModules = @()
        [System.Collections.ArrayList]$LatestRepositoryModules = @()
        [System.Collections.ArrayList]$NamedModules = @()
        [System.Collections.ArrayList]$RepoFoundModules = @()
        $FindModuleParams = @{
            ErrorAction = 'SilentlyContinue'
        }
        if ($PSBoundParameters.ContainsKey('Repository'))
        {
            $FindModuleParams.Repository = $PSBoundParameters.Repository
        }
        $GetInstalledModuleParams = @{
            ErrorAction = 'SilentlyContinue'
        }
    }
    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                #Get the locally available modules on this system for the current user based on entries in $env:Psmodulepath
                @(Get-Module -ListAvailable).foreach({$LocalModules.add($_) | Out-Null})
                #Get the locally available modules that were installed using PowerShellGet Module commands
                $LocalModules.where({$null -ne $_.RepositorySourceLocation}).foreach({Get-InstalledModule -Name $_.Name -RequiredVersion $_.Version @GetInstalledModuleParams}).foreach({$LocalPowerShellGetModules.add($_) | Out-Null})
                ($LocalModules.ForEach({$_.Name}) | Sort-Object -Unique).foreach({$NamedModules.add([pscustomobject]@{Name=$_}) | Out-Null})
                $LocalPowerShellGetModules.ForEach({
                    if (-not $RepoFoundModules.Contains($_.name))
                    {
                        $FindModuleParams.Name = $_.name
                        $RepositoryModule = Find-Module @FindModuleParams
                        $LatestRepositoryModules.add($RepositoryModule) | Out-Null
                        $RepoFoundModules.add($_.name) | Out-Null
                    }
                })
            }
            'Named'
            {
                foreach ($n in $Name)
                {
                    #Get the locally available named module(s) on this system for the current user based on entries in $env:Psmodulepath
                    $LocalModules.add($(Get-Module -ListAvailable -Name $n -ErrorAction Stop)) | Out-Null
                    #Get the locally available named module(s) that were installed using PowerShellGet Module commands
                    $GetInstalledModuleParams.Name = $n
                    $GetInstalledModuleParams.AllVersions = $true
                    $LocalPowerShellGetModules.add($(Get-InstalledModule @GetInstalledModuleParams)) | Out-Null
                    #Get the PSGallery Module for the named module
                    $FindModuleParams.Name = $n
                    $LatestRepositoryModule = Find-Module @FindModuleParams
                    $LatestRepositoryModules.add($LatestRepositoryModule) | Out-Null
                    $NamedModules.add($([pscustomobject]@{Name=$n})) | Out-Null
                }
            }
        }
    }
    End
    {
        $LocalModulesLookupNV = @{}
        $LocalModules.foreach({$_}) | Select-Object -Property Name,Version,Path,GUID,ModuleBase,LicenseUri,ProjectUri,@{n='NameVersion';e={[string]$($_.Name + $_.Version)}} | ForEach-Object -Process {$LocalModulesLookupNV.$($_.NameVersion) = $_}
        #$LocalModulesLookupN = $LocalModules.foreach({$_}) | Select-Object -Property Name,Version,Path,GUID,ModuleBase,LicenseUri,ProjectUri,@{n='NameVersion';e={$_.Name + $_.Version}} | Group-Object -AsHashTable -Property Name
        $LocalPowerShellGetModulesLookup = @{}
        $LocalPowerShellGetModules.foreach({$_}) | Select-Object -Property Name,Version,Author,PublishedDate,InstalledDate,UpdatedDate,LicenseUri,InstalledLocation,Repository,@{n='NameVersion';e={$_.Name + $_.Version}} | ForEach-Object -Process {$LocalPowerShellGetModulesLookup.$($_.NameVersion) = $_}
        $LatestRepositoryModulesLookup = @{}
        $LatestRepositoryModules.foreach({$_}) | Select-Object -Property Name,Version,Author,PublishedDate,LicenseUri,ProjectUri,Repository | ForEach-Object -Process {$LatestRepositoryModulesLookup.$($_.Name) = $_}
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                $PerInstalledVersionOutput = @(
                    foreach ($lm in $LocalModules.foreach({$_}))
                    {
                        $lookup = $lm.Name + $lm.Version
                        [PSCustomObject]@{
                            Name = $lm.Name
                            Version = $lm.Version
                            IsLatestVersion = if ($null -ne $LatestRepositoryModulesLookup.$($lm.name).Version) {$lm.version -eq $LatestRepositoryModulesLookup.$($lm.name).Version} else {$null}
                            AllInstalledVersions = @($LocalModules.foreach({$_}).where({$_.Name -ieq $lm.Name}).foreach({$_.Version.tostring()}))
                            InstalledFromRepository = $null -ne $lm.RepositorySourceLocation
                            Repository = $LocalPowerShellGetModulesLookup.$lookup.Repository
                            InstalledLocation = $lm.ModuleBase
                            InstalledDate = $LocalPowerShellGetModulesLookup.$lookup.InstalledDate
                            PublishedDate = $LocalPowerShellGetModulesLookup.$lookup.PublishedDate
                            LatestRepositoryVersion = $LatestRepositoryModulesLookup.$($lm.name).Version
                            LatestRepositoryVersionPublishedDate = $LatestRepositoryModulesLookup.$($lm.name).PublishedDate
                            LatestVersionInstalled = if ($null -eq $lm.RepositorySourceLocation) {$null} else {$LocalModulesLookupNV.ContainsKey($lm.Name + $LatestRepositoryModulesLookup.$($lm.name).Version.tostring())}
                        }
                    }
                )
            }
            'Named'
            {
                $PerInstalledVersionOutput = @(
                    foreach ($nm in $NamedModules)
                    {
                        if ($LocalModules.foreach({$_}).where({$_.Name -ieq $nm.Name}).count -ge 1)
                        {
                            foreach ($lm in $LocalModules.foreach({$_}).where({$_.Name -ieq $nm.Name}))
                            {
                                $lookup = $nm.Name + $lm.Version
                                [PSCustomObject]@{
                                    Name = $nm.Name
                                    Version = $lm.Version
                                    IsLatestVersion = if ($null -ne $LatestRepositoryModulesLookup.$($nm.name).Version) {$lm.version -eq $LatestRepositoryModulesLookup.$($nm.name).Version} else {$null}
                                    AllInstalledVersions = @($LocalModules.foreach({$_}).where({$_.Name -ieq $nm.Name}).foreach({$_.Version}))
                                    InstalledFromRepository = $null -ne $lm.RepositorySourceLocation
                                    Repository = $LocalPowerShellGetModulesLookup.$lookup.Repository
                                    InstalledLocation = $lm.ModuleBase
                                    InstalledDate = $LocalPowerShellGetModulesLookup.$lookup.InstalledDate
                                    PublishedDate = $LocalPowerShellGetModulesLookup.$lookup.PublishedDate
                                    LatestRepositoryVersion = $LatestRepositoryModulesLookup.$($nm.name).Version
                                    LatestRepositoryVersionPublishedDate = $LatestRepositoryModulesLookup.$($nm.name).PublishedDate
                                    LatestVersionInstalled = if ($null -eq $lm.RepositorySourceLocation) {$null} else {$LocalModulesLookupNV.ContainsKey($lm.Name + $LatestRepositoryModulesLookup.$($lm.name).Version.tostring())}
                                    #LatestVersionInstalled = $LocalModulesLookupNV.ContainsKey($nm.Name + $LatestRepositoryModulesLookup.$($nm.name).Version.tostring())
                                }
                            }
                        }
                        else
                        {
                            $lookup = $nm.Name
                            [PSCustomObject]@{
                                Name = $lookup
                                Version = $null
                                IsLatestVersion = $null
                                AllInstalledVersions = $null
                                InstalledFromRepository = $null
                                Repository = $LatestRepositoryModulesLookup.$lookup.Repository
                                InstalledLocation = $null
                                InstalledDate = $null
                                PublishedDate = $null
                                LatestRepositoryVersion = $LatestRepositoryModulesLookup.$lookup.Version
                                LatestRepositoryVersionPublishedDate = $LatestRepositoryModulesLookup.$lookup.PublishedDate
                                LatestVersionInstalled = $false
                            }
                        }
                    }
                )
            }
        }
        switch ($PerInstalledVersion)
        {
            $true
            {
                $PerInstalledVersionOutput
            }
            $false
            {
                $PerModuleGroups = $PerInstalledVersionOutput | Group-Object -Property Name
                foreach ($pmg in $PerModuleGroups)
                {
                    $lvInstalled = $pmg.Group.Version.foreach({$_.tostring()}) | Sort-Object -Descending | Select-Object -first 1
                    switch ($null -eq $lvInstalled)
                    {
                        $false
                        {
                            [PSCustomObject]@{
                                Name = $pmg.Name
                                Version = $lvInstalled
                                IsLatestVersion = $pmg.Group.where({$_.version.tostring() -eq $lvInstalled}).IsLatestVersion | Select-Object -Unique
                                AllInstalledVersions = @($pmg.Group.where({$_.version.tostring() -eq $lvInstalled}).AllInstalledVersions | Select-Object -Unique)
                                InstalledFromRepository = $pmg.Group.where({$_.version.tostring() -eq $lvInstalled}).InstalledFromRepository | Select-Object -Unique
                                Repository = $pmg.Group.where({$_.version.tostring() -eq $lvInstalled}).Repository | Select-Object -Unique
                                InstalledLocation = $pmg.Group.where({$_.version.tostring() -eq $lvInstalled}).InstalledLocation
                                InstalledDate = $pmg.Group.where({$_.version.tostring() -eq $lvInstalled}).InstalledDate | Select-Object -Unique
                                PublishedDate = $pmg.Group.where({$_.version.tostring() -eq $lvInstalled}).PublishedDate | Select-Object -Unique
                                LatestRepositoryVersion = $pmg.Group.where({$_.version.tostring() -eq $lvInstalled}).LatestRepositoryVersion | Select-Object -Unique
                                LatestRepositoryVersionPublishedDate = $pmg.Group.where({$_.version.tostring() -eq $lvInstalled}).LatestRepositoryVersionPublishedDate | Select-Object -Unique
                                LatestVersionInstalled = $pmg.Group.where({$_.version.tostring() -eq $lvInstalled}).LatestVersionInstalled | Select-Object -Unique
                            }
                        }
                        $true
                        {
                            [PSCustomObject]@{
                                Name = $pmg.Name
                                Version = $null
                                IsLatestVersion = $null
                                AllInstalledVersions = $null
                                InstalledFromRepository = $null
                                Repository = $LatestRepositoryModulesLookup.$($pmg.Name).Repository
                                InstalledLocation = $null
                                InstalledDate = $null
                                PublishedDate = $null
                                LatestRepositoryVersion = $LatestRepositoryModulesLookup.$($pmg.Name).Version
                                LatestRepositoryVersionPublishedDate = $LatestRepositoryModulesLookup.$($pmg.Name).PublishedDate
                                LatestVersionInstalled = $False
                            }
                        }
                    }
                }
            }
        }
    }
}
