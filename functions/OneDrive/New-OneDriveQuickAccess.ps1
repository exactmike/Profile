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
    Set-ItemProperty -path $OneDriveAccount.RegistryPath -name 'NickName' -Value $NickName
}