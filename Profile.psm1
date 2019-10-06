$FunctionFiles = Get-ChildItem -Recurse -File -Path $(Join-Path -Path $PSScriptRoot -ChildPath 'Functions')
foreach ($ff in $FunctionFiles) { . $ff.fullname }

enum InstallManager { Chocolatey; Git; PowerShellGet; Manual }