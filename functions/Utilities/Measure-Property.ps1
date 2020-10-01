Function Measure-Property
{
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'HashTable')]
        [Alias('AHT')]
        [switch]
        $AsHashTable,

        [Parameter(ValueFromPipeline = $true)]
        [psobject[]]
        $InputObject,

        [Parameter(Position = 0, Mandatory)]
        [string]
        $Property,

        [string]
        ${Culture},

        [switch]
        ${CaseSensitive})

    begin
    {
        try
        {
            $GroupObjectParams = @{ } + $PSBoundParameters
            #We never want an element with this version
            $GroupObjectParams['NoElement'] = $true
            #We never want group-object itself to create a hashtable
            $GroupObjectParams['AsHashTable'] = $false
            if ($true -eq $PSBoundParameters['AsHashTable'])
            {
                $hashtable = @{ }
            }
            $InputObjects = [System.Collections.ArrayList]::new()
        }
        catch
        {
            throw
        }
    }

    process
    {
        try
        {
            $null = $InputObjects.Add($_)
        }
        catch
        {
            throw
        }
    }

    end
    {
        try
        {
            $groups = $InputObjects | Group-Object @GroupObjectParams
            if ($true -eq $PSBoundParameters['AsHashTable'])
            {
                $groups | ForEach-Object { $hashtable["$($_.Name)"] = $_.Count }
                $hashtable
            }
            else
            {
                $groups | ForEach-Object { [pscustomobject]@{Name = $_.Name; Count = $_.Count; } }
            }
        }
        catch
        {
            throw
        }
    }
}