Function Adobe 
{

	#Start Adobe
	$process =  "{0}\CSAMC_UserGuide.pdf" -f $RootDir
	Start-Process $process

	#Wait for PDF to load
	Start-Sleep -Seconds 60

	#Get Adobe Window Focus
	$myshell = New-Object -ComObject "Wscript.Shell"
	$myshell.AppActivate("CSAMC_UserGuide.pdf - Adobe Reader")
	Start-Sleep -Seconds 2

	#Start Scrolling Down
	for($i = 0; $i -le 50; $i++)
	{
		$myshell.SendKeys("{PGDN}")
		Start-Sleep -Milliseconds 500
	}

	#Kill Adobe Process
	Stop-Process -Name AcroRd32 -force 

}

Function main () {

	Adobe

}

################### Global Variables ####################################

$RootDir        =   Split-path $MyInvocation.MyCommand.Path -Parent

#########################################################################


main