:: =========================================================================================================
:: Name:			Run_NDSPerfTest
:: Description:		Launcher script
:: $Author: weeger $ 
:: $Date: 2016-02-26 17:24:30 +0800 (Fri, 26 Feb 2016) $
:: $Rev: 39182 $
:: $Header: $
:: History: 		Initial version
:: =========================================================================================================

PATH C:\Windows\Sysnative\WindowsPowerShell\v1.0;C:\Windows\System32\WindowsPowerShell\v1.0

Powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Unrestricted -Command "& {z:\NDS_RegressionTesting\TestCaseWizard.ps1}"

Powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Unrestricted -Command "& {z:\NDS_RegressionTesting\NDSPerfTest.ps1}"

EXIT %ERRORLEVEL%