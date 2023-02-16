# Make use of IPConfig to find out the name of your network adapter and the search string accordingly
$adaptor = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object {$_.Name -like "*Ethernet*"}
# Location of log
$log = "c:\temp\NetworkInterface.log"
# Sleep time...may vary from 5 to 10 seconds. Please adjust accordingly 
$sleeptime = 3
# Number of iterations to repeat. 
$iteration = 5



Function LogMessage
{
    param ([string] $msg)
       
    $timeval = Get-date
    Add-Content $log "$timeval $msg"   
    Write-Host $msg
}


for ($i = 1; $i -le $iteration; $i++) {
    LogMessage "*******ITERATION $i ***************"
    LogMessage "Disabling Interface for $sleeptime seconds"
	$adaptor.Disable()
    start-sleep -s $sleeptime
	LogMessage "Enabling Interface for $sleeptime seconds"
	$adaptor.Enable()
    start-sleep -s $sleeptime
}