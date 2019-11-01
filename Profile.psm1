$FunctionFiles = Get-ChildItem -Recurse -File -Path $(Join-Path -Path $PSScriptRoot -ChildPath 'Functions')
foreach ($ff in $FunctionFiles) { if ($ff.fullname -like '*.ps*1') { . $ff.fullname } }

enum InstallManager { Chocolatey; Git; PowerShellGet; Manual }
