#
# NDSPerfTest_vs.ps1
#
Param(
    [String]$PerfTestPath = (Split-Path $script:MyInvocation.MyCommand.Path),
    [String]$PerfTestConfigName = "NDSPerfTestConfig.xml",
    [String]$PerfTestErrLogName = "NDSPerfTest_Error.log",
    [String]$PerfTestLogName    = "NDSPerfTest",
    [String]$PerfCounterCSVName = "NDSPerfTestReports",
    [String]$LocalPath          = $MyInvocation.MyCommand.Path,
    [String]$LocalDir           = ($MyInvocation.MyCommand.Path).substring(0, $LocalPath.LastIndexOf("\"))
)

#########################################################################################################
##################################### Dymanic Module Functions ##########################################
#########################################################################################################


# Function ConvertToScriptblock converts string to new function module
# Params $Str --- The function name and script in string format
Function ConvertToScriptblock([String]$Str){
    Try{
        $ScriptBlock = [scriptblock]::Create($Str)
        New-Module -ScriptBlock $ScriptBlock
    }
    Catch{
        $ErrorMessage = "["+$_.InvocationInfo.ScriptLineNumber+"] "+$_.Exception.Message+" "+$_.InvocationInfo.PositionMessage
        $ItemName = $MyInvocation.MyCommand.Name.PadRight(25)
        LogMessage $PerfTestErrLogPath "[$ItemName] - $ErrorMessage"
    }
}

# Function LoadFunctions get the parameter number, code content from configuration file and format them into a function
# Params $Codes --- The sciprt content defined in configuration file
# Params $Name  --- The name of function
# Params $Num   --- The number of parameters will be in the function
Function LoadFunctions([String]$Codes, [String]$Name, [String]$Num){
    Try{
        $FuncName   = "TestAction" + $Name; $FuncsCRIPT = $Codes
        $Num = $Num -as [int]            ; $ParamList = ""
        For($lf = 0; $lf -lt $Num; $lf++){
            If($lf -gt 0){$ParamList = $ParamList + ", "}
            $ParamList = $ParamList + "[String]`$p$lf"     
        }
		
        $Scripts    = "Function " + $FuncName +"($ParamList){`$Value = $FuncsCRIPT; Return `$Value}"
        ConvertToScriptblock($Scripts)
    }
    Catch{
        $ErrorMessage = "["+$_.InvocationInfo.ScriptLineNumber+"] "+$_.Exception.Message+" "+$_.InvocationInfo.PositionMessage
        $ItemName = $MyInvocation.MyCommand.Name.PadRight(25)
        LogMessage $PerfTestErrLogPath "[$ItemName] - $ErrorMessage"
    }
}

# Function LoadPredefinedFunctions loads function scripts defined in configuration before health check script running
# Params $ParentNode --- the <HealthCheckTypes> node in Configuration file that contains test function content 
Function LoadDynamicModules([Xml.XmlElement]$ParentNode){
    Try{
        $Nodes = $ParentNode.ActionType
        Foreach($Node in $Nodes){
            LoadFunctions $Node.innerText $Node.Name $Node.ParamNum
    }}
    Catch{
        $ErrorMessage = "["+$_.InvocationInfo.ScriptLineNumber+"] "+$_.Exception.Message+" "+$_.InvocationInfo.PositionMessage
        $ItemName = $MyInvocation.MyCommand.Name.PadRight(25)
        LogMessage $PerfTestErrLogPath "[$ItemName] - $ErrorMessage"
    }
}

#########################################################################################################


Function CleanLogFile{
    $File = "$LocalDir\Reports\TestLog.txt"
    If(Test-Path $File){
        Clear-Content $File
    }
}

Function LogMessage([string]$PerfTestLogPath,[String]$Msg){
    $Timeval =  Get-date -Format [MM-dd-yyyy:HH:mm:ss]
    Add-Content $PerfTestLogPath  "$Timeval $Msg"
}

# Function will get display mode loaded from DisplayModes
Function Get-DisplayMode([Xml.XmlElement]$ParentNode){
    $displaymode = "Cannot determine display mode"
    try{
        $modes = $ParentNode.DisplayModes | Select-Object -ExpandProperty displaymode        
        foreach ($mode in $modes){
            $wmiQuery = (gwmi -Class $mode.Class -Namespace $mode.NameSpace -Property $mode.Properties)
            [bool]$Value = $false
			$stringreplace = $mode.InnerText.replace('$','$wmiquery.')
			$compare = if ((Invoke-Expression $stringreplace)){$value = $true}else{$Value=$false}
            if ($Value -eq $true){
                Return $mode.Name
                break;
            }
        }        
    }
    catch{
        $ErrorMessage = "["+$_.InvocationInfo.ScriptLineNumber+"] "+$_.Exception.Message+" "+$_.InvocationInfo.PositionMessage
        $ItemName = $MyInvocation.MyCommand.Name.PadRight(25)
        LogMessage $HealthCheckErrLogPath "[$ItemName] - $ErrorMessage" 
        Return $displaymode       
    }
    Return $displaymode
}

#Delete next block if above is successful.
<#$modes = $xmldata.NDSPerformanceTest.DisplayModes | select-object -ExpandProperty displaymode
foreach ($mode in $modes){
        write-host $mode
            $wmiQuery = (gwmi -Class $mode.Class -Namespace $mode.NameSpace -Property $mode.Properties)
            $Value = $mode.InnerText.replace('$','$wmiquery.')
            if ($Value.ToString()){
                Return $mode.Name
                break;
            }
        }#>
								        
Function Load-WMICounters ([string]$ConfigPath, [string]$Sensor, [string]$GraphicMode){
    
    $LogPath = $LogPath
    $CfgPath = $ConfigPath
    
    [xml]$Content = Get-Content $CfgPath   
	$TestSuiteName = $Content.NDSPerformanceTest.TestSuite.Name
	$SensorObj  = $Content.NDSPerformanceTest.Sensors.PerformanceCounters | Where-Object {$_.name -eq "$Sensor"}
	$CounterObj	= $SensorObj.Counter | Where-Object {$_.name -eq "$GraphicMode"}
	$Counter	= $CounterObj.InnerText
	$NameSpace 	= $CounterObj.NameSpace
	$Class 		= $CounterObj.Class
	$Interval 	= 1
	#If ($SensorObj.Path -match "LocalDir"){$SensorObj.Path = ($Localdir + $SensorObj.Path.tostring().replace("`$Localdir",""))}
	If ($SensorObj.Path -match "LocalDir"){$SensorObjpath = ($Localdir + $SensorObj.Path.Substring(9))}		
	#$Logpath 	= "{0}\NDSPerfTestReports_{1}_{2}_{3}.csv" -f $SensorObj.Path,$TestSuiteName,$Sensor,$Time
	#$Logpath 	= "{0}\NDSPerfTestReports_{1}_{2}_{3}.csv" -f $SensorObjpath,$TestSuiteName,$Sensor,$Time

	$Logpath 	= "{0}\$(hostname)_{1}_{2}_{3}.csv" -f $SensorObjpath,$TestSuiteName,$Sensor,$Time		

	
	#Write-Host ("LEO"+$sensorobjpath)
	#write-host ("LEO"+$LogPath)


	$func = {

		Function get-ndscounter {
		param (
         [Parameter(Mandatory=$false,Position =0)] [string] $NameSpace,
		 [Parameter(Mandatory=$false,Position =1)] [string] $Class,
		 [Parameter(Mandatory=$false,Position =2)] [string] $Parameter,
		 [Parameter(Mandatory=$false,Position =3)] [int] $Interval,
		 [Parameter(Mandatory=$false,Position =4)] [string] $Logpath,
		 [Parameter(Mandatory=$false,Position =4)] [string] $TMPactiont
		)
				
        while ($true){
			try{
				$leotest = gc $TMPactiont -Tail 1
				if ($leotest -eq $null){
				$leotest = ("No Current TestCase,No Current Action")
				}
				$leotest = $leotest.Split(",")
				$Global:currentTestcaseNamet = $leotest[0]
				$Global:currentActiont = $leotest[1]
				$paramvalue=Get-WmiObject -Namespace $NameSpace -Class $class
                $t = Get-date
				$currentvalue=[int]($paramvalue.$Parameter[0]);
				Add-Content $logpath "[$t],$currentvalue,$currentTestcaseNamet,$currentActiont"
				sleep $interval;
            }
            Catch{
                Write-Verbose "Unable to get current value"
                break;
            }

        }
		}	
	
	}
	
	$ScriptBlock = {get-ndscounter -NameSpace $args[0] -class $args[1] -parameter $args[2] -interval $args[3] -logpath $args[4] -TMPactiont $args[5]}

	Start-Job -initializationScript $func -ScriptBlock $ScriptBlock -ArgumentList $NameSpace, $Class, $Counter, $Interval, $LogPath, $TMPaction.Fullname
}

Function Load-PerfmonCounters([string]$ConfigPath, [string]$Sensor){
    
    $LogPath = $LogPath
    $CfgPath = $ConfigPath
	       
    [xml]$Content = Get-Content $CfgPath   
    
	$TestSuiteName = $Content.NDSPerformanceTest.TestSuite.Name
	
	$Counters     = ($Content.NDSPerformanceTest.Sensors.PerformanceCounters | Where-Object {$_.name -eq "$Sensor"}).Counter
	$CounterPath  = ($Content.NDSPerformanceTest.Sensors.PerformanceCounters | Where-Object {$_.name -eq "$Sensor"}).Path
    
    If ($CounterPath -match "LocalDir"){$CounterPathreport = ($Localdir + $CounterPath.Substring(9))}
	$LogPath = "{0}\$(hostname)_{1}_{2}_{3}.csv" -f $CounterPathreport,$TestSuiteName,$Sensor,$Time
	#prev_ver
    #$ScriptBlock = {$args[0] | Get-Counter -SampleInterval 1 -continuous | Export-Counter -fileformat csv -force -Path $args[1]}
	
	$scriptblock = {
		$path = $args[1].ToString()
		$path = $path.Insert(($path.Length - 4),"_TMP")
		$args[0] | Get-Counter -SampleInterval 1 -Continuous | Export-Counter -FileFormat csv -force -Path $path
	}

	<#$scriptblock3init = {

    function Wait-FileChange {
        param(
            [Parameter(Mandatory=$false, Position = 0)][string]$File,
            [Parameter(Mandatory=$false, Position = 1)][string]$Action
        )
        $FilePath = Split-Path $File -Parent
        $FileName = Split-Path $File -Leaf
        $filechangeScriptBlock = [scriptblock]::Create($Action)

        $Watcher = New-Object IO.FileSystemWatcher $FilePath, $FileName -Property @{ 
            IncludeSubdirectories = $false
            EnableRaisingEvents = $true
        }
		$onChange = Register-ObjectEvent $Watcher Changed -Action {$global:FileChanged = $true}
		while ($true){
			while ($global:FileChanged -eq $false){
            Start-Sleep -Milliseconds 10
        }

        & $filechangeScriptBlock
		}
        
		$global:FileChanged = $false
        Unregister-Event -SubscriptionId $onChange.Id
    }
}#>

	<#$scriptblock3 = {
		$path = $args[0].ToString()
		$path = $path.Insert(($path.Length - 4),"_TMP")
		$exportpath = $args[0]
		$global:FileChanged = $false

		#while($true){
			#Try{
				$Action = {$import = import-csv $path ;for ($i=($import.Count - 1);$i-ilt$import.Count;$i++){$import[$i] | Select-Object *,@{n='CurrentAction';e={Get-date}} | Export-Csv -NoTypeInformation $exportpath -Append}
							}
				Wait-FileChange $path $Action
			#}
			#catch{
			#	Write-Verbose "something went wrong"
			#	break;
			#}
#}

    }#>

    
    Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Counters , $LogPath
#	start-job -InitializationScript $scriptblock3init -ScriptBlock $scriptblock3 -ArgumentList $LogPath

	#TEST new job no init
	$scriptblock3 = {
		$logpath = $args[0]
		$tempLogpath = $logpath.ToString()
		$tempLogpath = $tempLogpath.Insert(($tempLogpath.Length - 4),"_TMP")
		$TMPaction = $args[1]

		#$global:FileChanged = $false

	function Wait-FileChange {
			param(
				[Parameter(Mandatory=$false, Position = 0)][string]$File,
				[Parameter(Mandatory=$false, Position = 1)][string]$Action
			)
		$global:FileChanged = $false
		Function write-toxml {
			param(
				[Parameter(Mandatory=$false, Position = 0)][string]$File,
				[Parameter(Mandatory=$false, Position = 0)][string]$Currentactiont,
				[Parameter(Mandatory=$false, Position = 0)][string]$currentTestcaseNamet
				)
			$import = import-csv $File
			for ($i=($import.Count - 1);$i-ilt$import.Count;$i++){
				$import[$i] | Select-Object *,@{n='CurrentTestcase';e={$currentTestcaseNamet}},@{n='CurrentAction';e={$currentactiont}} | Export-Csv -NoTypeInformation $LogPath -Append
				}
				$global:FileChanged = $false
			}

			#$global:FileChanged = $false
			$FilePath = Split-Path $File -Parent
			$FileName = Split-Path $File -Leaf
			#$ScriptBlock = [scriptblock]::Create($Action)

			$Watcher = New-Object IO.FileSystemWatcher $FilePath, $FileName -Property @{ 
				IncludeSubdirectories = $false
				EnableRaisingEvents = $true
			}
			$onChange = Register-ObjectEvent $Watcher Changed -Action {$global:FileChanged = $true}

			while ($true){
				Try{
					while ($global:FileChanged -eq $false){
						Start-Sleep -Milliseconds 100
						}
					if ($global:FileChanged -eq $true){
					$leotest = gc $TMPaction -Tail 1
					if ($leotest -eq $null){
					$leotest = ("No Current TestCase,No Current Action")
					}
					$leotest = $leotest.Split(",")
					$currentTestcaseNamet = $leotest[0]
					$currentActiont = $leotest[1]
					write-toxml -File $File -Currentactiont $currentActiont -currentTestcaseNamet $currentTestcaseNamet
					#Unregister-Event -SubscriptionId $onChange.Id 
					}
				}
				Catch {
					write-host "something went wrong"
				}
					
						}
				}
			
		
		#while ($true){
	#$Action = {$import = import-csv $tempLogpath ; for ($i=($import.Count - 1);$i-ilt$import.Count;$i++){$import[$i] | Select-Object *,@{n='CurrentAction';e={Get-date}} | Export-Csv -NoTypeInformation $LogPath -Append
	#			} }
			Wait-FileChange -file $tempLogpath
		#$global:FileChanged = $true
		#	}
	}
	Start-Job -ScriptBlock $ScriptBlock3 -ArgumentList $LogPath, $TMPaction.Fullname
	
}




Function CleanBackGroundJob{
    Get-Job | Stop-Job | Remove-Job
}

<#Function Global:Send-AU3Keys([System.ValueType]$WinHandle, [System.ValueType]$ControlHandle, [int]$Times, [int]$SleepTime, [string]$Key){
    
    For($i=0;$i-lt$Times;$i++){
        If($ControlHandle -eq $Null){        
            Send-AU3Key -Key $Key 
        }
        Else{
            Send-AU3ControlKey -WinHandle $winHandle -ControlHandle $controlHandle -Key $Key 
        }
        If($SleepTime -ne $Null -And $SleepTime -ne 0){
            Start-Sleep -Milliseconds $SleepTime
        }
    }
}#>
Function Global:Send-AU3Keys([string]$title,[int]$Times, [int]$SleepTime, [string]$Key){
    $winHandle = Get-AU3WinHandle -Title $title
    $controlHandle = Get-AU3ControlHandle -WinHandle $winhandle

    For($i=0;$i-lt$Times;$i++){
        If($ControlHandle -eq $Null){        
            Send-AU3Key -Key $Key
        }
        Else{

            Send-AU3ControlKey -WinHandle $winHandle -ControlHandle $controlHandle -Key $Key 
        }
        If($SleepTime -ne $Null -And $SleepTime -ne 0){
            Start-Sleep -Milliseconds $SleepTime
        }
    }
}


Function Global:MoveWindows([string]$Title, [int]$Time, [string]$Button, [int]$X2, [int]$Y2){

    Show-AU3WinActivate -Title $Title
    Wait-AU3WinActive   -Title $Title -Timeout 10
    $WinHandle = Get-AU3WinHandle -Title $Title
    $WinPos    = Get-AU3WinPos -Title $Title
    $X = $WinPos.X+40
    $Y = $WinPos.Y-15

    Invoke-AU3MouseClickDrag -Button $Button -X1 $X -Y1 $Y -X2 $X2 -Y2 $Y2
    Start-Sleep -s $Time
}


#########################################################################################################
######################################## Test Suite Functions ###########################################
#########################################################################################################
Function CheckCondition([String]$Text){
    Try {
        If($Text -eq $Null -or $Text.trim() -eq ""){Return $True}
        
        $Text = $Text.Trim()
        $TextArray = $Text -split '[.,()\\?!<>""'']'
        Foreach($Str in $TextArray){
			If($Str.StartsWith("$")   -and $Variables.ContainsKey($Str.Substring(1).trim())){
                $ReplaceValue = $Variables.($Str.Substring(1).trim())
				$Text = $Text.Replace($Str,$ReplaceValue)
            }
            If($Str.StartsWith("'$")   -and $Variables.ContainsKey($Str.Substring(2).trim())){
                $ReplaceValue = $Variables.($Str.Substring(2).trim())
				$Text = $Text.Replace($Str,$ReplaceValue)
            }
		}
        $Value = Invoke-Expression($Text)
        If($Value -eq $True){Return $True}
        Else{Return $False}
    }
    Catch{ 
        $ErrorMessage = "["+$_.InvocationInfo.ScriptLineNumber+"] "+$_.Exception.Message+" "+$_.InvocationInfo.PositionMessage
        $ItemName = $MyInvocation.MyCommand.Name.PadRight(25)
        LogMessage $HealthCheckErrLogPath "[$ItemName] - $ErrorMessage" 
        Return $False       
    }
}


Function CheckVariables([String]$Text){
    Try {
        $Text = $Text.Trim()
        $TextArray = $Text -split '[.,()\\?!<>""'']'
        Foreach($Str in $TextArray){
			If($Str.StartsWith("$")   -and $Variables.ContainsKey($Str.Substring(1).trim())){
                $ReplaceValue = $Variables.($Str.Substring(1).trim())
				$Text = $Text.Replace($Str,$ReplaceValue)
            }
            If($Str.StartsWith("'$")   -and $Variables.ContainsKey($Str.Substring(2).trim())){
                $ReplaceValue = $Variables.($Str.Substring(2).trim())
				$Text = $Text.Replace($Str,$ReplaceValue)
            }
		}
        If($Text -ne $Null -and ($Text.Contains(" ") -or $Text -like "[<>?,./:;|\{}]*" -or $Text -like "[_+-=]*" -or $Text -like "[()&*^%]*" -or $Text -like "[$#@!~]*")){
            $Text = "`'"+$Text+"`'" 
        }
    }
    Catch{ 
        $ErrorMessage = "["+$_.InvocationInfo.ScriptLineNumber+"] "+$_.Exception.Message+" "+$_.InvocationInfo.PositionMessage
        $ItemName = $MyInvocation.MyCommand.Name.PadRight(25)
        LogMessage $HealthCheckErrLogPath "[$ItemName] - $ErrorMessage"        
    }
    Return $Text
}


Function StringToArray([string]$Text, [string]$Split){
    $Params = @()
    Try {       
        If($Split -ne $Null -and $Split -ne ""){
            $Arrays = $Text.Split($Split)
            foreach($Item in $Arrays){ $Params += CheckVariables $Item}      
        }
        Else{$Params += CheckVariables $Text}
    }
    Catch{ 
        $ErrorMessage = "["+$_.InvocationInfo.ScriptLineNumber+"] "+$_.Exception.Message+" "+$_.InvocationInfo.PositionMessage
        $ItemName = $MyInvocation.MyCommand.Name.PadRight(25)
        LogMessage $HealthCheckErrLogPath "[$ItemName] - $ErrorMessage"        
    }
    Return [String[]]$Params  
}


Function GetValue([String]$Name, [String]$Type, [String]$Content, [String]$Split){

    Try{
        If($Type -eq $null -or $Type -eq ""){Return $Content}
        If($Type -eq "Text"  ){Return $Content}
        If($Type -eq "Header"){Return $Content}
        $Strings = $Content.Replace("^,","~").Split(",")
        Foreach($String in $Strings){
            $String = $String.Replace("~",",").Trim()
            $Params = StringToArray $String $Split

            Write-Host "TestAction$Type $Params"
            $Value  = Invoke-Expression "TestAction$Type $Params"
            Write-Host $Value
            If(($Value -ne $Null) -and ($Value.ToString().trim() -ne "") -and ($Value -ne $False)){Return $Value}        
        }
        If([string]$Value -eq "$False") {Return "False" }
        If([string]$Value -eq "0")      {Return "0" }
        If($Value -eq $Null -or $Value.ToString().trim() -eq ""){Return "Done"}
        Return $Value
    }
    Catch{
        $ErrorMessage = "["+$_.InvocationInfo.ScriptLineNumber+"] "+$_.Exception.Message+" "+$_.InvocationInfo.PositionMessage
        $ItemName = $MyInvocation.MyCommand.Name.PadRight(25)
        LogMessage $PerfTestErrLogPath "[$ItemName] - $ErrorMessage"
        Return "Failed"
    }
}


Function RunTestAction([Xml.XmlElement]$ItemNode){
    Try{
        $Value = GetValue $ItemNode.Name $ItemNode.Type $ItemNode.InnerText $ItemNode.Split
        $GloablVar = $ItemNode.GlobalVar
        If($GloablVar -ne $null -and $GloablVar -ne ""){
            If($Variables.ContainsKey($GloablVar)){
                $Variables.Remove($GloablVar)
            }
            $Variables.Add($GloablVar,$Value)
        }
        Return $Value 
    }
    Catch{ 
        $ErrorMessage = "["+$_.InvocationInfo.ScriptLineNumber+"] "+$_.Exception.Message+" "+$_.InvocationInfo.PositionMessage
        $ItemName = $MyInvocation.MyCommand.Name.PadRight(25)
        LogMessage $PerfTestErrLogPath "[$ItemName] - $ErrorMessage"  
        Return "Failed"
    }
}


Function RunTestSuite([Xml.XmlElement]$ParentNode){
    $Global:Variables = @{}
    $Variables.add("LocalDir" ,$LocalDir)
    $Variables.add("LocalPath",$LocalPath)
	

	
    Try{
        foreach($TestSuite in $ParentNode.TestSuite){
            $TestSuiteName = $TestSuite.Name
            LogMessage $PerfTestLogPath (CheckCondition ($TestSuite.Condition))
            If($TestSuite.IsRun -eq "False" -or (-not (CheckCondition $TestSuite.Condition))){Continue}
            LogMessage $PerfTestLogPath "Running Test Suite [$TestSuiteName]"
            foreach($TestCase in $TestSuite.TestCase){
                $TestCaseName = $TestCase.Name
                LogMessage $PerfTestLogPath ((CheckCondition $TestCase.Condition))
                If($TestCase.IsRun -eq "False" -or (-not (CheckCondition $TestCase.Condition))){Continue}
				$global:currentTestcaseName = $TestCaseName
                LogMessage $PerfTestLogPath "....... Test Case  [$TestCaseName]"
                foreach($Action in $TestCase.Action){
                    $ActionName = $Action.Type
					$currentAction = $ActionName
					Add-Content -Path $TMPaction.FullName ("$currentTestcaseName,$currentAction")
                    LogMessage $PerfTestLogPath ((CheckCondition $Action.Condition))
                    If($Action.IsRun -eq "False" -or (-not (CheckCondition $Action.Condition))){Continue}
                    $Result = RunTestAction $Action
                    LogMessage $PerfTestLogPath "....... Action Run [$ActionName] - $Result"                 
                }
            }
        }
        Return $True  
    }
    Catch{ 
        $ErrorMessage = "["+$_.InvocationInfo.ScriptLineNumber+"] "+$_.Exception.Message+" "+$_.InvocationInfo.PositionMessage
        $ItemName = $MyInvocation.MyCommand.Name.PadRight(25)
        LogMessage $PerfTestErrLogPath "[$ItemName] - $ErrorMessage"  
        Return $False  
    }
}

#########################################################################################################

Function RunPerfTest(){
    Try{
        #$Global:Time = (get-date).ToString("_MMddyyyy_hhmmss")
        $Global:Time = get-date -f 'yyyyMMdd_hhmm'
        $Global:PerfTestConfigPath = "$PerfTestPath\$PerfTestConfigName"
        If(-Not (Test-Path $PerfTestConfigPath)){Return}
        $Global:PerfTestErrLogPath = "$PerfTestPath\Reports\$PerfTestErrLogName"
        $Global:PerfTestLogPath    = "$PerfTestPath\Reports\$PerfTestLogName"+$Time+".log"
        If(-Not (Test-Path $PerfTestErrLogPath)){New-Item -ItemType file -Path $PerfTestErrLogPath}
        If(-Not (Test-Path $PerfTestLogPath   )){New-Item -ItemType file -Path $PerfTestLogPath   }
		$global:TMPaction = New-Item -ItemType file -Path ($env:TEMP+"\$(hostname)TEMP"+$time+".log")
        [xml]$Global:XMLData = Get-Content $PerfTestConfigPath
		Import-Module "$LocalDir\AutoItX\AutoItX.psd1"
	    LoadDynamicModules $XMLData.NDSPerformanceTest.ActionTypes    
		Load-PerfmonCounters $PerfTestConfigPath "System"
        Load-PerfmonCounters $PerfTestConfigPath "ICA"
        $GraphicMode = Get-DisplayMode -ParentNode $XMLData.NDSPerformanceTest
        #$GraphicMode = "H.264"
        write-host ("`n"+"$GraphicMode"+"`n"+"`n"+"`n")
		LogMessage $PerfTestLogPath ("....... Found display mode = " + $GraphicMode)
		Load-WMICounters -ConfigPath $PerfTestConfigPath -Sensor "FPS" -GraphicMode $GraphicMode     
		Load-WMICounters -ConfigPath $PerfTestConfigPath -Sensor "ICARTT" -GraphicMode "All"
        RunTestSuite $XMLData.NDSPerformanceTest
        CleanBackGroundJob
		#make func
		Get-EventSubscriber | Unregister-Event
        Return $True  
    }
    Catch{ 
        $ErrorMessage = "["+$_.InvocationInfo.ScriptLineNumber+"] "+$_.Exception.Message+" "+$_.InvocationInfo.PositionMessage
        $ItemName = $MyInvocation.MyCommand.Name.PadRight(25)
        LogMessage $PerfTestErrLogPath "[$ItemName] - $ErrorMessage"  
        Return $False  
    }
}

RunPerfTest