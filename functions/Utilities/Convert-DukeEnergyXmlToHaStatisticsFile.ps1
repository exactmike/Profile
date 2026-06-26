function Convert-DukeEnergyXmlToHaStatisticsFile
{
    <#
    .SYNOPSIS
    Converts Duke Energy (ESPI / Green Button) interval XML into an hourly, cumulative
    counter time series suitable for the homeassistant-statistics importer.

    .DESCRIPTION
    Duke Energy provides 30-minute interval deltas (kWh per interval). Home Assistant long-term
    statistics for the Energy dashboard use hourly timestamps (minutes must be 00).
    This function:
      1) Parses IntervalReading nodes (epoch start + kWh value).
      2) Buckets readings into hourly totals.
      3) Reconstructs a cumulative counter (state/sum) per hour.
      4) Fills in any missing hours (not expected but just in case)
      5) Optionally, limits the data imported to a specific window, or only data after a certain point.
      4) Writes a CSV/TSV with columns: statistic_id, unit, start, state, sum.

    By default, timestamps are always emitted in UTC ("UTC") to avoid DST repeated-hour ambiguity.
    After export of a file from this function the statistics may be imported to Home Assistant using
    https://github.com/klausj1/homeassistant-statistics

    NOTE: After first use, if you download additional Duke Energy XML files to process and import to Home Assistant,
    you must use the LastImportedTotalKwh and LastImportedStartUtc to avoid invalid data import.

    .PARAMETER XmlFilePath
    Path to the DukeEnergyUsage.xml file you manually downloaded.

    .PARAMETER OutputFolderPath
    Folder Path to which to output the resulting file.  The file will be automatically named after your
    StatisticId with any special characters replaced with _ and a date stamp like yyyyMMddHHmm
    Full file name like StatisticIDAsOfyyyyMMddHHmm.csv.

    .PARAMETER StatisticId
    Statistic identifier to import. Use ':' for "external" statistics (recommended),
    e.g. 'sensor:duke_energy_consumption'. Change this only if you want a fresh statistic.
    Defaults to 'sensor:duke_energy_consumption'.

    .PARAMETER Unit
    Unit of measurement. For energy consumption, this should be 'kWh'.

    .PARAMETER LastImportedTotalKwh
    Starting cumulative total to align imports. For a brand-new statistic, keep 0.
    If you are appending/importing overlapping ranges and want continuity with existing
    data, set this to the cumulative total at the hour BEFORE the first hour you will be importing.

    .PARAMETER LastImportedStartUtc
    UTC timestamp (hour start) of the latest imported row; only rows after this time will be written.
    Duke's provided xml files seem to always include 2 years of history plus one month and end at start of the last UTC day.

    .PARAMETER FillMissingHours
    Inserts rows for missing hours with 0 usage (cumulative stays flat).
    This avoids gaps in graphs if the source data is missing an hour.
    Defaults to true unless specifically set to $false.

    .PARAMETER Delimiter
    Delimiter character for the output file. Default comma. Use "`t" for TSV.

    .PARAMETER StartUtc
    Optional UTC lower bound (inclusive) to limit imported data, based on the reading's
    interval start time. Use with caution -  the value for LastImportedTotalKwh must be coordinated with your sensor's existing imported data, if any.

    .PARAMETER EndUtc
    Optional UTC upper bound (exclusive) to limit imported data, based on the reading's
    interval start time.

    .EXAMPLE
    Convert-DukeEnergyXmlToHaStatisticsFile -XmlFilePath .\DukeEnergyUsage.xml `
      -OutputFolderPath c:\LocalFiles\
      -StatisticId 'sensor:duke_energy_consumption'
      -InitialImport

    Then copy duke_energy_import.csv into your HA /config and call:
    import_statistics.import_from_file with timezone_identifier='UTC', delimiter=','
    #>
    [CmdletBinding(DefaultParameterSetName = 'DeltaImport')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string] $XmlFilePath
        ,
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string] $OutputFolderPath
        ,
        [Parameter()]
        [string] $StatisticId = 'sensor:duke_energy_consumption'
        ,
        [Parameter(ParameterSetName = 'DeltaImport', Mandatory)]
        [Parameter(ParameterSetName = 'InitialImport')]
        [ValidateRange(0, 1e12)]
        [double] $LastImportedTotalKwh
        ,
        [Parameter(ParameterSetName = 'DeltaImport', Mandatory)]
        [datetime] $LastImportedStartUtc
        ,
        [Parameter()]
        [bool]$FillMissingHours = $true
        ,
        [Parameter()]
        [bool]$RequireFullHours = $true
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $Delimiter = ','
        ,
        [Parameter()]
        [datetime] $StartUtc
        ,
        [Parameter()]
        [datetime] $EndUtc
        ,
        [parameter(ParameterSetName = 'InitialImport')]
        [switch]$InitialImport
    )

    Set-StrictMode -Version Latest
    if ($PSCmdlet.ParameterSetName -eq 'InitialImport' -and -not $PSBoundParameters.ContainsKey('LastImportedTotalKwh'))
    {
        $LastImportedTotalKwh = 0.0
    }

    # Namespaces for Atom + ESPI
    $ns = @{
        atom = 'http://www.w3.org/2005/Atom'
        espi = 'http://naesb.org/espi'
    }

    # Output timestamp format required by the importer: dd.MM.yyyy HH:mm (minutes must be 00)
    Write-Information -MessageData 'Setting Output timestamp format to HA long term statistics pattern dd.MM.yyyy HH:mm'
    $startFormat = 'dd.MM.yyyy HH:mm'

    # Output File Path
    $DateString = Get-Date -Format yyyyMMddHHmm
    $FileNamePart = $StatisticId -replace '[^A-Za-z0-9_-]', '_'
    $OutputFileName = $FileNamePart + 'AsOf' + $DateString + '.csv'
    $OutputFilePath = Join-Path -Path $OutputFolderPath -ChildPath $OutputFileName
    Write-Information -MessageData "set output file path to $OutputFilePath"

    # Parse XML with native PowerShell/.NET XML support
    Write-Information -MessageData "Getting Content of XML file $XmlFilePath"
    [xml] $xml = Get-Content -LiteralPath $XmlFilePath -Raw
    # Bind the namespace manager to this XML's NameTable and register prefixes once
    $nsmgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $nsmgr.AddNamespace('atom', $ns.atom)
    $nsmgr.AddNamespace('espi', $ns.espi)

    # --- Source metadata from <espi:interval> (Duke-specific structure) ---
    $intervalNode = (Select-Xml -Xml $xml -Namespace $ns -XPath '//espi:interval' | Select-Object -First 1).Node
    if (-not $intervalNode)
    {
        throw 'Could not find //espi:interval in the XML. Cannot determine unitOfMeasure/secondsPerInterval.'
    }

    $uomNode = $intervalNode.SelectSingleNode('espi:unitOfMeasure', $nsmgr)
    $spiNode = $intervalNode.SelectSingleNode('espi:secondsPerInterval', $nsmgr)

    if (-not $uomNode -or -not $spiNode)
    {
        throw 'Missing espi:unitOfMeasure or espi:secondsPerInterval under //espi:interval.'
    }

    $unitOfMeasure = ($uomNode.InnerText).Trim()
    # Normalize UnitOfMeasure to HA expected case
    [int]$secondsPerInterval = ($spiNode.InnerText).Trim()

    Write-Information -MessageData "Interval metadata: unitOfMeasure='$unitOfMeasure', secondsPerInterval=$secondsPerInterval"

    # Determine how many intervals constitute one hour (used by RequireFullHours)
    if (3600 % $secondsPerInterval -ne 0)
    {
        throw "secondsPerInterval=$secondsPerInterval does not divide evenly into 3600; cannot enforce full hours safely."
    }
    $expectedPerHour = [int](3600 / $secondsPerInterval)

    # Normalize interval values to kWh
    # Duke uses 'kWH' (case-insensitive). We'll accept kWh and Wh variants.
    $kwhMultiplier = 1.0
    switch -Regex ($unitOfMeasure)
    {
        '^kwh$' { $kwhMultiplier = 1.0; $unitOfMeasure = 'kWh'; break } # kWh is the case-sensitive expected value of Home Assistant
        '^wh$' { $kwhMultiplier = 1.0 / 1000.0; $unitOfMeasure = 'Wh'; break } # Wh is the case-sensitive expected value of Home Assistant
        default
        {
            throw "Unsupported unitOfMeasure='$unitOfMeasure'. Expected kWh/kWH or Wh."
        }
    }

    Write-Information -MessageData "Value normalization: multiplier-to-kWh = $kwhMultiplier (unitOfMeasure='$unitOfMeasure')"

    # Extract all IntervalReading nodes
    Write-Information -MessageData "Selecting Interval Reading Nodes"
    $readings = Select-Xml -Xml $xml -Namespace $ns -XPath '//espi:IntervalReading'
    if (-not $readings) { throw 'No espi:IntervalReading nodes found. Is this the expected Duke ESPI XML?' }

    # Hourly aggregation bucket: [DateTime (hour start)] -> sum(kWh)
    $hourly = @{}
    $hourlyCount = @{}


    Write-Information -MessageData 'Iterating through Interval Reading Nodes'
    foreach ($node in $readings.Node)
    {
        $startNode = $node.SelectSingleNode('espi:timePeriod/espi:start', $nsmgr)
        $valNode = $node.SelectSingleNode('espi:value', $nsmgr)

        if (-not $startNode -or -not $valNode) { continue }

        $epoch = [int64]$startNode.InnerText
        $kwhRaw = [double]$valNode.InnerText
        $kwh = $kwhRaw * $kwhMultiplier

        $utc = [DateTimeOffset]::FromUnixTimeSeconds($epoch).UtcDateTime

        if ($PSBoundParameters.ContainsKey('StartUtc') -and $utc -lt $StartUtc.ToUniversalTime()) { continue }
        if ($PSBoundParameters.ContainsKey('EndUtc') -and $utc -ge $EndUtc.ToUniversalTime()) { continue }

        # Bucket key = top of the hour (minutes 00)
        $hourStart = [datetime]::new($utc.Year, $utc.Month, $utc.Day, $utc.Hour, 0, 0, [System.DateTimeKind]::Utc)

        if (-not $hourly.ContainsKey($hourStart)) { $hourly[$hourStart] = 0.0 }
        $hourly[$hourStart] += $kwh

        if (-not $hourlyCount.ContainsKey($hourStart)) { $hourlyCount[$hourStart] = 0 }
        $hourlyCount[$hourStart] += 1
    }

    if ($RequireFullHours)
    {

        $incompleteHours = @($hourlyCount.GetEnumerator() |
                Where-Object { $_.Value -ne $expectedPerHour } |
                ForEach-Object { $_.Key })

        if ($incompleteHours.Count -gt 0)
        {
            Write-Information -MessageData "RequireFullHours enabled: removing $($incompleteHours.Count) incomplete hour(s)."
            foreach ($h in $incompleteHours)
            {
                $hourly.Remove($h) | Out-Null
                $hourlyCount.Remove($h) | Out-Null
            }
        }

        if ($hourly.Count -eq 0)
        {
            throw 'RequireFullHours removed all hours (no complete hours remain).'
        }
    }

    if ($hourly.Count -eq 0)
    {
        throw 'No readings remained after filtering. Check StartUtc/EndUtc or source content.'
    }


    # Produce a sorted list of hours
    $hours = $hourly.Keys | Sort-Object

    # Optionally fill gaps (missing hours => 0 usage)
    if ($FillMissingHours)
    {
        Write-Information -MessageData 'Checking for and filling any missing hours'
        $filled = New-Object System.Collections.Generic.List[datetime]
        $cur = $hours[0]
        $end = $hours[-1]

        while ($cur -le $end)
        {
            $filled.Add($cur)
            $cur = $cur.AddHours(1)
        }

        foreach ($h in $filled)
        {
            if (-not $hourly.ContainsKey($h)) { $hourly[$h] = 0.0 }
        }

        $hours = $hourly.Keys | Sort-Object
    }

    # Filter to only hours after the last imported hour (append-only output)
    if ($PSBoundParameters.ContainsKey('LastImportedStartUtc'))
    {
        $cutoff = $LastImportedStartUtc.ToUniversalTime()

        # Ensure cutoff is aligned to top-of-hour UTC; if not, round down
        $cutoff = [datetime]::new($cutoff.Year, $cutoff.Month, $cutoff.Day, $cutoff.Hour, 0, 0, [DateTimeKind]::Utc)

        $hours = @($hours | Where-Object { $_ -gt $cutoff })

        Write-Information -MessageData "Filtering output to hours after $($cutoff.ToString('u')); remaining hours: $($hours.Count)"

        if (-not $hours -or $hours.Count -eq 0)
        {
            Write-Information -MessageData 'No new hours after cutoff; no output file will be created.'
            return
        }
    }


    # Reconstruct cumulative totals
    Write-Information -MessageData 'Generating Transformed Time Series Records'
    $total = [double]$LastImportedTotalKwh
    $rows = foreach ($h in $hours)
    {
        $total += [double]$hourly[$h]

        [pscustomobject]@{
            statistic_id = $StatisticId
            unit         = $unitOfMeasure
            start        = $h.ToString($startFormat)
            state        = [math]::Round($total, 6)
            sum          = [math]::Round($total, 6)
            # last_changed intentionally omitted; the importer ignores extra columns anyway. :contentReference[oaicite:2]{index=2}
        }
    }

    $latestTotalKwh = [math]::Round($total, 3)

    # Write CSV/TSV
    $rows | Export-Csv -Delimiter $Delimiter -Path $OutputFilePath -Encoding utf8 -NoTypeInformation
    Write-Information -MessageData "Wrote $($rows.Count) hourly rows to: $OutputFilePath"

    $outputObject = [PSCustomObject]@{
        OutputFilePath = $OutputFilePath
        LatestTotalKwh = $latestTotalKwh
    }
    $outputObject
}
