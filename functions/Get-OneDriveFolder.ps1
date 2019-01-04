    Function Get-OneDriveFolder {
        
    if (Test-Path HKCU:\Software\Microsoft\OneDrive)
    {$OneDrivePath = (Get-ItemProperty -Path HKCU:\Software\Microsoft\OneDrive -Name UserFolder).UserFolder}
    elseif (Test-Path HKCU:\Software\Microsoft\Windows\CurrentVersion\SkyDrive)
    {$OneDrivePath = (Get-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\SkyDrive -Name UserFolder).UserFolder}
    $OneDrivePath

    }
