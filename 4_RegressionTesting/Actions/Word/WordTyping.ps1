Import-Module Z:\NDS_RegressionTesting\AutoItX\AutoItX.psd1

# Run Word
Start-Process "Z:\NDS_RegressionTesting\Actions\Word\WordTypingWin10.docx"
 
# Wait for an untitled notepad window and get the handle
$Title = "WordTypingWin10"
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
 

$timeout = 35
$iterations = 3


Start-Sleep -Seconds 10
		
for ($prghcount=0; $prghcount -lt 5; $prghcount++) {

	$wordsperprgh = 30
	for ($wordcount=0; $wordcount -lt $wordsperprgh; $wordcount++){

		$wordsize=Get-Random -min 2 -max 10
		for($count = 0; $count -lt $wordsize; $count++){
		     	$character=Get-Random -min 65 -max 90
			Send-AU3ControlKey -ControlHandle $controlHandle -Key ([Char]$character) -WinHandle $winHandle
			start-sleep -milliseconds $timeout

		}
		Send-AU3ControlKey -ControlHandle $controlHandle -Key "{SPACE}" -WinHandle $winHandle		
		start-sleep -milliseconds $timeout

	}
	Send-AU3ControlKey -ControlHandle $controlHandle -Key "{ENTER}{ENTER}" -WinHandle $winHandle
	start-sleep -milliseconds $timeout
}




for ($i=1;$i -le $iterations; $i++){
    Start-Sleep -Milliseconds $timeout
    write-host ("test:" + $i)
    Send-AU3ControlKey -ControlHandle $controlHandle -Key "{PGDN}" -WinHandle $winHandle


}

Stop-Process -Name WINWORD