function Get-FE3UpdateIDs {
    <#
    .SYNOPSIS
        Parses SyncUpdates XML response to extract update identifiers

    .DESCRIPTION
        Processes the XML response from Invoke-FE3SyncUpdates to extract UpdateIDs,
        RevisionIDs, and builds a GUID-to-PackageName mapping from File nodes.
        The mapping is stored in $script:GuidToPackageNameMap for later use.

    .PARAMETER Xml
        Raw XML string from the FE3 SyncUpdates response

    .OUTPUTS
        Hashtable with UpdateIDs, RevisionIDs, and PackageNames ArrayLists

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param([string]$Xml)
    
    [xml]$doc = New-Object System.Xml.XmlDocument
    $doc.LoadXml($Xml)
    
    $updateIDs = New-Object System.Collections.ArrayList
    $revisionIDs = New-Object System.Collections.ArrayList
    $packageNames = New-Object System.Collections.ArrayList
    
    # Map GUID → Real Package Name
    $guidToPackageName = @{}
    
    Write-Verbose "=== Building GUID to PackageName mapping ==="
    
    # Extract file names from <File FileName="GUID.appx" ... InstallerSpecificIdentifier="RealName">
    $fileNodes = $doc.GetElementsByTagName("File")
    Write-Verbose "Found $($fileNodes.Count) File nodes in SyncUpdates XML"
    
    foreach ($fileNode in $fileNodes) {
        $fileName = $fileNode.Attributes.GetNamedItem("FileName")
        $installerID = $fileNode.Attributes.GetNamedItem("InstallerSpecificIdentifier")
        
        if ($fileName) {
            Write-Verbose "  File: $($fileName.Value)"
        }
        
        if ($fileName -and $installerID) {
            $fullFileName = $fileName.Value
            $realName = $installerID.Value
            
            # Extract extension from original filename
            if ($fullFileName -match '\.(appx|msix|msixbundle|appxbundle|eappx|emsix)$') {
                $extension = $matches[0]
                $guid = $fullFileName -replace '\.(appx|msix|msixbundle|appxbundle|eappx|emsix|cab)$', ''
                
                # Store with extension as key (for bundles like "GUID.msixbundle")
                $guidToPackageName["$guid$extension"] = $realName
                Write-Verbose "    Mapped: $guid$extension → $realName"
            }
            else {
                # No recognized extension, store GUID only
                $guid = $fullFileName -replace '\.cab$', ''
                $guidToPackageName[$guid] = $realName
                Write-Verbose "    Mapped: $guid → $realName"
            }
        }
        elseif ($fileName -and -not $installerID) {
            Write-Verbose "    No InstallerSpecificIdentifier for $($fileName.Value)"
        }
    }
    
    Write-Verbose "Total mappings created: $($guidToPackageName.Count)"
    Write-Verbose "=== End of mapping ==="
    
    # Exporter le mapping pour l'utiliser plus tard
    $script:GuidToPackageNameMap = $guidToPackageName
    
    $nodes = $doc.GetElementsByTagName("SecuredFragment")
    
    Write-Verbose "Found $($nodes.Count) SecuredFragment nodes"
    
    foreach ($node in $nodes) {
        $updateNode = $node.ParentNode.ParentNode.FirstChild
        if ($updateNode.Attributes.Count -ge 2) {
            $updateID = $updateNode.Attributes[0].Value
            $revisionID = $updateNode.Attributes[1].Value
            
            [void]$updateIDs.Add($updateID)
            [void]$revisionIDs.Add($revisionID)
        }
    }
    
    return @{
        UpdateIDs = $updateIDs
        RevisionIDs = $revisionIDs
        PackageNames = $packageNames
    }
}
