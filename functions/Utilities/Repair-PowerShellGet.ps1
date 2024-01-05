function Repair-PowerShellGet
{
    param(
        [switch]$FixSecurityProtocol
    )

    switch($FixSecurityProtocol)
    {
        $true
        {
            #ideally add this to all users and shells profile if not set on the machine globally
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        }
    }

    Install-PackageProvider -Name NuGet -Force -Scope AllUsers
    Install-Module -Name PowerShellGet -Force -AllowClobber -Scope AllUsers
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}