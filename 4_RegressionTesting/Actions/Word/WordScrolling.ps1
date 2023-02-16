Import-Module Z:\NDS_RegressionTesting\AutoItX\AutoItX.psd1

# Run notepad.exe
Start-Process "Z:\NDS_RegressionTesting\Actions\Word\WordScrollingWin10.docx"
 
# Wait for an untitled notepad window and get the handle
$Title = "WordScrollingWin10"
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
 

$timeout = 500
$iterations = 3

for ($i=1;$i -le $iterations; $i++){
    Start-Sleep -Milliseconds $timeout
    write-host ("test:" + $i)
    Send-AU3ControlKey -ControlHandle $controlHandle -Key "{PGDN}" -WinHandle $winHandle


}

Stop-Process -Name WINWORD