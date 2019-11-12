function Start-KeepAlive {
    $wshell = New-Object -ComObject wscript.shell
    do {$wshell.SendKeys('{SCROLLLOCK}'); Write-Host 'Sleeping 60 Seconds'; Start-Sleep -Seconds 60} until ($false)
}
