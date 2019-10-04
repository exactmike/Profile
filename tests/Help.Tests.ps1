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

Describe "Public commands in $script:ModuleName have comment-based or external help" -Tags 'Build' {
    $functions = Get-Command -Module $Script:ModuleName
    $help = foreach ($function in $functions)
    {
        Get-Help -Name $function.Name
    }

    foreach ($node in $help)
    {
        Context $node.Name {
            It "Should have a Description or Synopsis" {
                ($node.Description + $node.Synopsis) | Should Not BeNullOrEmpty
            }

            It "Should have an Example" {
                $node.Examples | Should Not BeNullOrEmpty
                $node.Examples | Out-String | Should -Match ($node.Name)
            }

            foreach ($parameter in $node.Parameters.Parameter)
            {
                if ($parameter -notmatch 'WhatIf|Confirm')
                {
                    It "Should have a Description for Parameter [$($parameter.Name)]" {
                        $parameter.Description.Text | Should Not BeNullOrEmpty
                    }
                }
            }
        }
    }
}

Write-Information -MessageData "Removing Module $Script:ModuleName" -InformationAction Continue
Remove-Module -Name $Script:ModuleName -Force -ErrorAction SilentlyContinue