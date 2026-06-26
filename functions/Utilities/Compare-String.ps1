function Compare-String {
  param(
    [String] $string1,
    [String] $string2
  )

  $maxLength = [Math]::Max($string1.Length, $string2.Length)

  for ($i = 0; $i -lt $maxLength; $i++) {
    $char1 = if ($i -lt $string1.Length) { $string1[$i] } else { $null }
    $char2 = if ($i -lt $string2.Length) { $string2[$i] } else { $null }

    if ($char1 -cne $char2) {
      [PSCustomObject]@{
        Position    = $i
        String1Char = $char1
        String2Char = $char2
      }
    }
  }
}
