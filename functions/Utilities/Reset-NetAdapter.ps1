function Reset-NetAdapter
{
  param(
    [parameter()]
    [validateSet('Wi-Fi')]
    $Name
  )
  if (-not $IsWindows) {
      throw [System.PlatformNotSupportedException]::new('Reset-NetAdapter requires Windows.')
  }

  Get-NetAdapter -Name $Name | Disable-NetAdapter -passthru -confirm:$false | Enable-NetAdapter
}