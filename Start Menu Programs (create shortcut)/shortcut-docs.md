# Start Menu Shortcut Creator Documentation

## Overview
This script creates shortcuts in the Windows Start Menu with customizable names. When you send a file to this script, it will prompt you to enter a name for the shortcut (with the original filename as the default) and then create the shortcut in your Start Menu Programs folder.

## Installation

1. Create a new text file
2. Copy the code below into the file
3. Save the file as `SendToStartMenu.bat`
4. Press Win + R, type `shell:sendto` and press Enter
5. Move the `SendToStartMenu.bat` file to the opened SendTo folder

## Full Code

```batch
@echo off
setlocal EnableDelayedExpansion
:: Set the destination folder where shortcuts will be created
set "DEST_FOLDER=%appdata%\Microsoft\Windows\Start Menu\Programs"
:: Create destination folder if it doesn't exist
if not exist "%DEST_FOLDER%" mkdir "%DEST_FOLDER%"
:: Get the dropped file path and default name without extension
set "FILE_PATH=%~1"
set "DEFAULT_NAME=%~n1"
:: Create simple VBScript input box
echo Set objShell = CreateObject("WScript.Shell") > "%temp%\InputBox.vbs"
echo strInput = InputBox("Enter shortcut name:", "Create Shortcut", "%DEFAULT_NAME%") >> "%temp%\InputBox.vbs"
echo If strInput = "" Then >> "%temp%\InputBox.vbs"
echo   WScript.Echo "CANCELED" >> "%temp%\InputBox.vbs"
echo Else >> "%temp%\InputBox.vbs"
echo   WScript.Echo strInput >> "%temp%\InputBox.vbs"
echo End If >> "%temp%\InputBox.vbs"
:: Get custom name from input box
for /f "delims=" %%i in ('cscript //nologo "%temp%\InputBox.vbs"') do set "CUSTOM_NAME=%%i"
:: Delete the input VBScript
del "%temp%\InputBox.vbs"
:: Check if user clicked Cancel
if "%CUSTOM_NAME%"=="CANCELED" (
    echo Operation canceled by user.
    timeout /t 3
    exit /b
)
:: Create VBScript to make the shortcut
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%temp%\CreateShortcut.vbs"
echo sLinkFile = "%DEST_FOLDER%\%CUSTOM_NAME%.lnk" >> "%temp%\CreateShortcut.vbs"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%temp%\CreateShortcut.vbs"
echo oLink.TargetPath = "%FILE_PATH%" >> "%temp%\CreateShortcut.vbs"
echo oLink.Description = "Shortcut to %CUSTOM_NAME%" >> "%temp%\CreateShortcut.vbs"
echo oLink.WorkingDirectory = "%~dp1" >> "%temp%\CreateShortcut.vbs"
echo oLink.Save >> "%temp%\CreateShortcut.vbs"
:: Run the VBScript to create the shortcut
cscript //nologo "%temp%\CreateShortcut.vbs"
:: Clean up the temporary VBScript
del "%temp%\CreateShortcut.vbs"
:: Display success message
echo Shortcut "%CUSTOM_NAME%" created in %DEST_FOLDER%
timeout /t 3
```

## How It Works

The script performs the following steps:

1. Sets the destination folder to your Start Menu Programs folder using the %appdata% environment variable
2. Creates the destination folder if it doesn't exist
3. Gets the file path and name from the sent file
4. Creates a temporary VBScript to show an input box
5. Prompts you for the shortcut name, with the original filename (minus extension) as the default
6. Creates another temporary VBScript to create the actual shortcut
7. Creates the shortcut in your Start Menu Programs folder
8. Cleans up temporary files
9. Shows a success message

## Usage

1. Right-click any file you want to create a shortcut for
2. Go to "Send to"
3. Click "SendToStartMenu"
4. Enter the desired name for the shortcut (or press Enter to use the default name)
5. The shortcut will be created in your Start Menu Programs folder

## Parameters Used

- `%~1`: The full path of the dropped file
- `%~n1`: The filename without extension
- `%~dp1`: The directory path of the dropped file
- `%appdata%`: Points to the current user's AppData\Roaming folder
- `%temp%`: Points to the temporary files folder

## Common Issues and Solutions

1. **Input box doesn't appear**
   - Make sure you have permissions to run scripts
   - Try running the script as administrator

2. **Shortcut isn't created**
   - Check if you have write permissions in the Start Menu folder
   - Make sure the file path doesn't contain special characters

3. **Script closes immediately**
   - The script includes a pause command to keep the window open
   - Check the error message before the window closes

## Customization

To change the destination folder, modify this line:
```batch
set "DEST_FOLDER=%appdata%\Microsoft\Windows\Start Menu\Programs"
```

For example, to save shortcuts to your desktop:
```batch
set "DEST_FOLDER=%userprofile%\Desktop"
```

## Notes

- The script uses VBScript for both the input box and shortcut creation
- Temporary files are created in your %temp% folder and automatically deleted
- The script preserves the working directory of the original file
- If you cancel the input box or leave it empty, it will use the original filename
