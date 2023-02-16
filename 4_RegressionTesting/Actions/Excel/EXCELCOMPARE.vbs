wscript.echo time
sExcelSheet1 = "tax_det_new"
sExcelSheet2 =  "tax_det_orig"

    Set objExcel = CreateObject("Excel.Application")
   objExcel.Visible = True

Set objWorkbook1= objExcel.Workbooks.Open("c:\temp\perftest\" & sExcelSheet1 &".xls")
Set objWorkbook2= objExcel.Workbooks.Open("c:\temp\perftest\" & sExcelSheet2 &".xls")


Set objWorksheet1= objWorkbook1.Worksheets(1).UsedRange

Set objWorksheet2= objWorkbook2.Worksheets(1).UsedRange
 
   For Each cell In objWorksheet1.Cells
	   intRowIndex = Cell.Row
       intColumnIndex = Cell.Column
		 
       If cell.Value <> objWorksheet2.Cells(intRowIndex, intColumnIndex).Value Then
		 Flag = 1
		 cell.Font.Color = vbRed
             objWorksheet2.Cells(intRowIndex, intColumnIndex).Font.Color = vbRed
        Else
		   cell.Font.Color = vbBLUE
               objWorksheet2.Cells(intRowIndex, intColumnIndex).Font.Color = vbBLUE

           End If
   Next


objExcel.DisplayAlerts = False

objWorkbook1.Close
objWorkbook2.Close


wscript.echo time


strComputer = "."
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set colProcessList = objWMIService.ExecQuery _
    ("Select * from Win32_Process Where Name = 'Excel.exe'")
For Each objProcess in colProcessList
    objProcess.Terminate()
Next