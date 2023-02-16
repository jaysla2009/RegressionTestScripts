Import-Module Z:\NDS_RegressionTesting\AutoItX\AutoItX.psd1

# Run notepad.exe
Start-Process "Z:\NDS_RegressionTesting\Actions\PowerPoint\sample_presentation.pptx"

Start-Sleep -Seconds 30
 
# Wait for an untitled notepad window and get the handle
$Title = "sample_presentation - Microsoft PowerPoint"
Wait-AU3Win -Title $Title
$winHandle = Get-AU3WinHandle -Title $Title
Write-Host ("winhandle: " + $winhandle)

#get app windows status
$ws = get-au3winstate -title $Title
Write-Host ("Winstate " + $ws) 
 
# Activate the window
Show-AU3WinActivate -WinHandle $winHandle

#get app windows status
$ws = get-au3winstate -title $Title
Write-Host ("Winstate " + $ws) 


 
# Get the handle of the notepad text control for reliable operations
$controlHandle = Get-AU3ControlHandle -WinHandle $winhandle -Control "Edit1"
 
# Change the edit control
#Set-AU3ControlText -ControlHandle $controlHandle -NewText "Hello! This is being controlled by AutoIt and PowerShell!" -WinHandle $winHandle
 
# Send some keystrokes to the edit control
Send-AU3ControlKey -ControlHandle $controlHandle -Key "{F5}" -WinHandle $winHandle
Start-Sleep -Seconds 5

$timeout = 500
$iterations = 15

for ($i=1;$i -le $iterations; $i++){
    Start-Sleep -Milliseconds $timeout
    write-host ("test:" + $i)
    Send-AU3ControlKey -ControlHandle $controlHandle -Key "{PGDN}" -WinHandle $winHandle


}

Start-Sleep -Seconds 5
Send-AU3ControlKey -ControlHandle $controlHandle -Key "{ESC}" -WinHandle $winHandle



Stop-Process -Name PowerPnt