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
echo WScript.Echo strInput >> "%temp%\InputBox.vbs"

:: Get custom name from input box
for /f "delims=" %%i in ('cscript //nologo "%temp%\InputBox.vbs"') do set "CUSTOM_NAME=%%i"

:: Delete the input VBScript
del "%temp%\InputBox.vbs"

:: If user clicked Cancel or entered nothing, use default name
if "%CUSTOM_NAME%"=="" set "CUSTOM_NAME=%DEFAULT_NAME%"

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