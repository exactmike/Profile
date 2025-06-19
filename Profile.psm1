# Import Core Module Functions

$FunctionsFolder = Join-Path -Path $PSScriptRoot -ChildPath 'functions'
Write-Verbose -Message "Finding Functions from $FunctionsFolder"
$FunctionFiles = Get-ChildItem -Recurse -File -Path $FunctionsFolder
Write-Verbose -Message "Found $($FunctionFiles.count) Function Files To Load"
foreach ($ff in $FunctionFiles) { if ($ff.fullname -like '*.ps1') { . $ff.fullname } }


# Run Module Environment Setup
$GetTimeZoneIDsScriptBlock = {
    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    $CompletionNames = @([System.TimeZoneInfo]::GetSystemTimeZones()).where({
        $_.ID -like "$wordToComplete*"}).ID

    foreach ($n in $CompletionNames)
    {
      [System.Management.Automation.CompletionResult]::new($n, $n, 'ParameterValue', $n)
    }
}
$GetTimeZoneNamesScriptBlock = {
    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameters
    )

    $CompletionNames = @([System.TimeZoneInfo]::GetSystemTimeZones()).where({
        $_.StandardName -like "$wordToComplete*"}).StandardName

    foreach ($n in $CompletionNames)
    {
      [System.Management.Automation.CompletionResult]::new($n, $n, 'ParameterValue', $n)
    }
}

Register-ArgumentCompleter -CommandName @(
  'Get-TimeInZone'
) -ParameterName 'TimeZoneID' -ScriptBlock $GetTimeZoneIDsScriptBlock
Register-ArgumentCompleter -CommandName @(
  'Get-TimeInZone'
) -ParameterName 'TimeZoneName' -ScriptBlock $GetTimeZoneNamesScriptBlock