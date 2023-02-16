
Function PowerPoint-Play {

    $myshell = New-object -ComObject "Wscript.shell"

    $filepath = "C:\temp\NDS_PerformanceTest\Actions\PowerPoint\sample_presentation.pptx"
    Start-Process $filepath
    Start-Sleep -Seconds 5
    
    $myshell.AppActivate("sample_Presentation.pptx - Powerpoint")
    Start-Sleep -Seconds 2
    
    $myshell.SendKeys("{F5}")

    
    for($i = 1; $i -le 25; $i++) #### sang
    {
        $myshell.SendKeys("{Down}")
        Start-Sleep -Seconds 5
    }
    
    $myshell.SendKeys("{ESC}")
    Start-Sleep -Seconds 5
    Stop-Process -Name Powerpnt -Force

}

Function main () {

	PowerPoint-Play

}

################### Global Variables ####################################

$RootDir        =   Split-path $MyInvocation.MyCommand.Path -Parent

#########################################################################


main