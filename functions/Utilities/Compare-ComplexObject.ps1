    Function Compare-ComplexObject {
        
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        $ReferenceObject
        ,
        [Parameter(Mandatory)]
        $DifferenceObject
        ,
        [string[]]$SuppressedProperties
        ,
        [parameter()]
        [validateset('All', 'EqualOnly', 'DifferentOnly')]
        [string]$Show = 'All'
    )#param
    #setup properties to compare
    #get properties from the Reference Object
    $RefProperties = @($ReferenceObject | get-member -MemberType Properties | Select-Object -ExpandProperty Name)
    #get properties from the Difference Object
    $DifProperties = @($DifferenceObject | get-member -MemberType Properties | Select-Object -ExpandProperty Name)
    #Get unique properties from the resulting list, eliminating duplicate entries and sorting by name
    $ComparisonProperties = @(($RefProperties + $DifProperties) | Select-Object -Unique | Sort-Object)
    #remove properties where they are entries in the $suppressedProperties parameter
    $ComparisonProperties = $ComparisonProperties | where-object {$SuppressedProperties -notcontains $_}
    $results = @()
    foreach ($prop in $ComparisonProperties)
    {
        $property = $prop.ToString()
        $ReferenceObjectValue = @($ReferenceObject.$($property))
        $DifferenceObjectValue = @($DifferenceObject.$($property))
        switch ($ReferenceObjectValue.Count)
        {
            1
            {
                if ($DifferenceObjectValue.Count -eq 1)
                {
                    $ComparisonType = 'Scalar'
                    If ($ReferenceObjectValue[0] -eq $DifferenceObjectValue[0]) {$CompareResult = $true}
                    If ($ReferenceObjectValue[0] -ne $DifferenceObjectValue[0]) {$CompareResult = $false}
                }#if
                else
                {
                    $ComparisonType = 'ScalarToArray'
                    $CompareResult = $false
                }
            }#1
            0
            {
                $ComparisonType = 'ZeroCountArray'
                $ComparisonResults = @(Compare-Object -ReferenceObject $ReferenceObjectValue -DifferenceObject $DifferenceObjectValue -PassThru)
                if ($ComparisonResults.Count -eq 0) {$CompareResult = $true}
                elseif ($ComparisonResults.Count -ge 1) {$CompareResult = $false}
            }#0
            Default
            {
                $ComparisonType = 'Array'
                $ComparisonResults = @(Compare-Object -ReferenceObject $ReferenceObjectValue -DifferenceObject $DifferenceObjectValue -PassThru)
                if ($ComparisonResults.Count -eq 0) {$CompareResult = $true}
                elseif ($ComparisonResults.Count -ge 1) {$CompareResult = $false}
            }#Default
        }#switch
        $ComparisonObject = New-Object -TypeName PSObject -Property @{Property = $property; CompareResult = $CompareResult; ReferenceObjectValue = $ReferenceObjectValue; DifferenceObjectValue = $DifferenceObjectValue; ComparisonType = $comparisontype}
        $results +=
        $ComparisonObject | Select-Object -Property Property, CompareResult, ReferenceObjectValue, DifferenceObjectValue #,ComparisonType
    }#foreach
    switch ($show)
    {
        'All' {$results}#All
        'EqualOnly' {$results | Where-Object {$_.CompareResult}}#EqualOnly
        'DifferentOnly' {$results |Where-Object {-not $_.CompareResult}}#DifferentOnly
    }#switch $show

    }
