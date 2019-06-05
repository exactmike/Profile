Function Get-InstalledModuleInfo {

    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Named', Position = 1)]
        [string[]]$Name
        ,
        [parameter(ParameterSetName = 'Named', Position = 2)]
        [string]$RequiredVersion
        ,
        [string]$Repository
    )
    begin
    {
        [System.Collections.ArrayList]$LocalModules = @()
        [System.Collections.ArrayList]$LocalPowerShellGetModules = @()
        [System.Collections.ArrayList]$LatestRepositoryModules = @()
        $FindModuleParams = @{}
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
                $LocalModules.where({$null -ne $_.RepositorySourceLocation}).foreach({Get-InstalledModule -Name $_.Name -AllVersions}).foreach({$LocalPowerShellGetModules.add($_) | Out-Null})
                $LocalPowerShellGetModules.ForEach({
                    $FindModuleParams.Name = $_.name
                    $RepositoryModule = Find-Module @FindModuleParams
                    $LatestRepositoryModules.add($RepositoryModule) | Out-Null
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
                    switch ($PSBoundParameters.ContainsKey('RequiredVersion'))
                    {
                        $true
                        {
                            $GetInstalledModuleParams.RequiredVersion = $PSBoundParameters.RequiredVersion
                        }
                        $false
                        {
                            $GetInstalledModuleParams.AllVersions = $true
                        }
                    }
                    $LocalPowerShellGetModules.add($(Get-InstalledModule @GetInstalledModuleParams)) | Out-Null
                    #Get the PSGallery Module for the named module
                    $FindModuleParams.Name = $n
                    $RepositoryModule = Find-Module @FindModuleParams
                    $LatestRepositoryModules.add($($RepositoryModule)) | Out-Null
                }
            }
        }
    }
    End
    {
        $ToReturn = @{
            LatestRepositoryModules = $LatestRepositoryModules
            LocalModules = $LocalModules
            LocalPowerShellGetModules = $LocalPowerShellGetModules
        }
        $ToReturn
    }
<#     End
    {
        $LocalModulesLookup = $LocalModules | Group-Object -AsHashTable -Property Name
        $LocalPowerShellGetModulesLookup = $LocalPowerShellGetModules | Select-Object -Property Name,Version | Group-Object -AsHashTable -Property Name
        $LatestRepositoryModulesLookup = $LatestRepositoryModules | Select-Object -Property Name,Version | Select-Object -Unique | Group-Object -AsHashTable -Property Name
        $ModuleVersionStatuses = @(
            foreach ($am in $LocalModules)
            {
                #Iterate through available modules
                $ModuleVersionStatus = [PSCustomObject]@{
                    Name            = $am.Name
                    Version         = $am.Version
                    PowerShellGet   = $null
                    LatestVersion   = $null
                    UpdateAvailable = $null
                    Location        = Split-Path -Path $am.ModuleBase -Parent
                    Guid            = $am.Guid.guid
                }
                switch ($LocalPowerShellGetModulesLookup.ContainsKey($am.Name))
                {
                    $true
                    {
                        try
                        {

                            $PSGetModule = $null
                            $PSGetModule = Get-InstalledModule -Name $am.name -RequiredVersion $am.Version -ErrorAction Stop
                            if ($null -ne $PSGetModule)
                            {
                                $ModuleVersionStatus.PowerShellGet = $true
                                $ModuleVersionStatus.LatestVersion = $LatestRepositoryModulesLookup.$($am.name).Version
                                $ModuleVersionStatus.UpdateAvailable = $($ModuleVersionStatus.LatestVersion -gt $ModuleVersionStatus.Version)
                            }
                        }
                        catch
                        {
                            $ModuleVersionStatus.PowerShellGet = $false
                            $ModuleVersionStatus.LatestVersion = 'Unknown'
                            $ModuleVersionStatus.UpdateAvailable = 'Unknown'
                        }
                    }
                    $false
                    {
                        $ModuleVersionStatus.PowerShellGet = $false
                        $ModuleVersionStatus.LatestVersion = 'Unknown'
                        $ModuleVersionStatus.UpdateAvailable = 'Unknown'
                    }
                }
                $ModuleVersionStatus
            }
        )
        $GroupVersionStatusByModuleName = @($ModuleVersionStatuses | Group-Object -Property Name)
        foreach ($g in $GroupVersionStatusByModuleName)
        {
            switch ($g.count -gt 1)
            {
                $true
                {
                    [PSCustomObject]@{
                        Name                   = $g.Name
                        LatestVersionInstalled = $g.group.Version | Sort-Object -Descending | Select-Object -First 1
                        InstalledVersions      = @($g.group.Version | Sort-Object -Descending -Unique)
                        PowerShellGet          = if ($g.group.PowerShellGet -contains $true) {$true} else {$false}
                        LatestVersion          = $g.group.LatestVersion | Where-Object -FilterScript {$_ -ne 'Unknown'} | Sort-Object -Descending | Select-Object -First 1
                        UpdateAvailable        = if ($g.group.UpdateAvailable -contains $false) {$false} else {$true}
                        Location               = @($g.group.Location | Select-Object -Unique)
                        Guid                   = @($g.group.Guid | Select-Object -Unique)
                    }


                }
                $false
                {
                    [PSCustomObject]@{
                        Name                   = $g.Name
                        LatestVersionInstalled = $g.group[0].Version
                        InstalledVersions      = @($g.group[0].Version)
                        PowerShellGet          = $g.group[0].PowerShellGet
                        LatestVersion          = $g.group[0].LatestVersion
                        UpdateAvailable        = $g.group[0].UpdateAvailable
                        Location               = @($g.group[0].Location)
                        Guid                   = @($g.group[0].Guid)
                    }
                }
            }
        }
    } #>
}
