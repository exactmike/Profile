    Function Test-StringIsConvertibleToGUID {
        
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory, ValueFromPipeline)]
        [String]$string
    )
    try {([guid]$string -is [guid])} catch {$false}

    }
