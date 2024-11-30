$FunctionsFolder = Join-Path -Path $PSScriptRoot -ChildPath 'functions'
Write-Verbose -Message "Finding Functions from $FunctionsFolder"
$FunctionFiles = Get-ChildItem -Recurse -File -Path $FunctionsFolder
Write-Verbose -Message "Found $($FunctionFiles.count) Function Files To Load"
foreach ($ff in $FunctionFiles) { if ($ff.fullname -like '*.ps1') { . $ff.fullname } }
