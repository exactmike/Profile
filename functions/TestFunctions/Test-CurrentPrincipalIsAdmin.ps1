Function Test-CurrentPrincipalIsAdmin
{
    if (-not $IsWindows) {
        throw [System.PlatformNotSupportedException]::new('Test-CurrentPrincipalIsAdmin requires Windows.')
    }

    $currentPrincipal = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent())
    $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')

}
