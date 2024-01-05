function Invoke-SessionAS
{
    param(
        [parameter(Mandatory)]
        [string]$Identity
        ,
        [switch]$SaveCredential
        ,
        [parameter()]
        [ValidateSet('PWSH', 'Powershell', 'CMD')]
        [string]$CLI = 'PWSH'
    )
    switch ($SaveCredential)
    {
        $true
        {
            runas /savecred /user:$Identity "$CLI -noexit"
        }
        $false
        {
            runas /user:$Identity "$CLI -noexit"
        }
    }

}