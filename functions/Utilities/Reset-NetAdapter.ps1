function Reset-NetAdapter
{
  param(
    [parameter()]
    [validateSet('Wi-Fi')]
    $Name
  )

  Get-NetAdapter -Name $Name | Disable-NetAdapter -passthru -confirm:$false | Enable-NetAdapter
}