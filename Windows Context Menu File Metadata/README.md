&lt;!-- Copy-Meta --&gt;
&lt;!-- https://github.com/YOUR_USERNAME/Copy-Meta --&gt;

# 📋 Copy-Meta  
**One-click Windows shell extension that copies file & folder metadata to the clipboard.**

![GitHub release (latest by date)](https://img.shields.io/github/v/release/YOUR_USERNAME/Copy-Meta)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-green.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## ✨ What it does

Right-click any file or folder → **Copy Metadata** → choose what you need.  
No dialogs, no external apps—just pure Windows Shell + PowerShell.

| Menu item            | Files | Folders | Fallback logic |
|----------------------|-------|---------|----------------|
| Title                | ✅    | ❌      | N/A if empty   |
| Media Created Date   | ✅    | ✅      | Date-Taken → Media-Created → File-Created |
| Dimensions           | ✅    | ❌      | N/A for non-media |
| Duration             | ✅    | ❌      | N/A for non-media |
| File / Folder Size   | ✅    | ✅      | Recursive for folders |
| Date Created         | ✅    | ✅      | File-system time |
| Date Modified        | ✅    | ✅      | File-system time |
| Full Path            | ✅    | ✅      | Absolute path |
| **Copy All**         | ✅    | ✅      | Pre-formatted block |

---

## 🎬 5-second demo
&lt;!-- Replace URL with your own GIF or MP4 --&gt;
![demo](https://user-images.githubusercontent.com/YOUR_USERNAME/.../copymeta.gif)

---

## 🚀 Quick install

1. **Download** the latest release zip and extract it.  
   (Or clone the repo: `git clone https://github.com/YOUR_USERNAME/Copy-Meta.git`)

2. **Double-click** `Install_CopyMeta_Menu.reg` → *Yes* to UAC / Registry prompt.

3. **Done.** Right-click any file/folder and look for “Copy Metadata”.

&gt; The PowerShell script is expected at `C:\Scripts\CopyMeta.ps1`.  
&gt; Change the path in the `.reg` file if you prefer another location.

---

## 🧹 Uninstall

Double-click `uninstall_CopyMeta_Menu.reg` and confirm.  
The menu vanishes instantly—no reboot required.

---

## ⚙️ Configuration

Open `CopyMeta.ps1` and tweak the top line:

```powershell
$DateFormat = "yyyy-MM-dd HH:mm:ss"   # ISO
# $DateFormat = "MM/dd/yyyy h:mm tt"  # US
