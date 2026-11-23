function New-OneDriveQuickAccess
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory,ValueFromPipeline)]
        [psobject]$OneDriveAccount
        ,
        [parameter(Mandatory)]
        [string]$NickName
    )
    if (-not $IsWindows) {
        throw [System.PlatformNotSupportedException]::new('New-OneDriveQuickAccess requires Windows.')
    }
    Set-ItemProperty -path $OneDriveAccount.RegistryPath -name 'NickName' -Value $NickName
}