# Copy Metadata Extension - Documentation

## Overview

**Copy Metadata** is a Windows Shell extension that adds a customizable sub-menu to the right-click context menu of files **and folders**. It allows users to instantly copy attributes—such as Created Date, Folder Size, Media Duration, and Dimensions—directly to the clipboard without navigating complex properties windows.

## Features

* **Universal Support:** Works on both Files and Folders (Directories).
* **Smart Media Dates:** intelligently finds "Date Taken" (Photos) or "Media Created" (Videos) and falls back to the file system creation date if metadata is missing.
* **Recursive Folder Size:** Calculates the total size of a folder (including subfolders) with one click.
* **Format Cleaning:** Automatically strips invisible characters from Windows metadata to ensure dates match your preferred format.
* **Non-Destructive:** Uses native Windows PowerShell and Registry keys; no third-party software installation required.

---

## Installation

### Prerequisites

* Windows 10 or Windows 11.
* Administrator privileges (to write to the Registry).

### Step 1: Script Setup

1. Create a folder to host the script (Recommended: `C:\Scripts`).
2. Create a new file named `CopyMeta.ps1`.
3. Paste the **PowerShell code** provided in the CopyMeta.ps1 section below.
4. Save the file.

### Step 2: Registry Integration

1. Open **Notepad**.
2. Paste the **Registry code** provided in the Install_Universal_Menu.reg section below.
3. Save the file as `Install_Universal_Menu.reg`.
4. **Double-click** the file and select **Yes** when prompted by User Account Control and the Registry Editor.

## Uninstallation

1. Open **Notepad**.
2. Paste the **Registry code** provided in the Uninstall_Universal_Menu.reg section below.
3. Save the file as `Uninstall_Universal_Menu.reg`.
4. **Double-click** the file and select **Yes** when prompted by User Account Control and the Registry Editor.
---

## Usage Guide

### Basic Usage

1. **Right-click** any file OR folder in Windows Explorer.
* *Note for Windows 11:* You may need to select **Show more options** or hold `Shift` while right-clicking.


2. Hover over the **Copy Metadata** menu item.
3. Select the attribute you wish to copy.
4. **Paste** (`Ctrl+V`) the information into your desired application.

### Menu Options

| Option | Description | Logic / Fallback |
| --- | --- | --- |
| **Title** | Metadata Title | Returns `N/A` if empty. |
| **Media Created Date** | "Date Taken" or "Media Created" | Smartly checks EXIF/Video data. Falls back to **File Created Date** if missing. |
| **Media Dimensions** | Resolution (Width x Height) | Returns `N/A` for non-media files. |
| **Media Duration** | Length (Time) | Returns `N/A` for non-media files. |
| **File / Folder Size** | Size on disk | **Files:** Instant. **Folders:** Scans recursively (may take a moment). |
| **Date Created** | File System Creation Time | The timestamp the file landed on this drive. |
| **Date Modified** | Last Write Time | The timestamp the content was last changed. |
| **Full Path** | Absolute Path | `C:\Users\Docs\Video.mp4` |
| **Copy All Info** | Formatted Data Block | Copies all available fields into a clean list. |

---

## Configuration

### Changing Date Formats

To change how dates are formatted (e.g., US format vs. ISO format):

1. Open `C:\Scripts\CopyMeta.ps1` in a text editor.
2. Locate the line: `$DateFormat = "yyyy-MM-dd HH:mm:ss"`
3. Edit the string inside the quotes.
* **US Format:** `"MM/dd/yyyy h:mm tt"` (Output: `12/30/2023 2:30 PM`)
* **ISO Format:** `"yyyy-MM-dd"` (Output: `2023-12-30`)


4. Save the file. Changes are immediate.

### Changing Script Location

If you move the script from `C:\Scripts`, you must update the Registry:

1. Open the `Install_Universal_Menu.reg` file.
2. Find and Replace all instances of `C:\\Scripts\\CopyMeta.ps1` with your new path.
* *Important:* You must use double backslashes (`\\`) in the path.


3. Save and double-click the `.reg` file again to update the registry.

---

## Troubleshooting

| Issue | Cause | Solution |
| --- | --- | --- |
| **Folder Size is slow** | Large Directory | Calculating folder size requires counting every file inside. Wait a few seconds after clicking; it runs in the background. |
| **Menu missing on Folders** | Used old installer | Ensure you ran the updated `Install_Universal_Menu.reg` which adds keys to `HKEY_CLASSES_ROOT\Directory`. |
| **Dates look wrong** | Locale/Unicode issues | The latest script includes `Format-ShellDate` to clean invisible characters. Ensure you updated `CopyMeta.ps1`. |
| **"Script not found"** | Moved folder | Verify `CopyMeta.ps1` is exactly at `C:\Scripts` or update the registry path. |

---

## Source Code

### `CopyMeta.ps1`

```powershell
param (
    [string]$Path,
    [string]$Mode
)

# --- CONFIGURATION: CUSTOMIZE TIMESTAMP FORMAT HERE ---
# Examples: "yyyy-MM-dd HH:mm:ss" | "MM/dd/yyyy h:mm tt"
$DateFormat = "yyyy-MM-dd HH:mm:ss"
# ----------------------------------------------------

# Helper: Human-readable size
function Format-FileSize($bytes) {
    if ($null -eq $bytes) { return "0 Bytes" }
    $sizes = @("Bytes", "KB", "MB", "GB", "TB")
    $i = 0
    while ($bytes -ge 1024 -and $i -lt $sizes.Count - 1) {
        $bytes /= 1024
        $i++
    }
    return "$([math]::Round($bytes, 2)) $($sizes[$i])"
}

# Helper: Get Windows Shell Properties (Metadata)
function Get-ShellProp {
    param($FilePath, $Index)
    try {
        $dir = Split-Path $FilePath
        $file = Split-Path $FilePath -Leaf
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace($dir)
        $folderItem = $folder.ParseName($file)
        return $folder.GetDetailsOf($folderItem, $Index)
    } catch { return $null }
}

# Helper: Force Shell Dates to match Configuration Format
function Format-ShellDate {
    param($DateString)
    if ([string]::IsNullOrWhiteSpace($DateString)) { return $null }
    
    # Shell dates contain invisible unicode characters (LTR marks). We must strip them.
    # We replace non-printable characters to ensure clean parsing.
    $CleanString = $DateString -replace '[^\x20-\x7E]', ''
    
    try {
        # Attempt to parse the shell string into a DateTime object
        $dt = [DateTime]::Parse($CleanString)
        # Return it formatted according to user config
        return $dt.ToString($DateFormat)
    }
    catch {
        # If parsing fails (weird locale), return original string as-is
        return $DateString
    }
}

try {
    $Item = Get-Item -LiteralPath $Path -ErrorAction Stop
    $IsFolder = $Item.PSIsContainer
    $Output = ""

    switch ($Mode) {
        "Size" { 
            if ($IsFolder) {
                $stats = Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
                $Output = Format-FileSize $stats.Sum
            } else {
                $Output = Format-FileSize $Item.Length 
            }
        }
        "Created"  { $Output = $Item.CreationTime.ToString($DateFormat) }
        "Modified" { $Output = $Item.LastWriteTime.ToString($DateFormat) }
        "Path"     { $Output = $Item.FullName }
        "Name"     { $Output = $Item.Name }
        
        "Title" {
            if (-not $IsFolder) {
                $val = Get-ShellProp -FilePath $Item.FullName -Index 21
                if ([string]::IsNullOrWhiteSpace($val)) { $Output = "N/A" } else { $Output = $val }
            } else { $Output = "N/A" }
        }

        "MediaTime" {
            if (-not $IsFolder) {
                # 1. Try Date Taken (Photos)
                $raw = Get-ShellProp -FilePath $Item.FullName -Index 12
                
                # 2. Try Media Created (Videos) if #1 failed
                if ([string]::IsNullOrWhiteSpace($raw)) { 
                    $raw = Get-ShellProp -FilePath $Item.FullName -Index 208 
                }

                # 3. Format the result found
                $formatted = Format-ShellDate -DateString $raw

                # 4. Fallback to File Creation Time if nothing found
                if ([string]::IsNullOrWhiteSpace($formatted)) { 
                    $Output = $Item.CreationTime.ToString($DateFormat)
                } else { 
                    $Output = $formatted 
                }
            } else { 
                # Folders fall back to creation time
                $Output = $Item.CreationTime.ToString($DateFormat)
            }
        }

        "Dimensions" { 
            if (-not $IsFolder) {
                $val = Get-ShellProp -FilePath $Item.FullName -Index 31 
                if ([string]::IsNullOrWhiteSpace($val)) { $Output = "N/A" } else { $Output = $val }
            } else { $Output = "N/A" }
        }
        
        "Duration" { 
            if (-not $IsFolder) {
                $val = Get-ShellProp -FilePath $Item.FullName -Index 27
                if ([string]::IsNullOrWhiteSpace($val)) { $Output = "N/A" } else { $Output = $val }
            } else { $Output = "N/A" }
        }

        "All" {
            $sb = [System.Text.StringBuilder]::new()
            [void]$sb.AppendLine("Name:      $($Item.Name)")
            [void]$sb.AppendLine("Path:      $($Item.FullName)")
            
            if ($IsFolder) {
                 $stats = Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
                 [void]$sb.AppendLine("Size:      $(Format-FileSize $stats.Sum)")
            } else {
                 [void]$sb.AppendLine("Size:      $(Format-FileSize $Item.Length)")
            }

            [void]$sb.AppendLine("Created:   $($Item.CreationTime.ToString($DateFormat))")
            [void]$sb.AppendLine("Modified:  $($Item.LastWriteTime.ToString($DateFormat))")

            if (-not $IsFolder) {
                $title = Get-ShellProp -FilePath $Item.FullName -Index 21
                
                # Fetch Media Date
                $mediaRaw = Get-ShellProp -FilePath $Item.FullName -Index 12
                if ([string]::IsNullOrWhiteSpace($mediaRaw)) { 
                    $mediaRaw = Get-ShellProp -FilePath $Item.FullName -Index 208 
                }
                # Format Media Date
                $mediaFmt = Format-ShellDate -DateString $mediaRaw

                $dims  = Get-ShellProp -FilePath $Item.FullName -Index 31
                $dur   = Get-ShellProp -FilePath $Item.FullName -Index 27
                
                if (-not [string]::IsNullOrWhiteSpace($title))    { [void]$sb.AppendLine("Title:     $title") }
                if (-not [string]::IsNullOrWhiteSpace($mediaFmt)) { [void]$sb.AppendLine("MediaDate: $mediaFmt") }
                if (-not [string]::IsNullOrWhiteSpace($dims))     { [void]$sb.AppendLine("Dims:      $dims") }
                if (-not [string]::IsNullOrWhiteSpace($dur))      { [void]$sb.AppendLine("Duration:  $dur") }
            }
            
            $Output = $sb.ToString()
        }
    }

    if ($Output) { Set-Clipboard -Value $Output }
}
catch {
    [System.Windows.Forms.MessageBox]::Show("Error: $_", "Error", 0, 16)
}

```

### `Install_Universal_Menu.reg`

```registry
Windows Registry Editor Version 5.00

; =======================================================
; SECTION 1: FILES (Apply to all file types)
; =======================================================

[HKEY_CLASSES_ROOT\*\shell\CopyMetadata]
"MUIVerb"="Copy Metadata"
"SubCommands"=""
"Icon"="imageres.dll,-5301"

[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell]

; 01 Title
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\01Title]
@="Title"
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\01Title\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"Title\""

; 02 Media Date
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\02MediaTime]
@="Media Created Date"
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\02MediaTime\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"MediaTime\""

; 03 Dimensions
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\03Dimensions]
@="Media Dimensions"
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\03Dimensions\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"Dimensions\""

; 04 Duration
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\04Duration]
@="Media Duration"
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\04Duration\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"Duration\""

; Separator logic is automatic in cascading menus, but we order by number
; 05 Size
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\05Size]
@="File Size"
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\05Size\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"Size\""

; 06 Created
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\06Created]
@="Date Created"
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\06Created\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"Created\""

; 07 Modified
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\07Modified]
@="Date Modified"
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\07Modified\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"Modified\""

; 08 Path
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\08Path]
@="Full Path"
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\08Path\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"Path\""

; 09 All
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\09All]
@="Copy All Info Block"
[HKEY_CLASSES_ROOT\*\shell\CopyMetadata\shell\09All\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"All\""


; =======================================================
; SECTION 2: FOLDERS (Apply to Directories)
; =======================================================

[HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata]
"MUIVerb"="Copy Metadata"
"SubCommands"=""
"Icon"="imageres.dll,-5301"

[HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata\shell]

; 01 Size (Recursive)
[HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata\shell\01Size]
@="Folder Size"
[HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata\shell\01Size\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"Size\""

; 02 Created
[HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata\shell\02Created]
@="Date Created"
[HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata\shell\02Created\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"Created\""

; 03 Modified
[HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata\shell\03Modified]
@="Date Modified"
[HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata\shell\03Modified\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"Modified\""

; 04 Path
[HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata\shell\04Path]
@="Full Path"
[HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata\shell\04Path\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"Path\""

; 05 All
[HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata\shell\05All]
@="Copy All Info Block"
[HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata\shell\05All\command]
@="powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\CopyMeta.ps1\" -Path \"%1\" -Mode \"All\""

```
### `Uninstall_Universal_Menu.reg`

```registry
Windows Registry Editor Version 5.00

; Remove the menu from all Files
[-HKEY_CLASSES_ROOT\*\shell\CopyMetadata]

; Remove the menu from all Directories (Folders)
[-HKEY_CLASSES_ROOT\Directory\shell\CopyMetadata]

```