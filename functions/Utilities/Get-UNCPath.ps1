    Function Get-UNCPath {
        
    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [validatescript({Test-Path -Path $_})]
        [string[]]$Path = $(Get-Location).Path
    )
    begin
    {
        function Get-ContainerUNCPath
        {
            param(
                $ContainerPath
            )
            Push-Location
            Set-Location -Path $ContainerPath
            $loc = Get-Location
            if ($null -eq $loc.Drive) {$loc.ProviderPath}
            else {
                switch ($null -eq $loc.Drive.DisplayRoot)
                {
                    $true #not a network mapped drive - is local drive.
                    {
                        Join-Path -path (Join-Path -Path $('\\' + [System.Environment]::MachineName) -ChildPath $($loc.Drive.Name + '$')) -ChildPath $loc.Drive.CurrentLocation
                    }
                    $false #is a network mapped drive
                    {
                        Join-Path -Path $loc.Drive.DisplayRoot -ChildPath $loc.Drive.CurrentLocation
                    }
                }
            }
            Pop-Location
        }
    }
    process
    {
        foreach ($p in $Path)
        {
            $item = Get-Item -Path $p
            switch ($item.PSIsContainer)
            {
                $true
                {
                    Get-ContainerUNCPath -ContainerPath $item.FullName
                }
                $false
                {
                    Join-Path -Path $(Get-ContainerUNCPath -ContainerPath $(Split-Path -Path $item.FullName -Parent)) -ChildPath $item.name
                }
            }
        }
    }

    }
