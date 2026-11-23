function Start-KeepAlive
{
    if (-not $IsWindows) {
        throw [System.PlatformNotSupportedException]::new('Start-KeepAlive requires Windows.')
    }
    $wshell = New-Object -ComObject wscript.shell
    do
    {
        $wshell.SendKeys('{F13}')
        Write-Host 'Sleeping 60 Seconds'
        Start-Sleep -Seconds 60
    }
    until ($false)
}
