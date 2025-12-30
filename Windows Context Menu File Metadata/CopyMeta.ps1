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