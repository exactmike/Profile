<#
.SYNOPSIS
    Compares one object to another object at the attribute level.
    Does what you might expect Compare-Object to do but Compare-Object only compares SETS of objects and is most effective at comparing simple arrays.
    Compare-ComplexObject actually compares two objects at the attribute level to give a report of similarities and differences.
.DESCRIPTION
    Compares one object to anotehr object and outputs an object summarizing the similarities and / or differences of each attribute.
    The first object is the reference object and the second object is the difference object.
    Compare-ComplexObject is useful for generating a differences object between a before and after of a configuration of an object or for updating only changed attributes between objects stored in differents systems.
.NOTES
    This function, by default, overrides the default Powershell comparison of boolean $false to string 'false'.  The function returns TRUE, meaning equality, in this case.
    The reason for the override is that the default Powershell comparison of string 'false' to boolean 'false' returns TRUE, so for the purposes of this function the revers should return true as well.
    When using switch parameter DisableBoolNonBoolEquality, all of Powershell's default comparisons between boolean $true or $false and other object types are overridden.
    When using DisableBoolNonBoolEquality, the compared values must both be of type Boolean and the same value to get a TRUE comparison result.

.EXAMPLE
    # Define the first user
    $user1 = [PSCustomObject]@{
        FirstName  = 'Arvind'
        LastName   = 'Sharma'
        Location   = 'New York'
        LocationCountry = 'US'
        EmployeeID = 'A12345'
        Email      = 'arvind.sharma@example.com'
        EmployeeType = 'FullTime'
        Codes = @('alpha','beta','gamma')
        Active = $true
        OnLeave = $false
    }

    # Define the second user
    $user2 = [PSCustomObject]@{
        FirstName  = 'Carla'
        LastName   = 'Martinez'
        Location   = 'Los Angeles'
        LocationCountry = 'US'
        EmployeeID = 'C67890'
        Email      = 'carla.martinez@example.com'
        EmployeeType = 'FullTime'
        Codes = @('beta','gamma')
        Active = 'true'
        OnLeave = 'false'
    }

    Compare-ComplexObject -ReferenceObject $user1 -DifferenceObject $user2 # Default shows ALL comparisons

    Property        CompareResult ReferenceObjectValue        DifferenceObjectValue
    --------        ------------- --------------------        ---------------------
    Active                   True {True}                      {true}
    Codes                   False {alpha, beta, gamma}        {beta, gamma}
    Email                   False {arvind.sharma@example.com} {carla.martinez@example.com}
    EmployeeID              False {A12345}                    {C67890}
    EmployeeType             True {FullTime}                  {FullTime}
    FirstName               False {Arvind}                    {Carla}
    LastName                False {Sharma}                    {Martinez}
    Location                False {New York}                  {Los Angeles}
    LocationCountry          True {US}                        {US}
    OnLeave                  True {False}                     {false}

    Compare-ComplexObject -ReferenceObject $user1 -DifferenceObject $user2 -Show DifferentOnly

    Property   CompareResult ReferenceObjectValue        DifferenceObjectValue
    --------   ------------- --------------------        ---------------------
    Codes              False {alpha, beta, gamma}        {beta, gamma}
    Email              False {arvind.sharma@example.com} {carla.martinez@example.com}
    EmployeeID         False {A12345}                    {C67890}
    FirstName          False {Arvind}                    {Carla}
    LastName           False {Sharma}                    {Martinez}
    Location           False {New York}                  {Los Angeles}

    Compare-ComplexObject -ReferenceObject $user1 -DifferenceObject $user2 -Show EqualOnly

    Property        CompareResult ReferenceObjectValue DifferenceObjectValue
    --------        ------------- -------------------- ---------------------
    Active                   True {True}               {true}
    EmployeeType             True {FullTime}           {FullTime}
    LocationCountry          True {US}                 {US}
    OnLeave                  True {False}              {false}

    Compare-ComplexObject -ReferenceObject $user1 -DifferenceObject $user2 -show DifferentOnly -DisableBoolNonBoolEquality

    Property   CompareResult ReferenceObjectValue        DifferenceObjectValue
    --------   ------------- --------------------        ---------------------
    Active             False {True}                      {true}
    Codes              False {alpha, beta, gamma}        {beta, gamma}
    Email              False {arvind.sharma@example.com} {carla.martinez@example.com}
    EmployeeID         False {A12345}                    {C67890}
    FirstName          False {Arvind}                    {Carla}
    LastName           False {Sharma}                    {Martinez}
    Location           False {New York}                  {Los Angeles}
    OnLeave            False {False}                     {false}
#>


Function Compare-ComplexObject
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        $ReferenceObject # The Reference Object for the comparison
        ,
        [Parameter(Mandatory)]
        $DifferenceObject # The Difference Object for the comparison
        ,
        [parameter()]
        [Alias('ExcludeProperty')]
        [string[]]$SuppressedProperties # Properties to leave out of the comparison
        ,
        [parameter()]
        [Alias('Include')]
        [validateset('All', 'EqualOnly', 'DifferentOnly')]
        [string]$Show = 'All' # Specifies which comparison results to include in the output
        ,
        [parameter()]
        [switch]$DisableBoolNonBoolEquality # Forces Boolean to Boolean comparison, overriding Powershell default Boolean to other type behavior. If used, the compared properties must both be Boolean for a TRUE response to be possible.
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
