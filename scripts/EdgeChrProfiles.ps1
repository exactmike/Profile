[cmdletbinding()]
param(
    [parameter(Mandatory)]
    [ValidateScript( { Test-Path -Path $_ -PathType Container })]
    [string]$OutputFolderPath
)
$EdgeProfileDirectories = @(Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Profile *" -Directory; Get-Item -LiteralPath "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\")

$EdgeProfiles = $EdgeProfileDirectories.fullname.foreach( {
        $ProfilePath = $_
        $PreferencesFilePath = Join-Path -Path $ProfilePath -ChildPath Preferences
        $ProfileChildPath = Split-Path -Path $ProfilePath -Leaf
        (ConvertFrom-Json (Get-Content $PreferencesFilePath -Raw)) | Select-Object -Property *, @{n = 'ProfilePath'; e = { $ProfilePath } }, @{n = 'ProfileChildPath'; e = { $ProfileChildPath } }
    })

$EdgeProfiles.foreach( {
        $p = $_
        $ProfileName = $p.profile.name
        switch (Read-Choice -Choices "Yes", "No" -Title "Create Edge Profile Shortcut?" -Message "Do you want to create a shortcut for Edge Profile $ProfileName" -DefaultChoice 0)
        {
            0
            {
                # Create Shortcut on Desktop

                $TargetPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
                $ShortcutFile = Join-Path -Path $OutputFolderPath -ChildPath "$ProfileName.lnk"
                $WScriptShell = New-Object -ComObject WScript.Shell
                $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
                $IconPath = Join-Path -Path $p.ProfilePath -ChildPath 'Edge Profile.ico'
                $Shortcut.IconLocation = "$IconPath, 0"
                $Shortcut.Arguments = "--profile-directory=""$($p.ProfileChildPath)"""
                $Shortcut.TargetPath = $TargetPath
                $Shortcut.Save()
            }
            1
            {
                Write-Information -MessageData "Skipping Shortcut Creation for Profile $ProfileName" -InformationAction Continue
            }
        }
    })