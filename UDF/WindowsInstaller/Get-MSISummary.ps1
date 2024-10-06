function Get-MSISummary {
    Param(
        [object]$MSIFile 
    )
    Begin {
        $oMSIFile = if ($MSIFile) {
            $MSIFile
        } elseif ($global:MSIFile) {
            $global:MSIFile
        } else {
            throw [System.ArgumentNullException] "MSI File not opened, please use ""Open-MSIFile"""
        }
    }
    Process {
        $oMSIFile.OpenDatabase([MsiOpenDatabaseMode]::msiOpenDatabaseModeReadOnly)
        ## Get the SummaryInformation from the windows installer database
        [__comobject]$SummaryInformation = $oMSIFile.GetDatabase().SummaryInformation()
        $hSummaryInfoProperty = [ordered]@{
            Subject = $SummaryInformation.Property(3)
            Author = $SummaryInformation.Property(4)
            Title = $SummaryInformation.Property(2)
            Keywords = $SummaryInformation.Property(5)
            Comments = $SummaryInformation.Property(6)
            RevisionNumber = $SummaryInformation.Property(9)
            Template = $SummaryInformation.Property(7)
            CreatingApplication = $SummaryInformation.Property(18)
            Security = $SummaryInformation.Property(19)
            CodePage = $SummaryInformation.Property(1)
            LastSavedBy = $SummaryInformation.Property(8)
            LastPrinted = $SummaryInformation.Property(11)
            CreateTimeDate = $SummaryInformation.Property(12)
            LastSaveTimeDate = $SummaryInformation.Property(13)
            PageCount = $SummaryInformation.Property(14)
            WordCount = $SummaryInformation.Property(15)
            CharacterCount = $SummaryInformation.Property(16)
        }
                
        return New-Object -TypeName psobject -Property $hSummaryInfoProperty
    }
}