function New-OneDriveQuickAccess
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [psobject]$OneDriveAccount
        ,
        [parameter(Mandatory)]
        [string]$NickName
    )
    Set-ItemProperty -path $OneDriveAccount.RegistryPath -name 'NickName' -Value $NickName
}