Function Compare-ComplexObject
{
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
        ,
        [parameter()]
        [switch]$DisableBoolNonBoolEquality
    )

    #setup properties to compare
    #get properties from the Reference Object
    $RefProperties = @($ReferenceObject | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name | Sort-Object)
    Write-Verbose -Message "Reference Object Properties = $($RefProperties -join ' | ')"
    #get properties from the Difference Object
    $DifProperties = @($DifferenceObject | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name | Sort-Object)
    Write-Verbose -Message "Difference Object Properties = $($DifProperties -join ' | ')"
    #Get unique properties from the resulting list, eliminating duplicate entries and sorting by name
    $ComparisonProperties = @(@($RefProperties; $DifProperties) | Select-Object -Unique | Sort-Object)
    Write-Verbose -Message "Comparison Properties = $($ComparisonProperties -join ' | ')"
    #remove properties where they are entries in the $suppressedProperties parameter
    $ComparisonProperties = $ComparisonProperties | Where-Object { $SuppressedProperties -notcontains $_ }
    Write-Verbose -Message "Comparison Properties after SuppressedProperties Removed = $($ComparisonProperties -join ' | ')"

    $results = @(
        foreach ($prop in $ComparisonProperties)
        {
            $property = $prop.ToString()
            Write-Verbose -Message "Comparing $property"
            $ReferenceObjectValue = @($ReferenceObject.$($property))
            $DifferenceObjectValue = @($DifferenceObject.$($property))
            switch ($ReferenceObjectValue.Count)
            {
                1
                {
                    if ($DifferenceObjectValue.Count -eq 1)
                    {
                        $ComparisonType = 'Scalar'
                        switch ($null -eq $ReferenceObjectValue[0] -and $null -eq $DifferenceObjectValue[0])
                        {
                            $true
                            {
                                #remove null case from processing
                                $CompareResult = $true
                            }
                            $false
                            {
                                if ($null -eq $ReferenceObjectValue[0] -or $null -eq $DifferenceObjectValue[0])
                                {
                                    $CompareResult = $false #both values are not null
                                }
                                else #neither value is null
                                {

                                    $RefType = $ReferenceObjectValue[0].GetTypeCode()
                                    $DifType = $DifferenceObjectValue[0].GetTypeCode()

                                    switch ($RefType -eq $DifType)
                                    {
                                        $true
                                        {
                                            If ($ReferenceObjectValue[0] -eq $DifferenceObjectValue[0]) { $CompareResult = $true }
                                            If ($ReferenceObjectValue[0] -ne $DifferenceObjectValue[0]) { $CompareResult = $false }
                                        }
                                        $false
                                        {
                                            switch ($true)
                                            {
                                                { ($RefType -eq 'Boolean' -and $DifType -eq 'String') -or ($RefType -eq 'String' -and $DifType -eq 'Boolean') }
                                                {
                                                    switch ($DisableBoolNonBoolEquality)
                                                    {
                                                        $true
                                                        {
                                                            $CompareResult = $false #ref and dif are not the same type
                                                        }
                                                        $false
                                                        {
                                                            switch ($RefType -eq 'Boolean')
                                                            {
                                                                $true
                                                                {
                                                                    #$RefType is Boolean therefore $Diftype is String
                                                                    If ($ReferenceObjectValue[0] -eq $true -and $DifferenceObjectValue[0] -eq 'true') { $CompareResult = $true }
                                                                    If ($ReferenceObjectValue[0] -eq $false -and $DifferenceObjectValue[0] -eq 'false') { $CompareResult = $true }
                                                                    If ($ReferenceObjectValue[0] -eq $true -and $DifferenceObjectValue[0] -eq 'false') { $CompareResult = $false }
                                                                    If ($ReferenceObjectValue[0] -eq $false -and $DifferenceObjectValue[0] -eq 'true') { $CompareResult = $false }
                                                                }
                                                                $false
                                                                {
                                                                    #RefType is not Boolean and therefore string and $DifType is Boolean
                                                                    If ($DifferenceObjectValue[0] -eq $true -and $ReferenceObjectValue[0] -eq 'true') { $CompareResult = $true }
                                                                    If ($DifferenceObjectValue[0] -eq $false -and $ReferenceObjectValue[0] -eq 'false') { $CompareResult = $true }
                                                                    If ($DifferenceObjectValue[0] -eq $true -and $ReferenceObjectValue[0] -eq 'false') { $CompareResult = $false }
                                                                    If ($DifferenceObjectValue[0] -eq $false -and $ReferenceObjectValue[0] -eq 'true') { $CompareResult = $false }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                Default
                                                {
                                                    switch ($DisableBoolNonBoolEquality)
                                                    {
                                                        $true
                                                        {
                                                            switch ($RefType -eq 'Boolean' -or $DifType -eq 'Boolean')
                                                            {
                                                                $true
                                                                {
                                                                    $CompareResult = $false # types are not the same
                                                                }
                                                                $false
                                                                {
                                                                    If ($ReferenceObjectValue[0] -eq $DifferenceObjectValue[0]) { $CompareResult = $true }
                                                                    If ($ReferenceObjectValue[0] -ne $DifferenceObjectValue[0]) { $CompareResult = $false }
                                                                }
                                                            }
                                                        }
                                                        $false
                                                        {
                                                            If ($ReferenceObjectValue[0] -eq $DifferenceObjectValue[0]) { $CompareResult = $true }
                                                            If ($ReferenceObjectValue[0] -ne $DifferenceObjectValue[0]) { $CompareResult = $false }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }#if
                    else
                    {
                        $ComparisonType = 'ScalarToArray'
                        $CompareResult = $false
                    }
                }
                0
                {
                    $ComparisonType = 'ZeroCountArray'
                    $ComparisonResults = @(Compare-Object -ReferenceObject $ReferenceObjectValue -DifferenceObject $DifferenceObjectValue -PassThru)
                    if ($ComparisonResults.Count -eq 0) { $CompareResult = $true }
                    elseif ($ComparisonResults.Count -ge 1) { $CompareResult = $false }
                }
                Default
                {
                    $ComparisonType = 'Array'
                    $ComparisonResults = @(Compare-Object -ReferenceObject $ReferenceObjectValue -DifferenceObject $DifferenceObjectValue -PassThru)
                    if ($ComparisonResults.Count -eq 0) { $CompareResult = $true }
                    elseif ($ComparisonResults.Count -ge 1) { $CompareResult = $false }
                }
            }
            $ComparisonObject = New-Object -TypeName PSObject -Property @{Property = $property; CompareResult = $CompareResult; ReferenceObjectValue = $ReferenceObjectValue; DifferenceObjectValue = $DifferenceObjectValue; ComparisonType = $comparisontype }
            $ComparisonObject | Select-Object -Property Property, CompareResult, ReferenceObjectValue, DifferenceObjectValue #,ComparisonType
        }
    )
    switch ($show)
    {
        'All' { $results }#All
        'EqualOnly' { $results | Where-Object { $_.CompareResult } }#EqualOnly
        'DifferentOnly' { $results | Where-Object { -not $_.CompareResult } }#DifferentOnly
    }

}
