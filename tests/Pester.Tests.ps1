$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
$Script:ModuleRoot = $(Split-Path -Path $PSScriptRoot -Parent)
Write-Information -MessageData "Module Root is $script:ModuleRoot" -InformationAction Continue
$Script:ModuleName = $(Split-Path -$Script:ModuleRoot -Leaf)
Write-Information -MessageData "Module Name is $Script:ModuleName" -InformationAction Continue
$Script:ModuleFile = $Script:ModuleFile = Join-Path -Path $($Script:ModuleRoot) -ChildPath $($Script:ModuleName + '.psm1')
Write-Information -MessageData "Module File is $($script:ModuleFile)" -InformationAction Continue
$Script:ModuleSettingsFile = Join-Path -Path $($Script:ModuleRoot) -ChildPath $($Script:ModuleName + '.psd1')
Write-Information -MessageData "Module Settings File is $($script:ModuleSettingsFile)" -InformationAction Continue

Write-Information -MessageData "Removing Module $Script:ModuleName" -InformationAction Continue
Remove-Module -Name $Script:ModuleName -Force -ErrorAction SilentlyContinue
Write-Information -MessageData "Import Module $Script:ModuleName" -InformationAction Continue
Import-Module -Name $Script:ModuleSettingsFile -Force

Describe "Public commands have Pester tests" -Tag 'Build' {
    $commands = Get-Command -Module $Script:ModuleName

    foreach ($command in $commands.Name)
    {
        $file = Get-ChildItem -Path "$Script:ModuleRoot\Tests" -Include "$command.Tests.ps1" -Recurse
        It "Should have a Pester test for [$command]" {
            $file.FullName | Should Not BeNullOrEmpty
        }
    }
}

Write-Information -MessageData "Removing Module $Script:ModuleName" -InformationAction Continue
Remove-Module -Name $Script:ModuleName -Force -ErrorAction SilentlyContinue