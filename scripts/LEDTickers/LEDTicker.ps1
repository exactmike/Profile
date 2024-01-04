function New-LEDTextElement {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [ValidateLength(0, 16)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$text # The text content for the element, up to 16 characters
        ,
        [parameter()]
        [AllowNull()]
        [ValidateRange(1, 4)]
        [int]$size # the text size from 1 (smallest) to 4 (largest)
        ,
        [parameter()]
        [AllowNull()]
        [ValidateScript({ $_ -match '^(([0-9a-fA-F]{2}){3}|([0-9a-fA-F]){3})$' })]
        [string]$color # hexadecimal color specified with 6 chara
        ,
        [parameter()]
        [AllowNull()]
        [ValidateSet('L', 'C', 'R')]
        [string]$align
        ,
        [parameter()]
        [AllowNull()]
        [ValidateRange(0, 63)]
        [int]$x
        ,
        [parameter()]
        [AllowNull()]
        [ValidateRange(0, 31)]
        [int]$y
        ,
        [parameter()]
        [AllowNull()]
        [ValidateRange(0, 9)]
        [int]$page
    )

    $element = [ordered]@{
        text  = $text
        size  = switch ($PSBoundParameters.ContainsKey('size')) { $false { 1 } $true { $size } }
        color = switch ($PSBoundParameters.ContainsKey('color')) { $false { 'FFFFFF' } $true { $color } }
        x     = switch ($PSBoundParameters.ContainsKey('x')) { $true { $x } $false { 0 } }
        y     = switch ($PSBoundParameters.ContainsKey('y')) { $true { $y } $false { 0 } }
        align = switch ([string]::IsNullOrWhiteSpace($align)) { $true { 'L' } $false { $align } }
    }

    if ($PSBoundParameters.ContainsKey('page') -and $null -ne $page) {
        $element.Add('page', $page)
    }

    [PSCustomObject]$element

}
function New-LEDLineElement {
    [cmdletbinding()]
    param(

        [parameter()]
        [AllowNull()]
        [ValidateScript({ $_ -match '^(([0-9a-fA-F]{2}){3}|([0-9a-fA-F]){3})$' })]
        [string]$color # hexadecimal color specified with 6 characters and NO leading #
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 63)]
        [int]$x1
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 63)]
        [int]$x2
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 31)]
        [int]$y1
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 31)]
        [int]$y2
        ,
        [parameter()]
        [AllowNull()]
        [ValidateRange(0, 9)]
        [int]$page
    )

    $element = [ordered]@{
        shape = 'line'
        color = switch ([string]::IsNullOrWhiteSpace($color)) { $true { 'FFFFFF' } $false { $color } }
        x1    = switch ($PSBoundParameters.ContainsKey('x1')) { $true { $x1 } $false { 0 } }
        x2    = switch ($PSBoundParameters.ContainsKey('x2')) { $true { $x2 } $false { 0 } }
        y1    = switch ($PSBoundParameters.ContainsKey('y1')) { $true { $y1 } $false { 0 } }
        y2    = switch ($PSBoundParameters.ContainsKey('y2')) { $true { $y2 } $false { 0 } }
    }

    if ($PSBoundParameters.ContainsKey('page') -and $null -ne $page) {
        $element.Add('page', $page)
    }

    [PSCustomObject]$element

}
function New-LEDRectangleElement {
    [cmdletbinding()]
    param(

        [parameter()]
        [AllowNull()]
        [ValidateScript({ $_ -match '^(([0-9a-fA-F]{2}){3}|([0-9a-fA-F]){3})$' })]
        [string]$color # hexadecimal color specified with 6 characters and NO leading #
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 63)]
        [int]$x
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 63)]
        [int]$w
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 31)]
        [int]$y
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 31)]
        [int]$h
        ,
        [parameter()]
        [switch]$filled
        ,
        [parameter()]
        [AllowNull()]
        [ValidateRange(0, 9)]
        [int]$page
    )

    $element = [ordered]@{
        shape = 'rect'
        filled = switch ($filled) {$true {$true} $false {$false}}
        color = switch ([string]::IsNullOrWhiteSpace($color)) { $true { 'FFFFFF' } $false { $color } }
        x    = switch ($PSBoundParameters.ContainsKey('x')) { $true { $x } $false { 0 } }
        w   = switch ($PSBoundParameters.ContainsKey('w')) { $true { $w } $false { 0 } }
        y    = switch ($PSBoundParameters.ContainsKey('y')) { $true { $y } $false { 0 } }
        h    = switch ($PSBoundParameters.ContainsKey('h')) { $true { $h } $false { 0 } }
    }

    if ($PSBoundParameters.ContainsKey('page') -and $null -ne $page) {
        $element.Add('page', $page)
    }

    [PSCustomObject]$element

}
function New-LEDCircleElement {
    [cmdletbinding()]
    param(

        [parameter()]
        [AllowNull()]
        [ValidateScript({ $_ -match '^(([0-9a-fA-F]{2}){3}|([0-9a-fA-F]){3})$' })]
        [string]$color # hexadecimal color specified with 6 characters and NO leading #
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 63)]
        [int]$x
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 31)]
        [int]$y
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateScript({$_ -ge 1})]
        [int]$r
        ,
        [parameter()]
        [switch]$filled
        ,
        [parameter()]
        [AllowNull()]
        [ValidateRange(0, 9)]
        [int]$page
    )

    $element = [ordered]@{
        shape = 'circle'
        filled = switch ($filled) {$true {$true} $false {$false}}
        color = switch ([string]::IsNullOrWhiteSpace($color)) { $true { 'FFFFFF' } $false { $color } }
        x    = switch ($PSBoundParameters.ContainsKey('x')) { $true { $x } $false { 0 } }
        y    = switch ($PSBoundParameters.ContainsKey('y')) { $true { $y } $false { 0 } }
        r    = switch ($PSBoundParameters.ContainsKey('r')) { $true { $r } $false { 0 } }
    }

    if ($PSBoundParameters.ContainsKey('page') -and $null -ne $page) {
        $element.Add('page', $page)
    }

    [PSCustomObject]$element

}
function New-LEDDiamondElement {
    [cmdletbinding()]
    param(

        [parameter()]
        [AllowNull()]
        [ValidateScript({ $_ -match '^(([0-9a-fA-F]{2}){3}|([0-9a-fA-F]){3})$' })]
        [string]$color # hexadecimal color specified with 6 characters and NO leading #
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 63)]
        [int]$x
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 63)]
        [int]$w
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 31)]
        [int]$y
        ,
        [parameter(Mandatory)]
        [AllowNull()]
        [ValidateRange(0, 31)]
        [int]$h
        ,
        [parameter()]
        [switch]$filled
        ,
        [parameter()]
        [AllowNull()]
        [ValidateRange(0, 9)]
        [int]$page
    )

    $element = [ordered]@{
        shape = 'diamond'
        filled = switch ($filled) {$true {$true} $false {$false}}
        color = switch ([string]::IsNullOrWhiteSpace($color)) { $true { 'FFFFFF' } $false { $color } }
        x    = switch ($PSBoundParameters.ContainsKey('x')) { $true { $x } $false { 0 } }
        w   = switch ($PSBoundParameters.ContainsKey('w')) { $true { $w } $false { 0 } }
        y    = switch ($PSBoundParameters.ContainsKey('y')) { $true { $y } $false { 0 } }
        h    = switch ($PSBoundParameters.ContainsKey('h')) { $true { $h } $false { 0 } }
    }

    if ($PSBoundParameters.ContainsKey('page') -and $null -ne $page) {
        $element.Add('page', $page)
    }

    [PSCustomObject]$element

}
function New-LEDPixelLineElement {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [ValidateLength(0, 16)]
        [string]$hex # The 8 bit hex color pattern for the element, encoded as RRRGGGBB up to 16 characters
        ,
        [parameter()]
        [AllowNull()]
        [ValidateSet('H', 'V')]
        [string]$align
        ,
        [parameter()]
        [AllowNull()]
        [ValidateRange(0, 63)]
        [int]$x
        ,
        [parameter()]
        [AllowNull()]
        [ValidateRange(0, 31)]
        [int]$y
        ,
        [parameter()]
        [AllowNull()]
        [ValidateRange(0, 9)]
        [int]$page
    )

    $element = [ordered]@{
        shape = 'pixel'
        hex  = $hex
        size  = switch ($PSBoundParameters.ContainsKey('size')) { $false { 1 } $true { $size } }
        x     = switch ($PSBoundParameters.ContainsKey('x')) { $true { $x } $false { 0 } }
        y     = switch ($PSBoundParameters.ContainsKey('y')) { $true { $y } $false { 0 }}
        align = switch ([string]::IsNullOrWhiteSpace($align)) { $true { 'H' } $false { $align } }
    }

    if ($PSBoundParameters.ContainsKey('page') -and $null -ne $page) {
        $element.Add('page', $page)
    }

    [PSCustomObject]$element

}
Function Out-LEDTicker {
    [CmdletBinding(DefaultParameterSetName = 'IP', SupportsShouldProcess)]
    param(
        [parameter(Mandatory)]
        [psobject[]]$Element
        ,
        [parameter(ParameterSetName = 'IP', Mandatory)]
        [ValidateScript({ Test-IP -ip $_ })]
        [string]$TickerIP
        ,
        [parameter(ParameterSetName = 'FQDN', Mandatory)]
        [string]$TickerFQDN
    )

    $uri = 'http://' + $($TickerIP ?? $TickerFQDN) + '/api'

    switch ([bool]$Element[0].PSObject.Properties['page']) {
        $true {
            $PageGroups = $Element | Group-Object -AsHashTable -Property 'page'
            $content = @(
                foreach ($key in $PageGroups.keys | Sort-Object ) {
                    , $($PageGroups.$key | Select-Object -Property * -ExcludeProperty 'page')
                }
            )
        }
        $false {
            $content = $Element
        }       
    }

    $c2jp = @{
        Compress    = $true
        InputObject = $content
    }

    $body = ConvertTo-Json @c2jp

    Write-Information -MessageData $body

    if ($PSCmdlet.ShouldProcess("Post $body to $uri", $uri, 'Invoke-RestMethod Post')) {
        $null = Invoke-RestMethod -Method Post -Uri $uri -ContentType 'application/json' -Body $body
    }



}
