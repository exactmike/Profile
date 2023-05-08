Function New-WordTable
{
    [cmdletbinding(
        DefaultParameterSetName='Table'
    )]
    Param (
        [parameter()]
        [object]$WordObject,
        [parameter()]
        [object]$Object,
        [parameter()]
        [int]$Columns,
        [parameter()]
        [int]$Rows,
        [parameter(ParameterSetName='Table')]
        [switch]$AsTable,
        [parameter(ParameterSetName='List')]
        [switch]$AsList,
        [parameter()]
        [string]$TableStyle,
        [parameter()]
        [Microsoft.Office.Interop.Word.WdDefaultTableBehavior]$TableBehavior = 'wdWord9TableBehavior',
        [parameter()]
        [Microsoft.Office.Interop.Word.WdAutoFitBehavior]$AutoFitBehavior = 'wdAutoFitContent'
    )
    #Specifying 0 index ensures we get accurate data from a single object
    $Properties = $Object[0].psobject.properties.name
    $Range = @($Word.Selection.Paragraphs)[-1].Range
    $Table = $WordObject.Selection.Tables.add($Range, $Rows, $Columns, $TableBehavior, $AutoFitBehavior)

    Switch ($PSCmdlet.ParameterSetName)
    {
        'Table'
        {
            If (-NOT $PSBoundParameters.ContainsKey('TableStyle'))
            {
                $Table.Style = 'Medium Shading 1 - Accent 1'
            }
            $c = 1
            $r = 1
            #Build header
            $Properties | ForEach-Object {
                Write-Verbose "Adding $($_)"
                $Table.cell($r, $c).range.Bold=1
                $Table.cell($r, $c).range.text = $_
                $c++
            }
            $c = 1
            #Add Data
            For ($i=0; $i -lt (($Object | Measure-Object).Count); $i++)
            {
                $Properties | ForEach-Object {
                    $Table.cell(($i+2), $c).range.Bold=0
                    $Table.cell(($i+2), $c).range.text = $Object[$i].$_
                    $c++
                }
                $c = 1
            }
        }
        'List'
        {
            If (-NOT $PSBoundParameters.ContainsKey('TableStyle'))
            {
                $Table.Style = 'Light Shading - Accent 1'
            }
            $c = 1
            $r = 1
            $Properties | ForEach-Object {
                $Table.cell($r, $c).range.Bold=1
                $Table.cell($r, $c).range.text = $_
                $c++
                $Table.cell($r, $c).range.Bold=0
                $Table.cell($r, $c).range.text = $Object.$_
                $c--
                $r++
            }
        }
    }
}