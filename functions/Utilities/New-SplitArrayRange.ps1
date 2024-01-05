Function New-SplitArrayRange
{
        
    <#
        .SYNOPSIS
        Provides Start and End Ranges to Split an array into a specified number of parts (new arrays) or parts (new arrays) with a specified number (size) of elements
        .EXAMPLE
        New-SplitArrayRange -InputArray @(1,2,3,4,5,6,7,8,9,10) -parts 3
        .EXAMPLE
        New-SplitArrayRange -InputArray @(1,2,3,4,5,6,7,8,9,10) -size 3
        .NOTE
        Derived from https://gallery.technet.microsoft.com/scriptcenter/Split-an-array-into-parts-4357dcc1#content
        #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)]
        [array]$inputArray # the array you want to split into parts
        ,
        [parameter(Mandatory, ParameterSetName = 'Parts')]
        [parameter(ParameterSetName = 'NVAByParts')]
        [int]$parts # the number of parts to split the array into
        ,
        [parameter(Mandatory, ParameterSetName = 'Size')]
        [parameter(ParameterSetName = 'NVABySize')]
        [int]$size # the number of elements to include in each part, or with NumericValueAttribute, the maximum size of the sum of the NumericValueAttribute
        ,
        [parameter(Mandatory, ParameterSetName = 'NVAByParts')]
        [parameter(Mandatory, ParameterSetName = 'NVABySize')]
        [string]$NumericValueAttribute # Specify the name of an attribute of the input array to user for evenly dividing the array by size or parts
        ,
        [switch]$exp
    )
    switch -wildcard ($PSCmdlet.ParameterSetName)
    {
        'Parts'
        {
            Write-Information -MessageData "Calculating Partsize from desired parts: $parts"
            $PartSize = [Math]::Ceiling($inputArray.count / $parts)
            Write-Information -MessageData "Calculated PartSize = $PartSize"
        }#Parts
        'Size'
        {
            Write-Information -MessageData "Calculating Partsize from desired size: $size"
            $PartSize = $size
            $parts = [Math]::Ceiling($inputArray.count / $size)
            Write-Information -MessageData "Calculated Parts = $parts"
        }#Size
        'NVABy*'
        {
            Write-Verbose 'By NumericValueAttribute'
            switch ($PSCmdlet.ParameterSetName)
            {
                'NVABySize'
                {
                    #$stats = $inputArray | Measure-Object -Property $NumericValueAttribute -AllStats
                    $prefixSum = [System.Collections.Generic.List[decimal]]::new()
                    $e = 0
                    $inputArray.foreach({
                        $prefixSum.add($_.$NumericValueAttribute + $prefixSum[$e-1])
                        $e++
                    })
                    Write-Information -MessageData "Calculating Partsize from desired maximum sum size of attribute $NumericValueAttribute : $size"
                    $PartSize = $size
                }
                'NVAByParts'
                {

                }
            }
        }

    }#switch

    if ($PSCmdlet.ShouldProcess('Calculate Ranges'))
    {
        switch ($PSCmdlet.ParameterSetName)
        {
        ({ $_ -in 'Size', 'Parts' })
            {
                $count = $inputArray.count
                for ($i = 1; $i -le $parts; $i++)
                {
                    $start = (($i - 1) * $PartSize)
                    $end = (($i) * $PartSize) - 1
                    if ($end -ge $count) { $end = $count }
                    $SplitArrayRange = [pscustomobject]@{
                        Part  = $i
                        Start = $start
                        End   = $end
                    }
                    $SplitArrayRange
                }#for   
            }
        ({ $_ -like 'NVABy*' })
            {
                switch ($exp)
                {
                    $true
                    {

                    }
                    $false
                    {
                        #initialize for array processing
                        $count = $inputarray.count
                        $lastelement = $count - 1
                        $p = 1 #part
                        $e = 0 #element
                        $arraydone = $false
                        do
                        {
                            #process the array
                            #initialize for part processing
                            $sum = 0
                            $start = $e
                            $partdone = $false
                            do
                            {
                                #find the next part
                                $sum = $sum + $inputArray[$e].$NumericValueAttribute
                                switch ($sum)
                                {
                                    { $_ -eq $size }
                                    {
                                        $end = $e
                                        $partdone = $true
                                    }
                                    { $_ -gt $size }
                                    {
                                        # go back one element
                                        $sum = $sum - $inputArray[$e].$NumericValueAttribute
                                        $e--
                                        $end = $e
                                        $partdone = $true
                                        continue
                                    }
                                    { $_ -lt $size }
                                    {
                                        if ($e -ge $lastelement)
                                        { $partdone = $true } # for the case where the last group is smaller and will never exceed $size
                                        $e++
                                    }
                                }
                            }
                            until ($partdone)
                            $SplitArrayRange = [pscustomobject]@{
                                Part  = $p
                                Start = $start
                                End   = $end
                                Sum   = $sum
                            }
                            $SplitArrayRange # output the part
                            #prep for next part
                            $p++ # advance part number
                            $e++ # advance element number
                            if ($e -gt $lastelement) # check for all elements processed
                            { $arraydone = $true }
                        }
                        until ($arraydone)
                    }
                }
            }
        }
    }
}
