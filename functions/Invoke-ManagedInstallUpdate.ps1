Function Invoke-ManagedInstallUpdate
{
    
    param(
        [InstallManager[]]$InstallManager
    )

    foreach ($i in $($Installs | Where-Object -FilterScript { $_.InstallManager -ne 'Manual' -and $_.InstallManager -in $InstallManager }))
    {
        Write-Verbose -Message "Processing $($i.Name) for Installation or Update." -Verbose
        $UMMParams = @{
            ErrorAction    = 'Stop'
            Name           = $i.Name
            InstallManager = $i.InstallManager
            AutoUpgrade    = switch ($i.AutoUpgrade) { 'TRUE' { $true } 'FALSE' { $false } Default { $false } }
            AutoRemove     = switch ($i.AutoRemove) { 'TRUE' { $true } 'FALSE' { $false } Default { $false } }
        }
        if ('TRUE' -eq $i.AutoRemove)
        { $UMMParams.AutoRemove = $true }
        if (-not [string]::IsNullOrEmpty($i.ExemptMachines))
        { $UMMParams.ExemptMachines = $i.ExemptMachines.split(';') }
        if (-not [string]::IsNullOrEmpty($i.RequiredVersions))
        { $UMMParams.RequiredVersions = $i.RequiredVersions.split(';') }
        if (-not [string]::IsNullOrEmpty($i.Parameters))
        { $UMMParams.AdditionalParameters = $i.Parameters }
        #$UMMParams
        Update-ManagedInstall @UMMParams
    }

}

