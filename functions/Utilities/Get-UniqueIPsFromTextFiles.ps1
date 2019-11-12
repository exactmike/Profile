    Function Get-UniqueIPsFromTextFiles {
        
    # Get-UniqueIPsFromLogs
    # Mike Campbell, mike@exactsolutions.biz
    # 2011-09-12
    # version .1
    ############################################################################################
    # Lists Unique IP Addresses from a set of text based log files
    #
    # Regular Expressions to match IP addresses and description below borrowed from:
    #
    # http://www.regular-expressions.info/examples.html
    #
    # Matching an IP address is another good example of a trade-off between regex complexity
    # and exactness.
    # \b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b
    # will match any IP address just fine,
    # but will also match 999.999.999.999 as if it were a valid IP address.
    # Whether this is a problem depends on the files or data you intend to apply the regex to.
    # To restrict all 4 numbers in the IP address to 0..255, you can use this complex beast:
    # \b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b
    # (everything on a single line).
    # The long regex stores each of the 4 numbers of the IP address into a capturing group.
    # You can use these groups to further process the IP number.
    # If you don't need access to the individual numbers,
    # you can shorten the regex with a quantifier to:
    # \b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b
    # Similarly, you can shorten the quick regex to
    # \b(?:\d{1,3}\.){3}\d{1,3}\b
    #
    # Regex.Matches Method Learned about from here: http://halr9000.com/article/526
    #
    # Auto-Help:
    <#
      PowerShell comes with great support for regular expressions but the -match operator can only find the first occurrence of a pattern. To find all occurrences, you can use the .NET RegEx type. Here is a sample::
      $text = 'multiple emails like tobias.weltner@email.de and tobias@powershell.de in a string'
      $emailpattern = '(?i)\b([A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4})\b'

      $emails = ([regex]$emailpattern).Matches($text) |
      ForEach-Object { $_.Groups[1].Value }

      $emails[0]

      "*" * 100

      $emails
      Note the statement "(?i)" in the regular expression pattern description. The RegEx object by default works case-sensitive. To ignore case, use this control statement.
  #>
    <#.Synopsis
      Searches a set of log files for unique IP addresses, with optional advanced regex matching
      .Parameter LogFileLocation
      A string value specifying the path to the log files to be parsed for unique IP addresses.
      Default value is the current path
      .Parameter Advanced
      Uses an advanced RegEx that avoids matching non IP addresses such as 999.999.999.999
      .Parameter LogFileExtension
      Allows user to specify the log folder extension.  Default is .log.
  #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$LogFileLocation = (get-location).path
        ,
        [parameter()]
        [switch]$Advanced
        ,
        [parameter()]
        [string]$LogFileExtension = '*.log'
    )
    BEGIN {}
    PROCESS
    {
        # get the log file content and store the strings in an array
        $LogStrings = Get-ChildItem -Path $LogFileLocation -Filter $LogFileExtension | Get-Content

        # Determine if the user specified the Advanced RegEx and create Regex Variable Accordingly

        If ($Advanced)
        {
            [regex]$IPRegEx = '\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
        }

        Else
        {
            [regex]$IPRegEx = '\b(?:\d{1,3}\.){3}\d{1,3}\b'
        }

        # Locate Matching Values from the string array $LogStrings

        $IPRegEx.Matches($LogStrings) | Select-Object -Property Value -Unique | Sort-Object -Property Value

    }
    END {}


    }
