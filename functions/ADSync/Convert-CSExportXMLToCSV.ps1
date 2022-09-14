function Convert-CSExportXMLToCSV {

    ### Abstract: This PoSH Script Parses The CS Export XML From FIM/MIM/AADConnect Into A CSV File For Analysis In Excel
    ### Written by: Jorge de Almeida Pinto [MVP-EMS]
    ### BLOG: http://jorgequestforknowledge.wordpress.com/
    ###
    ### 2019-09-19: Initial version of the script (v0.1)
    ### 2019-09-25: Added an additional column to identify the object and search against AD (v0.2)
    ###

                                                                                                                                                                                                                                                                <#
.SYNOPSIS
.DESCRIPTION
	Takes an XML file created by CSEXPORT, and produces a CSV file as the output more suitable for opening in Excel or produces the output in a gridview.
	Supports both single-valued attributes and multi-valued attributes.

.PARAMETER outToGridView
	This parameter tells the script to output to GridView

.PARAMETER outToCSV
	This parameter tells the script to output to a CSV file

.PARAMETER outToAll
	This parameter tells the script to output to all possible methods

.PARAMETER sourceXMLfilePaths
	The file path of the XML file to use as a source

.PARAMETER targetFilePath
	The file path of the CSV file to use as a target when using 'outToCSV'. DO NOT specify an extension. The script will add the corect file extension!

.EXAMPLE
	Parse the contents of the XML file into a GridView

	.\Parse-CS-Export-XML-To-CSV.ps1 -outToGridView -sourceXMLfilePaths <Source XML File Path>

.EXAMPLE
	Parse the contents of multiple XML files into a GridView

	.\Parse-CS-Export-XML-To-CSV.ps1 -outToGridView -sourceXMLfilePaths <Source XML File Path 1>,<Source XML File Path 2>,<Source XML File Path 3>

.EXAMPLE
	Parse the contents of the XML file into a CSV file

	.\Parse-CS-Export-XML-To-CSV.ps1 -outToCSV -sourceXMLfilePaths <Source XML File Path> -targetFilePath <Target File Path>

.EXAMPLE
	Parse the contents of multiple XML files into a CSV file

	.\Parse-CS-Export-XML-To-CSV.ps1 -outToCSV -sourceXMLfilePaths <Source XML File Path 1>,<Source XML File Path 2>,<Source XML File Path 3> -targetFilePath <Target File Path>

.EXAMPLE
	Parse the contents of the XML file into a GridView, CSV file

	.\Parse-CS-Export-XML-To-CSV.ps1 -outToAll -sourceXMLfilePaths <Source XML File Path> -targetFilePath <Target File Path>

.EXAMPLE
	Parse the contents of multiple XML files into a GridView, CSV file

	.\Parse-CS-Export-XML-To-CSV.ps1 -outToAll -sourceXMLfilePaths <Source XML File Path 1>,<Source XML File Path 2>,<Source XML File Path 3> -targetFilePath <Target File Path>

.NOTES
	* Supports FIM, MIM, AAD Connect
	* CSEXPORT must be used. An export drop file CANNOT be used!
	* The script only looks at exports (adds, updates, deletes). It does not look at imports.
	* Multiple CSEXPORT shource XML files can be used

	+++ CSEXPORT USAGE +++
	* FIM/MIM Folder Location For CS Export: "C:\Program Files\Microsoft Forefront Identity Manager\2010\Synchronization Service\Bin"
	* AAD Connect Folder Location For CS Export: "C:\Program Files\Microsoft Azure AD Sync\Bin"
	* Usage: CSEXPORT ma_name [filename] [/f[:]{d="DN"|r="rdn"|g="guid"|s|i|e|m|x}] [/o[:]{[e][b][h][d][p]}]
		ma_name     Name of MA to export
		filename    Filename (default is name of MA)
		/f          Filter objects to export (default is all objects, if this option is omitted). YOU CAN SPECIFY ONLY ONE FILTER!:
				d   Specify DN to export where DN is the distinguished name or anchor to export
				r   Specify RDN to export where RDN is the relative distinguished name to export
				g   Specify GUID to export where GUID is the globally unique identifier to export
				s   Disconnectors
				i   Import errors
				e   Export errors
				m   Pending imports
				x   Pending exports

		/o          Output the following items (default is all items, if this option is omitted):
				e   include error information
				b   include only the hologram
				h   include all tower holograms
				d   include all tower deltas
				p   include password set/change history

		Examples:
			* CSEXPORT "xyz.onmicrosoft.com - AAD" C:\TEMP\2019-01-01_AAD-CS_All.xml
			* CSEXPORT "xyz.onmicrosoft.com - AAD" C:\TEMP\2019-01-01_AAD-CS_PendingImports.xml /f:m
			* CSEXPORT "xyz.onmicrosoft.com - AAD" C:\TEMP\2019-01-01_AAD-CS_PendingExports.xml /f:x
    #>

    Param(
	    [switch]$outToGridView,
	    [switch]$outToCSV,
	    [switch]$outToAll,
	    [Parameter(Mandatory=$TRUE, ValueFromPipeline=$TRUE, ValueFromPipelineByPropertyName=$TRUE,
		    HelpMessage="Please specify the full file path to one or more source XML files")]
	    [ValidateNotNullOrEmpty()]
        [string[]]$sourceXMLfilePaths,
	    [Parameter(Mandatory=$FALSE, ValueFromPipeline=$TRUE, ValueFromPipelineByPropertyName=$TRUE,
		    HelpMessage="Please specify the full file path to one target CSV file")]
        [string]$targetFilePath
    )

    ### Clear The Screen
    Clear-Host

    ### Configure The Appropriate Screen And Buffer Size To Make Sure Everything Fits Nicely
    $uiConfig = (Get-Host).UI.RawUI
    $uiConfig.WindowTitle = "+++ PARSE CS EXPORT XML FILES TO CSV +++"
    $uiConfig.ForegroundColor = "Yellow"
    $uiConfigBufferSize = $uiConfig.BufferSize
    $uiConfigBufferSize.Width = 150
    $uiConfigBufferSize.Height = 9999
    $uiConfigScreenSizeMax = $uiConfig.MaxPhysicalWindowSize
    $uiConfigScreenSizeMaxWidth = $uiConfigScreenSizeMax.Width
    $uiConfigScreenSizeMaxHeight = $uiConfigScreenSizeMax.Height
    $uiConfigScreenSize = $uiConfig.WindowSize
    If ($uiConfigScreenSizeMaxWidth -lt 150) {
	    $uiConfigScreenSize.Width = $uiConfigScreenSizeMaxWidth
    } Else {
	    $uiConfigScreenSize.Width = 150
    }
    If ($uiConfigScreenSizeMaxHeight -lt 50) {
	    $uiConfigScreenSize.Height = $uiConfigScreenSizeMaxHeight - 5
    } Else {
	    $uiConfigScreenSize.Height = 50
    }
    $uiConfig.BufferSize = $uiConfigBufferSize
    $uiConfig.WindowSize = $uiConfigScreenSize

    Write-Host ""
    Write-Host "                                          **********************************************************" -ForeGroundColor Cyan
    Write-Host "                                          *                                                        *" -ForeGroundColor Cyan
    Write-Host "                                          *        --> Parse CS Export XML Files To CSV <--        *" -ForeGroundColor Cyan
    Write-Host "                                          *                                                        *" -ForeGroundColor Cyan
    Write-Host "                                          *      Written By: Jorge de Almeida Pinto [MVP-EMS]      *" -ForeGroundColor Cyan
    Write-Host "                                          *                                                        *" -ForeGroundColor Cyan
    Write-Host "                                          *   BLOG: http://jorgequestforknowledge.wordpress.com/   *" -ForeGroundColor Cyan
    Write-Host "                                          *                                                        *" -ForeGroundColor Cyan
    Write-Host "                                          **********************************************************" -ForeGroundColor Cyan
    Write-Host ""

    ### Definition Of Some Constants
    $execDateTime = Get-Date
    $execDateTimeDisplay = Get-Date $execDateTime -f "yyyy-MM-dd HH:mm:ss"

    # Define The (Empty) List For All Processed CS Objects
    $global:objectList = @()

    # Define The List Of (Main) Headers For Every CS Object
    $mainHeaders = @("MA-Name","Object-Type","Ops-Type","CS-DN","Connector-Type","MV-GUID","Last-Export","Source-ID","AD-ID")

    # Define The (Empty) List Of Attribute Headers For Every CS Object (In The End It Depends On The Schema And The Attributes Of The CS Object Containing Values)
    $global:attributeHeaders = @()

    $sourceXMLfilePaths | %{
	    $sourceXMLfilePath = $null
	    $sourceXMLfilePath = $_

	    # Check The Source File Exists
	    If (Test-Path $sourceXMLfilePath) {
		    # Define The XML Document Object
		    [System.Xml.XmlDocument]$xmlCSExport = New-Object System.Xml.XmlDocument
		    $xmlCSExport.load($sourceXMLfilePath)

		    # Get All The Objects From The CS Export XML File And Determine The Total Number Of Objects
		    $exportedCSObjects = $null
		    $exportedCSObjects = $xmlCSExport."cs-objects"."cs-object"
		    $exportedCSObjectTotalCount = $null
		    $exportedCSObjectTotalCount = $exportedCSObjects.count

		    # Get All The Objects From The CS Export XML File With ADDS, UPDATES And DELETES And Determine The Total Number Of Objects For Each
		    $exportedCSObjectAdds = $null
		    $exportedCSObjectAdds = $xmlCSExport."cs-objects"."cs-object" | ?{$_."export-delta-operation" -eq "add"}
		    $exportedCSObjectAddsCount = $null
		    $exportedCSObjectAddsCount = $exportedCSObjectAdds.count
		    $exportedCSObjectUpdates = $null
		    $exportedCSObjectUpdates = $xmlCSExport."cs-objects"."cs-object" | ?{$_."export-delta-operation" -eq "modify"}
		    $exportedCSObjectUpdatesCount = $null
		    $exportedCSObjectUpdatesCount = $exportedCSObjectUpdates.count
		    $exportedCSObjectDeletes = $null
		    $exportedCSObjectDeletes = $xmlCSExport."cs-objects"."cs-object" | ?{$_."export-delta-operation" -eq "delete"}
		    $exportedCSObjectDeletesCount = $null
		    $exportedCSObjectDeletesCount = $exportedCSObjectDeletes.count
		    $exportedCSObjectWithNoChanges = $null
		    $exportedCSObjectWithNoChanges = $xmlCSExport."cs-objects"."cs-object" | ?{$_."export-delta-operation" -eq "none"}
		    $exportedCSObjectWithNoChangesCount = $null
		    $exportedCSObjectWithNoChangesCount = $exportedCSObjectWithNoChanges.count

		    # If There Are Any Objects To Process
		    If ($exportedCSObjects) {
			    # Reset The Counters
			    $iNr = 0
			    $iAddNr = 0
			    $iUpdateNr = 0
			    $iDeleteNr = 0
			    $iNoChangeNr = 0

			    # Process For Every Exported CS Object
			    $exportedCSObjects | %{
				    # Increase This Counter
				    $iNr++

				    # The CS Object To Process
				    $objectCS = $null
				    $objectCS = $_

				    # Get The DN Of The Object In The Corresponding CS
				    $objectCSdn = $null
				    $objectCSdn = $objectCS."cs-dn"

				    # Get The MA Name For The Corresponding CS
				    $csMAName = $null
				    $csMAName = $objectCS."ma-name"

				    # Get The Type Of The Object In The Corresponding CS
				    $objectCStype = $null
				    $objectCStype = $objectCS."object-type"

				    # Get The Type Of The Connector In The Corresponding CS
				    $objectCSConnectorType = $null
				    $objectCSConnectorType = $(If ($objectCS.connector -eq 0) {"Disconnector"} Else {"Connector"})

				    # Get The MV GUID, If Any, Of The Object In The Corresponding CS
				    $objectCSMVGuid = $null
				    $objectCSMVGuid = $objectCS."mv-link"."#text"

				    # Get The Type Of Operation On The Object In The Corresponding CS
				    $objectCSOpsType = $null
				    $objectCSOpsType = $objectCS."export-delta-operation"

				    # Get The Last Export Time For The Object In The Corresponding CS
				    $objectCSLastExportTime = $null
				    $objectCSLastExportTime = $objectCS."last-export-delta-time"

				    # Get The Source Identifier For The Object In The Corresponding CS
				    $objectCSSourceID = $null
				    If ($objectCStype -eq "user" -Or $objectCStype -eq "group" -Or $objectCStype -eq "contact") {
					    $objectCSSourceID = $($objectCS."pending-import-hologram".entry.attr | ?{$_.name -eq "sourceAnchor"}).value
					    If (!$objectCSSourceID) {
						    $objectCSSourceID = $($objectCS."unapplied-export-hologram".entry.attr | ?{$_.name -eq "sourceAnchor"}).value
					    }
				    } Else {
					    $objectCSSourceID = "UNKNOWN"
				    }
				    If (!$objectCSSourceID) {
					    $objectCSSourceID = "UNABLE TO DETERMINE"
				    }

				    # Get The Unique AD Identifier For The Object In The Corresponding CS
				    $objectCSADID = $null
				    If ($objectCStype -eq "user") {
					    $objectCSADID = $($objectCS."pending-import-hologram".entry.attr | ?{$_.name -eq "userPrincipalName"}).value
					    If (!$objectCSADID) {
						    $objectCSADID = $($objectCS."unapplied-export-hologram".entry.attr | ?{$_.name -eq "userPrincipalName"}).value
					    }
				    } ElseIf ($objectCStype -eq "group") {
					    $objectCSADID = $($objectCS."pending-import-hologram".entry.attr | ?{$_.name -eq "dnsDomainName"}).value + "\" + $($objectCS."pending-import-hologram".entry.attr | ?{$_.name -eq "onPremisesSamAccountName"}).value
					    If ($objectCSADID -eq "\" -Or $objectCSADID.StartsWith("\") -Or $objectCSADID.EndsWith("\")) {
						    $objectCSADID = $($objectCS."unapplied-export-hologram".entry.attr | ?{$_.name -eq "dnsDomainName"}).value + "\" + $($objectCS."unapplied-export-hologram".entry.attr | ?{$_.name -eq "onPremisesSamAccountName"}).value
					    }
				    } ElseIf ($objectCStype -eq "contact") {
					    $objectCSADID = $($objectCS."pending-import-hologram".entry.attr | ?{$_.name -eq "mail"}).value
					    If (!$objectCSADID) {
						    $objectCSADID = $($objectCS."unapplied-export-hologram".entry.attr | ?{$_.name -eq "mail"}).value
					    }
				    } Else {
					    $objectCSADID = "UNKNOWN"
				    }
				    If (!$objectCSADID) {
					    $objectCSADID = "UNABLE TO DETERMINE"
				    }

				    # Show The Progress
				    $perCent = $($iNr / $exportedCSObjectTotalCount * 100)
				    $statusText = "Object $($iNr.ToString().PadLeft($exportedCSObjectTotalCount.Count.ToString().Length)) Of $exportedCSObjectTotalCount ($([math]::Round($perCent,2)) %) | CS-DN: $objectCSdn"
				    Write-Progress -Activity "Processing Objects" -Status $statusText -PercentComplete $perCent

				    # Define The Object And Store The Main Attributes In It
				    $object = New-Object -TypeName System.Object
				    $object | Add-Member -MemberType NoteProperty -Name "MA-Name" -Value $csMAName
				    $object | Add-Member -MemberType NoteProperty -Name "Object-Type" -Value $objectCStype
				    $object | Add-Member -MemberType NoteProperty -Name "Ops-Type" -Value $objectCSOpsType
				    $object | Add-Member -MemberType NoteProperty -Name "CS-DN" -Value $objectCSdn
				    $object | Add-Member -MemberType NoteProperty -Name "Connector-Type" -Value $objectCSConnectorType
				    $object | Add-Member -MemberType NoteProperty -Name "MV-GUID" -Value $objectCSMVGuid
				    $object | Add-Member -MemberType NoteProperty -Name "Last-Export" -Value $objectCSLastExportTime
				    $object | Add-Member -MemberType NoteProperty -Name "Source-ID" -Value $objectCSSourceID
				    $object | Add-Member -MemberType NoteProperty -Name "AD-ID" -Value $objectCSADID

				    # Get The Delta Operation Details When There Are Changes To Process
				    If ($objectCS."export-delta-operation" -ne "none") {
					    $objectCSDeltaOps = $null
					    $objectCSDeltaOps = $objectCS."unapplied-export".delta

					    # If The Delta Operation Concerns ADDS
					    If ($objectCSDeltaOps.operation -eq "add") {
						    # Increase This Counter
						    $iAddNr++

						    # Get The Attribute List
						    $attrListNonLinkedDelta = $objectCSDeltaOps.attr
						    $attrListLinkedDelta = $objectCSDeltaOps."dn-attr"

						    # Process Every Non-Linked Attribute
						    If ($attrListNonLinkedDelta) {
							    $attrListNonLinkedDelta | %{
								    # Get The Attribute Item
								    $attrNonLinkedItem = $null
								    $attrNonLinkedItem = $_
								    $attrNonLinkedItemName = $null
								    $attrNonLinkedItemName = $attrNonLinkedItem.name

								    # Add The Attribute Item To The List Of Attribute Headers If It Does Not Contain It To Gradually Build The Schema To Be Displayed With The Data
								    If ($global:attributeHeaders -notcontains $attrNonLinkedItemName) {
									    $global:attributeHeaders += $attrNonLinkedItemName
								    }

								    # Process The Data Of The Attribute
								    $attrNonLinkedValues = $null
								    $attrNonLinkedValues = $attrNonLinkedItem.value
								    $attrNonLinkedValuesString = $null
								    $attrNonLinkedValuesString = "[ADD:]" + $($attrNonLinkedValues -join "`n[ADD:]")
								    $object | Add-Member -MemberType NoteProperty -Name $attrNonLinkedItemName -value $attrNonLinkedValuesString
							    }
						    }

						    # Process Every Linked Attribute
						    If ($attrListLinkedDelta) {
							    $attrListLinkedDelta | %{
								    # Get The Attribute Item
								    $attrLinkedItem = $null
								    $attrLinkedItem = $_
								    $attrLinkedItemName = $null
								    $attrLinkedItemName = $attrLinkedItem.name

								    # Add The Attribute Item To The List Of Attribute Headers If It Does Not Contain It To Gradually Build The Schema To Be Displayed With The Data
								    If ($global:attributeHeaders -notcontains $attrLinkedItemName) {
									    $global:attributeHeaders += $attrLinkedItemName
								    }

								    # Process The Data Of The Attribute
								    $attrLinkedValues = $null
								    $attrLinkedValues = $attrLinkedItem."dn-value"
								    $attrLinkedValuesString = $null
								    $attrLinkedValuesString = "[ADD:]" + $($attrLinkedValues.dn -join "`n[ADD:]")

								    # Add The Attribute And Its Value(s) To The CS Object Being Processed
								    $object | Add-Member -MemberType NoteProperty -Name $attrLinkedItemName -value $attrLinkedValuesString
							    }
						    }
					    }

					    # If The Delta Operation Concerns UPDATES/MODIFIES
					    If ($objectCSDeltaOps.operation -eq "update") {
						    # Increase This Counter
						    $iUpdateNr++

						    # Get The Attribute List
						    $attrListNonLinkedDelta = $objectCSDeltaOps.attr
						    $attrListLinkedDelta = $objectCSDeltaOps."dn-attr"

						    # Process Every Non-Linked Attribute
						    If ($attrListNonLinkedDelta) {
							    $attrListNonLinkedDelta | %{
								    # Get The Attribute Item
								    $attrNonLinkedItem = $null
								    $attrNonLinkedItem = $_
								    $attrNonLinkedItemName = $null
								    $attrNonLinkedItemName = $attrNonLinkedItem.name

								    # Add The Attribute Item To The List Of Attribute Headers If It Does Not Contain It To Gradually Build The Schema To Be Displayed With The Data
								    If ($global:attributeHeaders -notcontains $attrNonLinkedItemName) {
									    $global:attributeHeaders += $attrNonLinkedItemName
								    }

								    # Get The Value(s)
								    $attrNonLinkedValues = $null
								    $attrNonLinkedValues = $attrNonLinkedItem.value

								    # Define Empty Variables To Work With
								    $attrNonLinkedValuesArray = @()
								    $attrNonLinkedValuesString = $null

								    # If The Modify Operation Concerns The Addition Of A Value
								    $attrNonLinkedValues | ?{$_.operation -eq "add"} | %{
									    $attrNonLinkedValuesArray += $("[ADD:]" + $($_."#text"))
								    }

								    # If The Modify Operation Concerns The Delete Of A Value
								    $attrNonLinkedValues | ?{$_.operation -eq "delete"} | %{
									    $attrNonLinkedValuesArray += $("[DEL:]" + $($_."#text"))
								    }

								    # Convert The Attribute Values To a String
								    $attrNonLinkedValuesString = $attrNonLinkedValuesArray -join "`n"

								    # Add The Attribute And Its Value(s) To The CS Object Being Processed
								    $object | Add-Member -MemberType NoteProperty -Name $attrNonLinkedItemName -value $attrNonLinkedValuesString
							    }
						    }

						    # Process Every Linked Attribute
						    If ($attrListLinkedDelta) {
							    $attrListLinkedDelta | %{
								    # Get The Attribute Item
								    $attrLinkedItem = $null
								    $attrLinkedItem = $_
								    $attrLinkedItemName = $null
								    $attrLinkedItemName = $attrLinkedItem.name

								    # Add The Attribute Item To The List Of Attribute Headers If It Does Not Contain It To Gradually Build The Schema To Be Displayed With The Data
								    If ($global:attributeHeaders -notcontains $attrLinkedItemName) {
									    $global:attributeHeaders += $attrLinkedItemName
								    }

								    # Get The Value(s)
								    $attrLinkedValues = $null
								    $attrLinkedValues = $attrLinkedItem."dn-value"

								    # Define Empty Variables To Work With
								    $attrLinkedValuesArray = @()
								    $attrLinkedValuesString = $null

								    # Get The Operation Type Of The Modification Of The Values
								    $attrLinkedValuesOps = $attrLinkedItem.operation

								    # If The Modify Operation Concerns Only The Addition Of A Value
								    If ($attrLinkedValuesOps -eq "add") {
									    $attrLinkedValues | %{
										    $attrLinkedValuesArray += $("[ADD:]" + $($_.dn))
									    }
								    }

								    # If The Modify Operation Concerns The Addition And Deletion Of Values
								    If ($attrLinkedValuesOps -eq "update") {
									    $attrLinkedValues | ?{$_.operation -eq "add"} | %{
										    $attrLinkedValuesArray += $("[ADD:]" + $($_.dn))
									    }
									    $attrLinkedValues | ?{$_.operation -eq "delete"} | %{
										    $attrLinkedValuesArray += $("[DEL:]" + $($_.dn))
									    }
								    }

								    # If The Modify Operation Concerns Only The Deletion Of A Value
								    If ($attrLinkedValuesOps -eq "delete") {
									    $attrLinkedValues | %{
										    $attrLinkedValuesArray += $("[DEL:]" + $($_.dn))
									    }
								    }

								    # Convert The Attribute Values To a String
								    $attrLinkedValuesString = $attrLinkedValuesArray -join "`n"

								    # Add The Attribute And Its Value(s) To The CS Object Being Processed
								    $object | Add-Member -MemberType NoteProperty -Name $attrLinkedItemName -value $attrLinkedValuesString
							    }
						    }
					    }

					    # If The Delta Operation Concerns DELETES
					    If ($objectCSDeltaOps.operation -eq "delete") {
						    # Increase This Counter
						    $iDeleteNr++

						    # Get The Attribute List Before The Export
						    $attrListNonLinkedFull = $objectCS."pending-import-hologram".entry.attr
						    $attrListLinkedFull = $objectCS."pending-import-hologram".entry."dn-attr"

						    # Process Every Non-Linked Attribute
						    If ($attrListNonLinkedFull) {
							    $attrListNonLinkedFull | %{
								    # Get The Attribute Item
								    $attrNonLinkedItem = $null
								    $attrNonLinkedItem = $_
								    $attrNonLinkedItemName = $null
								    $attrNonLinkedItemName = $attrNonLinkedItem.name

								    # Add The Attribute Item To The List Of Attribute Headers If It Does Not Contain It To Gradually Build The Schema To Be Displayed With The Data
								    If ($global:attributeHeaders -notcontains $attrNonLinkedItemName) {
									    $global:attributeHeaders += $attrNonLinkedItemName
								    }

								    # Process The Data Of The Attribute
								    $attrNonLinkedValues = $null
								    $attrNonLinkedValues = $attrNonLinkedItem.value
								    $attrNonLinkedValuesString = $null
								    $attrNonLinkedValuesString = "[DEL:]" + $($attrNonLinkedValues -join "`n[DEL:]")

								    # Add The Attribute And Its Value(s) To The CS Object Being Processed
								    $object | Add-Member -MemberType NoteProperty -Name $attrNonLinkedItemName -value $attrNonLinkedValuesString
							    }
						    }

						    # Process Every Linked Attribute
						    If ($attrListLinkedFull) {
							    $attrListLinkedFull | %{
								    # Get The Attribute Item
								    $attrLinkedItem = $null
								    $attrLinkedItem = $_
								    $attrLinkedItemName = $null
								    $attrLinkedItemName = $attrLinkedItem.name

								    # Add The Attribute Item To The List Of Attribute Headers If It Does Not Contain It To Gradually Build The Schema To Be Displayed With The Data
								    If ($global:attributeHeaders -notcontains $attrLinkedItemName) {
									    $global:attributeHeaders += $attrLinkedItemName
								    }

								    # Process The Data Of The Attribute
								    $attrLinkedValues = $null
								    $attrLinkedValues = $attrLinkedItem."dn-value"
								    $attrLinkedValuesString = $null
								    $attrLinkedValuesString = "[DEL:]" + $($attrLinkedValues.dn -join "`n[DEL:]")

								    # Add The Attribute And Its Value(s) To The CS Object Being Processed
								    $object | Add-Member -MemberType NoteProperty -Name $attrLinkedItemName -value $attrLinkedValuesString
							    }
						    }
					    }
				    } Else {
					    # Increase This Counter
					    $iNoChangeNr++
				    }

				    # Just To Get The Name Of The MA/Connector Of The Last Object Being Processed
				    $script:connectorSpaceName = $csMAName

				    # Add The Processed Object To The Main List
				    $global:objectList += $object
			    }
		    }

		    Write-Host ""
		    Write-Host "Connector Space Name Processed........................: $connectorSpaceName" -ForegroundColor Cyan
		    Write-Host " > Total Number Of Objects Exported From CS...........: $exportedCSObjectTotalCount" -ForegroundColor Magenta
		    Write-Host " > Total Number Of Objects With 'ADD' Operations......: $exportedCSObjectAddsCount" -ForegroundColor Magenta
		    Write-Host " > Total Number Of Objects With 'MODIFY' Operations...: $exportedCSObjectUpdatesCount" -ForegroundColor Magenta
		    Write-Host " > Total Number Of Objects With 'DELETE' Operations...: $exportedCSObjectDeletesCount" -ForegroundColor Magenta
		    Write-Host " > Total Number Of Objects With 'NO' Operations.......: $exportedCSObjectWithNoChangesCount" -ForegroundColor Magenta
		    Write-Host ""
	    } Else {
		    Write-Host "The Source XML File '$sourceXMLfilePath' DOES NOT Exist!..." -ForegroundColor Red
		    Write-Host ""
		    Write-Host ""
	    }
    }

    # Sort The Headers For The Attribute Names
    $attributeHeaders = $global:attributeHeaders | Sort-Object

    # Concatenate The Header Lists Into One list
    $allHeaders = $mainHeaders + $attributeHeaders

    # Create The Object Report
    $objectReport = $global:objectList | Select $allHeaders | Sort-Object -Property "MA-Name","Object-Type","Ops-Type","CS-DN"

    # When Output Goes To The CSV File
    If ($outToCSV -Or $outToAll) {
	    If (!($targetFilePath.EndsWith(".csv"))) {
		    $outputFilePath = $targetFilePath + ".csv"
	    } Else {
		    $outputFilePath = $targetFilePath
	    }
	    If (Test-Path $outputFilePath) {
		    $fileSuffixNr = 0
		    Do {
			    $fileSuffixNr++
			    $fileSuffix = $($fileSuffixNr.ToString().PadLeft(4,"0"))
			    $outputFilePath = $($($outputFilePath).TrimEnd("csv").TrimEnd(".") -replace '\d{4}$','') + $fileSuffix + '.csv'

		    } While (Test-Path $outputFilePath)
	    }

	    $objectReport | Export-Csv -Path $outputFilePath -Force -NoTypeInformation

	    Write-Host ""
	    Write-Host "CSV Report File.......................................: $outputFilePath" -ForegroundColor Magenta
	    Write-Host ""

	    Start-Sleep -s 3
    }

    # When Output Goes To The GridView
    If ($outToGridView -Or $outToAll) {
	    $objectReport | Out-GridView
    }

}