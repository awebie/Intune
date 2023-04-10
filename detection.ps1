$ErrorActionPreference = 'Stop'
# Get Folder Paths
$Desktop = Get-Item ([System.Environment]::GetFolderPath('Desktop'))
$Documents = Get-Item ([System.Environment]::GetFolderPath('MyDocuments'))
if (($null -eq $Desktop) -OR ($null -eq $Documents)) {
    Write-Error "Could Not Find Desktop Or Documents Folder"
    exit 99
}
# Verify KFM is On
# If Documents or Desktop are not in OneDrive then we don't need to pin them
if (($Desktop.FullName -notmatch "OneDrive") -OR ($Documents.FullName -notmatch "Onedrive")) {
    Write-Output "NOKFM"
    exit 0
} 
# Define Attributes
[Flags()]
 enum FileAttributesEX {
     ReadOnly                  = 0x00000001
     Hidden                    = 0x00000002
     System                    = 0x00000004
     Directory                 = 0x00000010
     Archive                   = 0x00000020
     Device                    = 0x00000040
     Normal                    = 0x00000080
     Temporary                 = 0x00000100
     SparseFile                = 0x00000200
     ReparsePoint              = 0x00000400
     Compressed                = 0x00000800
     Offline                   = 0x00001000
     NotContentIndexed         = 0x00002000
     Encrypted                 = 0x00004000
     IntegrityStream           = 0x00008000
     Virtual                   = 0x00010000
     NoScrubData               = 0x00020000
     EA                        = 0x00040000
     Pinned                    = 0x00080000
     Unpinned                  = 0x00100000
     RecallOnOpen              = 0x00040000
     RecallOnDataAccess        = 0x00400000
 }

# Check Pinning for Documents and Desktop
[bool]$DesktopIsPinned = ($Desktop.Attributes -band [FileAttributesEX]::Pinned) -eq [FileAttributesEX]::Pinned.Value__
[bool]$DesktopIsUnPinned = ($Desktop.Attributes -band [FileAttributesEX]::Unpinned) -eq [FileAttributesEX]::Unpinned.Value__
[bool]$DocumentsIsPinned = ($Documents.Attributes -band [FileAttributesEX]::Pinned) -eq [FileAttributesEX]::Pinned.Value__
[bool]$DocumentsUnIsPinned = ($Documents.Attributes -band [FileAttributesEX]::Unpinned) -eq [FileAttributesEX]::Unpinned.Value__
if ($DesktopIsPinned -and $DocumentsIsPinned -and (-not ($DesktopIsUnPinned -or $DocumentsUnIsPinned))) {
    #Desktop and Documents are pinned check if Desktop subfolders and files are
    Get-ChildItem $Desktop,$Documents -Recurse | ForEach-Object {
        # Check if the item is Pinned and/or Unpinned
        $isPinned = [bool](($_.Attributes -band [FileAttributesEX]::Pinned) -eq [FileAttributesEX]::Pinned)
        $isUnpinned = [bool](($_.Attributes -band [FileAttributesEX]::Unpinned) -eq [FileAttributesEX]::Unpinned)
        if ((-not $isPinned) -or ($isUnpinned)) {
            Write-Output "FoldersUnpinned"
            exit 1
        }
    }
            # Got through the gauntlet everything is pinned
            Write-Output "ALLFoldersPinned"
            exit 0 
}
else {
    Write-Output  "SubFoldersUnpinned"
    exit 1
}