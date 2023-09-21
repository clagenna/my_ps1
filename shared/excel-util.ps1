$script:excelFile  = $null
$script:excelSheet = $null

function excel-open([String] $p_file, [string] $p_sheetName ) {
    $script:excelFile  = $p_file
    $script:excelSheet = $p_sheetName
    $script:objExcel = New-Object -ComObject Excel.Application
    $script:objExcel.Visible = $false
    $script:workbook = $script:objExcel.Workbooks.Open($p_file)
    $script:excelSheet = $script:workbook.Worksheets.Item($p_sheetName)
}

function excel-crea([String] $p_file, [string] $p_sheetName ) {
    $script:excelFile  = $p_file
    $script:excelSheet = $p_sheetName
    $script:objExcel = New-Object -ComObject Excel.Application
    $script:objExcel.Visible=$false
    $script:workbook = $script:objExcel.Workbooks.add()
    $script:excelSheet = $script:workbook.sheets | where { $_.name.indexOf("1") }
}

function excel-save() {
  $script:objExcel.ActiveWorkbook.SaveAs($script:excelFile)
}
function excel-close() {
   if ( $script:objExcel -ne $null ) {
     $script:objExcel.quit()
   }

   $script:objExcel = $null
   $script:workbook = $null
   $script:excelSheet = $null
}


function set-excel-cell( [int] $p_row, [int] $p_col, [string] $p_val ) {
  $script:excelSheet.Cells.Item($p_row, [int] $p_col).value() = $p_val
}

function excel-cell( [int] $p_row, [int] $p_col ) {
  return $script:excelSheet.Cells.Item($p_row, [int] $p_col).Text
}

function excel-sheet () {
  return $script:excelSheet
}


# excel-open $script:excelFile $script:excelSheet

# for ( $riga = 1 ; $riga -lt 5 ; $riga++ )  {
#  for ( $colo = 1 ; $colo -lt 5 ; $colo++ )  {
#    Write-Host ( excel-cell $riga $colo ) -NoNewline
#    Write-Host ( "; " ) -NoNewline
#  }
#  Write-Host "; " 
# }

# excel-close