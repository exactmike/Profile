Function Get-OneDriveAccount
{
    [CmdletBinding()]
    param(
        [parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]$DisplayName
        ,
        [parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]$UserEmail
        ,
        [parameter()]
        [AllowNull()]
        [guid[]]$TenantID
    )
    if (Test-Path HKCU:\Software\Microsoft\OneDrive\Accounts -PathType Container)
    {
        @(Get-ChildItem -Path HKCU:\Software\Microsoft\OneDrive\Accounts).foreach(
            { Get-ItemProperty "Registry::$($_.name)" }
        ).where(
            {
                (
                    $null -eq $DisplayName -or [string]::IsNullOrEmpty($DisplayName) -or
                    $_.DisplayName -in $DisplayName -or
                    $(
                        @(foreach ($dn in $DisplayName)
                            {
                                $_.DisplayName -like $dn
                            }) -contains $true)
                ) -and
                (
                    $null -eq $userEmail -or [string]::IsNullOrEmpty($UserEmail) -or
                    $_.UserEmail -in $UserEmail -or
                    $(
                        @(foreach ($ue in $UserEmail)
                            {
                                $_.UserEmail -like $ue
                            }) -contains $true)
                ) -and
                (
                    $null -eq $TenantID -or
                    $_.ConfiguredTenantId -in @($TenantID.foreach( { $_.guid }))
                )
            }
        )

    }

}
