    Function Get-AvailableModuleInstallationStatus {
        
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Named', Position = 1)]
        [string[]]$Name
    )
    begin
    {
        $AvailableModules = @()
        $PowerShellGetModules = @()
    }
    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                #Get the locally available modules on this system for the current user based on entries in $env:Psmodulepath
                $AvailableModules = @(Get-Module -ListAvailable)
                #Get the locally available modules that were installed using PowerShellGet Module commands
                $PowerShellGetModules = @(Get-InstalledModule)
            }
            'Named'
            {
                foreach ($n in $Name)
                {
                    #Get the locally available named module(s) on this system for the current user based on entries in $env:Psmodulepath
                    $AvailableModules += Get-Module -ListAvailable -Name $n -ErrorAction Stop
                    #Get the locally available named module(s) that were installed using PowerShellGet Module commands
                    $PowerShellGetModules += Get-InstalledModule -Name $n -ErrorAction SilentlyContinue
                }
            }
        }
    }
    End
    {
        $PowerShellGetModules | ForEach-Object {
            $RepositoryModule = Find-Module -Name $_.name
            Add-Member -InputObject $_ -MemberType NoteProperty -Name LatestVersion -Value $RepositoryModule.Version
        }
        #Create a lookup hashtable for the PowerShellGet Modules
        $PowerShellGetModulesLookup = $PowerShellGetModules | Group-Object -AsHashTable -Property Name
        $ModuleVersionStatuses = @(
            foreach ($am in $AvailableModules)
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
                switch ($PowerShellGetModulesLookup.ContainsKey($am.Name))
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
                                $ModuleVersionStatus.LatestVersion = $PowerShellGetModulesLookup.$($am.name).LatestVersion
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
                        LatestVersion          = $g.group.LatestVersion | Sort-Object -Descending | Select-Object -First 1
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

    }

    }
