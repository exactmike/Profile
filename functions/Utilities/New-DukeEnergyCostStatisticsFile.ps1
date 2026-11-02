function New-DukeEnergyCostStatisticsFile {
    <#
    .SYNOPSIS
      Generate a Home Assistant cost statistics import file (USD) from a cumulative usage statistics import file (kWh).

    .INPUT
      Usage file columns (header required): statistic_id, unit, start, state, sum
      - start format: dd.MM.yyyy HH:mm (hourly)
      - state/sum: cumulative kWh (ever increasing)

    .OUTPUT
      Cost file columns: statistic_id, unit, start, state, sum
      - unit: USD
      - state/sum: cumulative USD (ever increasing)

    .PARAMETERS
      UsageFilePath, OutputFolderPath, StatisticID,
      LastImportedCost, LastImportedTotalKwH, OutputDelimiter,
      DukeEnergyCostStructure (RS|RSTC),
      CriticalPeakDates (optional, for RSTC only)

    .NOTES
      - RS includes tiering by calendar month (first 1000 kWh at tier1, remainder tier2).
      - RSTC applies TOU per hour; Critical peak requires a date list, otherwise not applied.
      - Riders/taxes are NOT included (your PDFs reference riders but do not provide cents/kWh values here).
    #>
      [CmdletBinding()]
      param(
        [Parameter(Mandatory)]
        [validateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
        [string]$UsageFilePath
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$UsageFileDelimiter = ","
        ,
        [Parameter(Mandatory)]
        [validateScript({Test-Path -LiteralPath $_ -PathType Container})]
        [string]$OutputFolderPath
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$StatisticID = 'sensor:duke_energy_consumption_cost'
        ,
        [Parameter()]
        [ValidateRange(0,[double]::MaxValue)]
        [double]$LastImportedCost = 0
        ,
        [Parameter()]
        [ValidateRange(0,[double]::MaxValue)]
        [double]$LastImportedTotalKwH = 0
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$OutputDelimiter = ","
        ,
        [Parameter(Mandatory)]
        [ValidateSet('RS','RSTC')]
        [string]$DukeEnergyCostStructure
        ,
        # Optional: For RSTC only. Dates (local) on which On-Peak hours become Critical Peak hours.
        # If you pass 2025-07-15, then On-Peak hours on that date are billed at Critical rate.
        [Parameter()]
        [datetime[]]$CriticalPeakDates = @()
      )

      begin {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'
        $tzEastern = [System.TimeZoneInfo]::FindSystemTimeZoneById('Eastern Standard Time')
        function Parse-HAStartTimeUtc([string]$StartText) {
            # dd.MM.yyyy HH:mm is UTC in your file
            return [DateTime]::ParseExact(
              $StartText,
              'dd.MM.yyyy HH:mm',
              [System.Globalization.CultureInfo]::InvariantCulture,
              [System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal
            )
          }


        function Get-DaysInMonth([datetime]$dt) {
          return [DateTime]::DaysInMonth($dt.Year, $dt.Month)
        }

        function Get-HourlyCustomerCharge([datetime]$dt, [double]$MonthlyCharge) {
          $hours = (Get-DaysInMonth $dt) * 24.0
          return $MonthlyCharge / $hours
        }

        function Get-EasterSunday([int]$Year) {
          # Anonymous Gregorian algorithm (Meeus/Jones/Butcher)
          $a = $Year % 19
          $b = [math]::Floor($Year / 100)
          $c = $Year % 100
          $d = [math]::Floor($b / 4)
          $e = $b % 4
          $f = [math]::Floor(($b + 8) / 25)
          $g = [math]::Floor(($b - $f + 1) / 3)
          $h = (19*$a + $b - $d - $g + 15) % 30
          $i = [math]::Floor($c / 4)
          $k = $c % 4
          $l = (32 + 2*$e + 2*$i - $h - $k) % 7
          $m = [math]::Floor(($a + 11*$h + 22*$l) / 451)
          $month = [math]::Floor(($h + $l - 7*$m + 114) / 31)
          $day = (($h + $l - 7*$m + 114) % 31) + 1
          return [datetime]::new($Year, $month, $day)
        }

        function Get-GoodFriday([int]$Year) {
          return (Get-EasterSunday $Year).AddDays(-2)
        }

        function Get-ObservedHoliday([datetime]$Holiday) {
          # If holiday falls on Saturday -> observe Friday; Sunday -> observe Monday; else same day.
          switch ($Holiday.DayOfWeek) {
            'Saturday' { return $Holiday.AddDays(-1) }
            'Sunday'   { return $Holiday.AddDays(1) }
            default    { return $Holiday }
          }
        }

        function Get-Thanksgiving([int]$Year) {
          # 4th Thursday in November
          $d = [datetime]::new($Year, 11, 1)
          while ($d.DayOfWeek -ne 'Thursday') { $d = $d.AddDays(1) }
          return $d.AddDays(21)
        }

        function Get-RSTCHolidays([int]$Year) {
          # Holidays per RSTC PDF: New Year's Day, Good Friday, Memorial Day, Independence Day,
          # Labor Day, Thanksgiving Day and the day after, Christmas Day.
          $holidays = New-Object System.Collections.Generic.HashSet[datetime]

          $newYears = Get-ObservedHoliday ([datetime]::new($Year,1,1))
          $goodFriday = (Get-GoodFriday $Year).Date

          # Memorial Day: last Monday in May
          $memorial = [datetime]::new($Year,5,31)
          while ($memorial.DayOfWeek -ne 'Monday') { $memorial = $memorial.AddDays(-1) }

          $independence = Get-ObservedHoliday ([datetime]::new($Year,7,4))

          # Labor Day: first Monday in September
          $labor = [datetime]::new($Year,9,1)
          while ($labor.DayOfWeek -ne 'Monday') { $labor = $labor.AddDays(1) }

          $thanks = Get-Thanksgiving $Year
          $dayAfterThanks = $thanks.AddDays(1)

          $christmas = Get-ObservedHoliday ([datetime]::new($Year,12,25))

          @($newYears, $goodFriday, $memorial, $independence, $labor, $thanks, $dayAfterThanks, $christmas) | ForEach-Object {
            [void]$holidays.Add($_.Date)
          }

          return $holidays
        }

        function Get-RSTCPeriod([datetime]$dt, [System.Collections.Generic.HashSet[datetime]]$HolidaySet, [System.Collections.Generic.HashSet[string]]$CriticalSet) {
          # Returns: 'Critical' | 'OnPeak' | 'OffPeak' | 'Discount'
          $isHoliday = $HolidaySet.Contains($dt.Date)
          $isWeekday = ($dt.DayOfWeek -ne 'Saturday' -and $dt.DayOfWeek -ne 'Sunday')
          $month = $dt.Month
          $hour = $dt.Hour

          $isSummer = ($month -ge 5 -and $month -le 9)

          # Discount windows:
          if ($isSummer) {
            # 1:00–6:00
            if ($hour -ge 1 -and $hour -lt 6) { return 'Discount' }
          } else {
            # 1:00–3:00 and 11:00–16:00
            if (($hour -ge 1 -and $hour -lt 3) -or ($hour -ge 11 -and $hour -lt 16)) { return 'Discount' }
          }

          # On-Peak windows (Mon–Fri excluding holidays):
          if ($isWeekday -and -not $isHoliday) {
            if ($isSummer) {
              # 18:00–21:00
              if ($hour -ge 18 -and $hour -lt 21) {
                if ($CriticalSet.Contains($dt.Date.ToString('yyyy-MM-dd'))) { return 'Critical' }
                return 'OnPeak'
              }
            } else {
              # 06:00–09:00
              if ($hour -ge 6 -and $hour -lt 9) {
                if ($CriticalSet.Contains($dt.Date.ToString('yyyy-MM-dd'))) { return 'Critical' }
                return 'OnPeak'
              }
            }
          }

          return 'OffPeak'
        }

        function Get-RateDefinition([string]$Structure) {
            switch ($Structure) {
              'RS' {
                return @{
                  Structure = 'RS'
                  MonthlyCustomerCharge = 11.96
                  Tier1KwhLimit = 1000.0
                  Tier1RatePerKwh = 0.133089  # 13.3089¢/kWh
                  Tier2RatePerKwh = 0.140340  # 14.0340¢/kWh
                }
              }
              'RSTC' {
                return @{
                  Structure = 'RSTC'
                  MonthlyCustomerCharge = 13.09
                  CriticalRatePerKwh = 0.386754  # 38.6754¢/kWh
                  OnPeakRatePerKwh   = 0.253857  # 25.3857¢/kWh
                  OffPeakRatePerKwh  = 0.125877  # 12.5877¢/kWh
                  DiscountRatePerKwh = 0.087237  # 8.7237¢/kWh
                }
              }
            }
          }

          $rate = Get-RateDefinition -Structure $DukeEnergyCostStructure


          # Load and parse usage rows
          $usageRows = Import-Csv -LiteralPath $UsageFilePath -Delimiter $UsageFileDelimiter
          $requiredCols = 'statistic_id','unit','start','state','sum'

          foreach ($col in $requiredCols) {
            if (-not ($usageRows[0].PSObject.Properties.Name -contains $col)) {
              throw "Usage file missing column '$col'. Found: $($usageRows[0].PSObject.Properties.Name -join ', ')"
            }
          }

          $usage = $usageRows | ForEach-Object {
            $dtUtc = Parse-HAStartTimeUtc $_.start
            $dtLocal = [System.TimeZoneInfo]::ConvertTimeFromUtc($dtUtc, $tzEastern)

            # Parse numeric using invariant culture; if your file uses comma decimals, adjust here.
            $sumVal   = [double]::Parse([string]$_.sum,   [System.Globalization.CultureInfo]::InvariantCulture)

            [pscustomobject]@{
                start    = [string]$_.start      # keep original UTC string for output
                start_utc = $dtUtc
                start_dt = $dtLocal             # use this for RSTC period logic + holidays
                kwh_cum  = $sumVal
              }
          } | Sort-Object start_utc

          # Delta import selection: only process rows where cumulative kWh advanced past last imported.
          $toProcess = if ($LastImportedTotalKwH -le 0) {
            $usage
          } else {
            $usage | Where-Object { $_.kwh_cum -gt $LastImportedTotalKwH }
          }

          if (-not $toProcess -or $toProcess.Count -eq 0) {
            Write-Information -MessageData "No rows beyond LastImportedTotalKwH=$LastImportedTotalKwH. Nothing to write."
            return
          }

          # Precompute holiday sets for years present (RSTC)
          $holidayByYear = @{}
          if ($DukeEnergyCostStructure -eq 'RSTC') {
            $years = $toProcess.start_dt.Year | Sort-Object -Unique
            foreach ($y in $years) {
              $holidayByYear[$y] = Get-RSTCHolidays $y
            }
          }

          # Critical peak set (string yyyy-MM-dd)
          $criticalSet = New-Object System.Collections.Generic.HashSet[string]
          foreach ($d in $CriticalPeakDates) { [void]$criticalSet.Add($d.Date.ToString('yyyy-MM-dd')) }


        # Output File Path
        $DateString = Get-Date -Format yyyyMMddHHmm
        $FileNamePart = $($StatisticID -replace '[^A-Za-z0-9_-]', '_') + '_' + $DukeEnergyCostStructure
        $OutputFileName = $FileNamePart + 'AsOf' + $DateString + '.csv'
        $OutputFilePath = Join-Path -Path $OutputFolderPath -ChildPath $OutputFileName
        Write-Information -MessageData "set output file path to $OutputFilePath"

        }

        process {
          $cumulativeCost = [double]$LastImportedCost
          $prevKwh = [double]$LastImportedTotalKwH
          $isFirstEmitted = $true

          # For RS tiering: track month usage within calendar month (kWh), based on deltas we apply.
          # If doing a delta import mid-month, we need an estimate of month-to-date kWh already consumed.
          # Best practical approach: treat month-to-date prior usage as "unknown" unless you provide it.
          # Here, we approximate by using the cumulative total and assume the file starts at month boundary when full import.
          # For delta runs, we compute monthToDate from the first processed row's date and the last imported total only if the
          # last imported hour is within same month as first processed hour; otherwise reset.
          $monthKey = $null
          $monthToDateKwh = 0.0

          $outRows = New-Object System.Collections.Generic.List[object]

          foreach ($r in $toProcess) {
            $dt = $r.start_dt
            $curKwh = $r.kwh_cum

            # Compute delta kWh
            $deltaKwh = if ($isFirstEmitted -and $LastImportedTotalKwH -le 0) {
              0.0  # avoid "from zero" spike on first row of a full import
            } else {
              $curKwh - $prevKwh
            }

            if ($deltaKwh -lt 0) {
              Write-Warning ("Negative kWh delta at {0}: current={1}, prev={2}. Treating delta as 0." -f $r.start, $curKwh, $prevKwh)
              $deltaKwh = 0.0
            }

            # Reset month tracking when month changes
            $thisMonthKey = "{0:0000}-{1:00}" -f $dt.Year, $dt.Month
            if ($monthKey -ne $thisMonthKey) {
              $monthKey = $thisMonthKey
              $monthToDateKwh = 0.0

              # If this is a delta import and the first emitted row is in the same month as the last imported point,
              # we cannot know exact prior month-to-date kWh without additional input. We keep it at 0 (conservative).
              # If you want exact RS tiering mid-month, add an optional parameter LastImportedMonthToDateKwh.
            }

            # Hourly customer charge
            $hourlyCust = Get-HourlyCustomerCharge -dt $dt -MonthlyCharge ([double]$rate.MonthlyCustomerCharge)

            # Compute energy cost for this hour
            $energyCost = 0.0

            if ($DukeEnergyCostStructure -eq 'RS') {
              # Tiering by month: first 1000 kWh at tier1, remainder tier2
              $tier1Remaining = [math]::Max(0.0, [double]$rate.Tier1KwhLimit - $monthToDateKwh)

              $tier1Kwh = [math]::Min($deltaKwh, $tier1Remaining)
              $tier2Kwh = [math]::Max(0.0, $deltaKwh - $tier1Kwh)

              $energyCost = ($tier1Kwh * [double]$rate.Tier1RatePerKwh) + ($tier2Kwh * [double]$rate.Tier2RatePerKwh)

              $monthToDateKwh += $deltaKwh
            }
            else {
              # RSTC TOU by hour
              $holidaySet = $holidayByYear[$dt.Year]
              $period = Get-RSTCPeriod -dt $dt -HolidaySet $holidaySet -CriticalSet $criticalSet

              switch ($period) {
                'Critical' { $energyCost = $deltaKwh * [double]$rate.CriticalRatePerKwh }
                'OnPeak'   { $energyCost = $deltaKwh * [double]$rate.OnPeakRatePerKwh }
                'OffPeak'  { $energyCost = $deltaKwh * [double]$rate.OffPeakRatePerKwh }
                'Discount' { $energyCost = $deltaKwh * [double]$rate.DiscountRatePerKwh }
                default    { $energyCost = $deltaKwh * [double]$rate.OffPeakRatePerKwh }
              }
            }

            $deltaCost = $hourlyCust + $energyCost
            $cumulativeCost += $deltaCost

            $outRows.Add([pscustomobject]@{
              statistic_id = $StatisticID
              unit         = 'USD'
              start        = $r.start
              state        = [Math]::Round($cumulativeCost, 4)
              sum          = [Math]::Round($cumulativeCost, 4)
            })

            $prevKwh = $curKwh
            $isFirstEmitted = $false
          }

          $outRows |
            Select-Object statistic_id,unit,start,state,sum |
            Export-CSV -Path $OutputFilePath -NoTypeInformation -Delimiter $OutputDelimiter -Encoding utf8

            return $OutputFilePath
        }
      }