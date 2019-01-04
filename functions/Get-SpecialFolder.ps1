    Function Get-SpecialFolder {
        
    <#
            Original source: https://github.com/gravejester/Communary.ConsoleExtensions/blob/master/Functions/Get-SpecialFolder.ps1
            MIT License
            Copyright (c) 2016 Øyvind Kallstad

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all
            copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
            SOFTWARE.
        #>
    [cmdletbinding(DefaultParameterSetName = 'All')]
    param (
    )
    DynamicParam
    {
        $Dictionary = New-DynamicParameter -Name 'Name' -Type $([string[]]) -ValidateSet @([Enum]::GetValues([System.Environment+SpecialFolder])) -Mandatory:$true -ParameterSetName 'Selected'
        Write-Output -InputObject $dictionary
    }#DynamicParam
    begin
    {
        #Dynamic Parameter to Variable Binding
        Set-DynamicParameterVariable -dictionary $Dictionary
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                $Name = [Enum]::GetValues([System.Environment+SpecialFolder])
            }
            'Selected'
            {
            }
        }
        foreach ($folder in $Name)
        {
            $FolderObject =
            [PSCustomObject]@{
                Name = $folder.ToString()
                Path = [System.Environment]::GetFolderPath($folder)
            }
            Write-Output -InputObject $FolderObject
        }#foreach
    }#begin

    }
