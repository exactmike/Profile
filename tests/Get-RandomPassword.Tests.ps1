$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $defaultParamCount = 11
        [object[]]$params = (Get-ChildItem "function:\$CommandName").Parameters.Keys
        $knownParameters = 'Length','CharacterSet'
        $paramCount = $knownParameters.Count
        It "Should contain specific parameters" {
            ( (Compare-Object -ReferenceObject $knownParameters -DifferenceObject $params -IncludeEqual | Where-Object SideIndicator -eq "==").Count ) | Should Be $paramCount
        }
        It "Should only contain $paramCount parameters" {
            $params.Count - $defaultParamCount | Should Be $paramCount
        }
    }
}

Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    Context "Validates Input" {
        It "Binds only values that are Int to the Length parameter" {
            {Get-RandomPassword -length 'two'} | Should Throw
            {Get-RandomPassword -Length 15} | Should NOT Throw
        }
        It "Binds only values that are in the validateSet to the CharacterSet parameter" {
            {Get-RandomPassword -CharacterSet 'Bob'} | Should Throw
            {Get-RandomPassword -CharacterSet 'Any'} | Should NOT Throw
        }
    }
    Context "Produces Expected Output" {
        $TestCases = @(
            @{
                Length = 5
                CharacterSet = 'Any'
            }
            @{
                Length = 15
                CharacterSet = 'Any'
            }
            @{
                Length = 25
                CharacterSet = 'Any'
            }
            @{
                Length = 5
                CharacterSet = 'NoSpecial'
            }
            @{
                Length = 15
                CharacterSet = 'NoSpecial'
            }
            @{
                Length = 25
                CharacterSet = 'NoSpecial'
            }
        )
        It -TestCases $TestCases "Produces the expected password length" {
            param($Length,$CharacterSet)
            $result = Get-RandomPassword -Length $Length -CharacterSet $CharacterSet
            $($result).length | Should Be $Length
        }

        It -TestCases $TestCases "Produces the expected character content" {
<#
            param($Length,$CharacterSet)
            $result = Get-RandomPassword -Length $Length -CharacterSet $CharacterSet
            switch ($CharacterSet)
            {
                'Any'
                {
                    $result
                }
                'NoSpecial'
                {
                    $result
                }
            }

in#>
        }
    }
}