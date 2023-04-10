$ErrorActionPreference = 'Stop'
# Get Folder Paths
$Desktop = Get-Item ([System.Environment]::GetFolderPath('Desktop'))
$Documents = Get-Item ([System.Environment]::GetFolderPath('MyDocuments'))
if (($null -eq $Desktop) -OR ($null -eq $Documents)) {
    Write-Error "Could Not Find Desktop Or Documents Folder"
    exit 99
}
#Define Attributes
[Flags()]
enum FileAttributesEX {
    ReadOnly = 0x00000001
    Hidden = 0x00000002
    System = 0x00000004
    Directory = 0x00000010
    Archive = 0x00000020
    Device = 0x00000040
    Normal = 0x00000080
    Temporary = 0x00000100
    SparseFile = 0x00000200
    ReparsePoint = 0x00000400
    Compressed = 0x00000800
    Offline = 0x00001000
    NotContentIndexed = 0x00002000
    Encrypted = 0x00004000
    IntegrityStream = 0x00008000
    Virtual = 0x00010000
    NoScrubData = 0x00020000
    EA = 0x00040000
    Pinned = 0x00080000
    Unpinned = 0x00100000
    RecallOnOpen = 0x00040000
    RecallOnDataAccess = 0x00400000
}
# Set the Pinned attribute on the Desktop and Documents folders. Unpin if unpinned. Pinned if not Pinned
$Desktop, $Documents | ForEach-Object {
    try {
        #When an exception occurs the Current Pipe Gets overwritten. We need details of the error in our report.
    $CurrentItem = $_ 
    $CurrentItem.Attributes = ($CurrentItem.Attributes -band (-bnot [FileAttributesEX]::Unpinned)) -bor [FileAttributesEX]::Pinned
    }Catch {
        Write-Error "Could Not pin $($CurrentItem.Name) root...`n$_"
        exit 99
    }
}

# Iterate through all items in the Desktop & Documents folder and its subfolders. Files created before the Root folder is pinned will not inherit the PINNED attribute. Hence the need.
$ErrorFiles = New-Object System.Collections.ArrayList
Get-ChildItem $Desktop.FullName, $Documents.FullName -Recurse | ForEach-Object {
    try {
    $CurrentItem = $_ 
    $CurrentItem.Attributes = ($CurrentItem.Attributes -band (-bnot [FileAttributesEX]::Unpinned)) -bor [FileAttributesEX]::Pinned
    }catch {
       $ErrorFiles.add($CurrentItem.FullName)
    }
}

if ($ErrorFiles.Count -ne 0) {
    Write-Error "These files could not be Processed: $([string]$ErrorFiles -split " " -join "`n")"  
    exit 98
}