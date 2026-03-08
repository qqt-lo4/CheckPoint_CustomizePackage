function New-OfficeDeploymentConfiguration {
    <#
    .SYNOPSIS
        Generates an Office Deployment Tool XML configuration file

    .DESCRIPTION
        Creates an XML configuration file compatible with Office Deployment Tool
        for deploying Microsoft Office products.

    .PARAMETER Products
        Array of Office products to install. Examples:
        - O365ProPlusRetail (Microsoft 365 Apps for enterprise)
        - O365BusinessRetail (Microsoft 365 Apps for business)
        - ProPlus2019Retail, ProPlus2021Retail, ProPlus2024Volume
        - Standard2019Retail, Standard2021Retail
        - HomeBusinessRetail, PersonalRetail
        And many others...

    .PARAMETER ExcludeApps
        Array of Office applications to exclude. Examples:
        Access, Excel, Groove (OneDrive), Lync (Skype), OneNote, Outlook,
        PowerPoint, Publisher, Teams, Word, Bing, OneDrive

    .PARAMETER Language
        Language ID (default: fr-fr). Examples: en-us, de-de, es-es, fr-FR

    .PARAMETER OfficeClientEdition
        Office architecture: 64 or 32 (default: 64)

    .PARAMETER Channel
        Update channel. Examples:
        - Current, MonthlyEnterprise, SemiAnnual, SemiAnnualPreview (Subscription)
        - PerpetualVL2019, PerpetualVL2021, PerpetualVL2024 (Volume License)
        And others...

    .PARAMETER OutputPath
        Path where to save the XML configuration file

    .PARAMETER AcceptEULA
        Automatically accept the EULA (default: $true)

    .PARAMETER PinIconsToTaskbar
        Pin Office icons to taskbar (default: $false)

    .PARAMETER DisplayLevel
        Installation display level: None, Full (default: None for silent)

    .PARAMETER AutoActivate
        Enable automatic activation (default: $true)

    .OUTPUTS
        Returns the path to the generated XML file

    .EXAMPLE
        New-OfficeDeploymentConfiguration -Products "O365ProPlusRetail" -OutputPath "C:\Temp\office-config.xml"
        Generates a configuration for Microsoft 365 Apps for enterprise

    .EXAMPLE
        New-OfficeDeploymentConfiguration -Products "O365ProPlusRetail" -ExcludeApps "Teams","Groove" -Language "en-us" -OutputPath "C:\Temp\config.xml"
        Generates configuration excluding Teams and OneDrive

    .EXAMPLE
        New-OfficeDeploymentConfiguration -Products "ProPlus2024Volume" -Channel "PerpetualVL2024" -Language "fr-FR" -OutputPath "C:\Temp\office2024.xml"
        Generates configuration for Office Professional Plus 2024 Volume License

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string[]]$Products,

        [Parameter(Mandatory=$false)]
        [string[]]$ExcludeApps,

        [Parameter(Mandatory=$false)]
        [string]$Language = "fr-fr",

        [Parameter(Mandatory=$false)]
        [ValidateSet("64", "32")]
        [string]$OfficeClientEdition = "64",

        [Parameter(Mandatory=$false)]
        [string]$Channel = "Current",

        [Parameter(Mandatory=$true)]
        [string]$OutputPath,

        [Parameter(Mandatory=$false)]
        [bool]$AcceptEULA = $true,

        [Parameter(Mandatory=$false)]
        [bool]$PinIconsToTaskbar = $false,

        [Parameter(Mandatory=$false)]
        [ValidateSet("None", "Full")]
        [string]$DisplayLevel = "None",

        [Parameter(Mandatory=$false)]
        [bool]$AutoActivate = $true
    )

    # Create XML document
    $xmlWriter = New-Object System.Xml.XmlTextWriter($OutputPath, [System.Text.Encoding]::UTF8)
    $xmlWriter.Formatting = [System.Xml.Formatting]::Indented
    $xmlWriter.Indentation = 2

    # Start document
    $xmlWriter.WriteStartDocument()
    $xmlWriter.WriteStartElement("Configuration")

    # Add element
    $xmlWriter.WriteStartElement("Add")
    $xmlWriter.WriteAttributeString("OfficeClientEdition", $OfficeClientEdition)
    $xmlWriter.WriteAttributeString("Channel", $Channel)

    # Add each product
    foreach ($product in $Products) {
        $xmlWriter.WriteStartElement("Product")
        $xmlWriter.WriteAttributeString("ID", $product)

        # Add language
        $xmlWriter.WriteStartElement("Language")
        $xmlWriter.WriteAttributeString("ID", $Language)
        $xmlWriter.WriteEndElement() # Language

        # Add excluded apps
        if ($ExcludeApps -and $ExcludeApps.Count -gt 0) {
            foreach ($app in $ExcludeApps) {
                $xmlWriter.WriteStartElement("ExcludeApp")
                $xmlWriter.WriteAttributeString("ID", $app)
                $xmlWriter.WriteEndElement() # ExcludeApp
            }
        }

        $xmlWriter.WriteEndElement() # Product
    }

    $xmlWriter.WriteEndElement() # Add

    # Display element
    $xmlWriter.WriteStartElement("Display")
    $xmlWriter.WriteAttributeString("Level", $DisplayLevel)
    $xmlWriter.WriteAttributeString("AcceptEULA", $AcceptEULA.ToString().ToUpper())
    $xmlWriter.WriteEndElement() # Display

    # Property element
    $xmlWriter.WriteStartElement("Property")
    $xmlWriter.WriteAttributeString("Name", "PinIconsToTaskbar")
    $xmlWriter.WriteAttributeString("Value", $PinIconsToTaskbar.ToString().ToUpper())
    $xmlWriter.WriteEndElement() # Property

    if ($AutoActivate) {
        $xmlWriter.WriteStartElement("Property")
        $xmlWriter.WriteAttributeString("Name", "AUTOACTIVATE")
        $xmlWriter.WriteAttributeString("Value", "1")
        $xmlWriter.WriteEndElement() # Property
    }

    # End Configuration
    $xmlWriter.WriteEndElement() # Configuration
    $xmlWriter.WriteEndDocument()

    # Close and save
    $xmlWriter.Flush()
    $xmlWriter.Close()

    Write-Verbose "Office configuration file created: $OutputPath"
    return $OutputPath
}
