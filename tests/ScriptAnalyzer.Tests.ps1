$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
$Script:ModuleRoot = $(Split-Path -Path $PSScriptRoot -Parent)
Write-Information -MessageData "Module Root is $script:ModuleRoot" -InformationAction Continue
$Script:ModuleName = $(Split-Path -$Script:ModuleRoot -Leaf)
Write-Information -MessageData "Module Name is $Script:ModuleName" -InformationAction Continue
$Script:ModuleFile = $Script:ModuleFile = Join-Path -Path $($Script:ModuleRoot) -ChildPath $($Script:ModuleName + '.psm1')
Write-Information -MessageData "Module File is $($script:ModuleFile)" -InformationAction Continue
$Script:ModuleSettingsFile = Join-Path -Path $($Script:ModuleRoot) -ChildPath $($Script:ModuleName + '.psd1')
Write-Information -MessageData "Module Settings File is $($script:ModuleSettingsFile)" -InformationAction Continue

Describe "All commands pass PSScriptAnalyzer rules" -Tag 'Build' {
    $rules = "$Script:ModuleRoot\ScriptAnalyzerSettings.psd1"
    $scripts = Get-ChildItem -Path $ModuleRoot -Include '*.ps1', '*.psm1', '*.psd1' -Recurse -Exclude 'ScriptAnalyzerSettings.psd1' |
        Where-Object -filterscript { $_.FullName -notmatch 'Classes' -and $_.FullName -notmatch 'Tests' }

    foreach ($script in $scripts)
    {
        Context $script.FullName {
            $results = Invoke-ScriptAnalyzer -Path $script.FullName -Settings $rules
            if ($results)
            {
                foreach ($rule in $results)
                {
                    It $("Should {0} Severity:{1} Line {2}: {3}" -f $rule.RuleName, $rule.Severity, $rule.Line, $rule.Message) {
                        $message = "violated"
                        $message | Should Be ""
                    }
                }
            }
            else
            {
                It "Should not fail any rules" {
                    $results | Should BeNullOrEmpty
                }
            }
        }
    }
}
