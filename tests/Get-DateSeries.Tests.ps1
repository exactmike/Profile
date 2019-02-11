$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        $defaultParamCount = 11
        [object[]]$params = (Get-ChildItem "function:\$CommandName").Parameters.Keys
        $knownParameters = 'Start','Interval','Units','Limit','SkipStart'
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
    BeforeAll {
        $vday = Get-Date -Year 2019 -Month 2 -Day 14 -Hour 12 -Minute 0 -Second 0
    }
    AfterAll {
    }
    Context "Validates Input" {
        It "Binds only values that are dateTime to the Start parameter" {
            {Get-DateSeries -Start 'tomorrow' -Interval 3 -Units Days -Limit 3 } | Should Throw
            {Get-DateSeries -Start '2019-02-14' -Interval 3 -Units Days -Limit 3} | Should NOT Throw
            {Get-DateSeries -Start '2019-02-14 11:30:00' -Interval 5 -Units Minutes -Limit 10} | Should NOT Throw
            {Get-DateSeries -Start $vday -Interval 3 -Units Days -Limit 3} | Should NOT Throw
        }
        It "Binds only values that are integers to the Interval parameter" {
            {Get-DateSeries -Start $vday -Interval 4 -Units Days -Limit 3} | Should NOT Throw
            {Get-DateSeries -Start $vday -Interval 'four' -Units Days -Limit 3} | Should Throw
        }
        It "Binds only values that are in the valid set to the Units parameter" {
            {Get-DateSeries -Start $vday -Interval 4 -Units Days -Limit 3} | Should NOT Throw
            {Get-DateSeries -Start $vday -Interval 4 -Units 'Decades' -Limit 3} | Should Throw
        }
        It "Binds only values that are integers in the ValidateRange to the Limit parameter" {
            {Get-DateSeries -Start $vday -Interval 4 -Units Days -Limit 3} | Should NOT Throw
            {Get-DateSeries -Start $vday -Interval 2 -Units Days -Limit 'five'} | Should Throw
            {Get-DateSeries -Start $vday -Interval 2 -Units Days -Limit 0} | Should Throw
        }
    }
    Context "Produces Expected Output" {
        It "Produces the expected number of results" {
            (Get-DateSeries -Start $vday -Interval 4 -Units Days -Limit 5).count | Should Be 5
            (Get-DateSeries -Start $vday -Interval 2 -Units Days -Limit 1 -SkipStart).count | Should Be 1
        }
        $TestCases = @(
            @{
                Interval = 1
                Units = 'Milliseconds'
            }
            @{
                Interval = 5
                Units = 'Milliseconds'
            }
            @{
                Interval = 1
                Units = 'Seconds'
            }
            @{
                Interval = 5
                Units = 'Seconds'
            }
            @{
                Interval = 1
                Units = 'Minutes'
            }
            @{
                Interval = 5
                Units = 'Minutes'
            }
            @{
                Interval = 1
                Units = 'Hours'
            }
            @{
                Interval = 5
                Units = 'Hours'
            }
            @{
                Interval = 1
                Units = 'Days'
            }
            @{
                Interval = 5
                Units = 'Days'
            }
        )
        It -TestCases $TestCases "Produces the expected intervals with built-in datetime units" {
            param($Interval,$Units)
            $results = Get-DateSeries -Start $vday -Interval $Interval -Units $Units -Limit 2
            $($results[1]-$results[0]).$('Total'+ $Units) | Should Be $Interval
        }
        $TestCases = @(
            @{
                Interval = 1
                Units = 'Weeks'
            }
            @{
                Interval = 5
                Units = 'Weeks'
            }
            @{
                Interval = 1
                Units = 'Years'
            }
            @{
                Interval = 5
                Units = 'Years'
            }
        )
        It -TestCases $TestCases "Produces the expected intervals with additional Units" {
            param($Interval,$Units)
            $results = Get-DateSeries -Start $vday -Interval $Interval -Units $Units -Limit 2
            switch ($Units)
            {
                'Years'
                {
                    switch ($Interval)
                    {
                        {$_ -lt 4}
                        {
                            $comparison = @($(365*$Interval);$(365*$interval) + 1)
                        }
                        {$_ -eq 4}
                        {
                            $comparison = @($(365*$interval)+1)
                        }
                        {$_ -gt 4}
                        {
                            if ($interval%4 -eq 0)
                            {$add = $Interval/4}
                            else
                            {$add = [math]::Truncate($($interval/4))}
                            $base = $Interval * 365
                            $comparison = @($($base + $add);$($base + $add + 1))
                        }
                    }
                    $($results[1]-$results[0]).TotalDays | Should BeIn $comparison
                }
                'Weeks'
                {
                    $comparison = $interval * 7
                    $($results[1]-$results[0]).TotalDays | Should Be $comparison
                }
            }
        }
    }
}