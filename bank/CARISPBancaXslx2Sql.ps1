<#
.SYNOPSIS
Legge files CSV e/o Excel e inserisce i records nel DB	 C A R I S P

.DESCRIPTION
Il formato del file da leggere è l'estratto che fornisce Welly con :
"DATA", "VALUTA", "DARE", "AVERE", "CAUSALE", "CAUSABI"
del tipo:
sep=;
DATA; VALUTA; DARE; AVERE; CAUSALE; CAUSALE ABI;
03/01/2022 ; 30/12/2021 ; 1,00 ;   ; PAGAMENTO TRAMITE POS Il 30/12/21 Ore 11:44 PARCHEGGIO 7 Nr.PAN: 060000084806 ; 43 ; 
03/01/2022 ; 02/01/2022 ; 13,56 ;   ; PAGAMENTO TRAMITE POS Il 02/01/22 Ore 07:14 METANGAS Nr.PAN: 060000084806 ; 43 ; 
03/01/2022 ; 02/01/2022 ; 73,62 ;   ; PAGAMENTO TRAMITE POS Il 02/01/22 Ore 13:36 STAZIONE DI SERVIZIO Q Nr.PAN: 060000084806 ; 43 ; 

#>


Add-Type -AssemblyName System.Windows.Forms
Set-StrictMode -Version 3.0
function get-fileMovimenti() {
    
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $initialDirectory = Split-Path $PSCommandPath
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "Excel files (*.xlsx)| *.xlsx|Comma sep(*.csv)|*.csv"
    $OpenFileDialog.ShowDialog() |  Out-Null

    return $OpenFileDialog.filename
}
function convertFrom-String2dt([string]$sz) {
    [datetime]$dtInn = $minDate
    if (!$sz -or $sz.Length -lt 5) {
        return $dtInn
    }
    try {
        $dtInn = [datetime]::ParseExact($sz, 'dd/MM/yyyy', $null)
    } catch {
        # $dtInn = $minDate
    }
    try {
        if ( $dtInn.CompareTo($minDate) -eq 0 ) {
            $dtInn = [datetime]::ParseExact($sz, 'd/MM/yyyy', $null)
        }
    } catch {
        # $dtInn = $minDate
    }
    try {
        if ( $dtInn.CompareTo($minDate) -eq 0 ) {
            $dtInn = [datetime]::ParseExact($sz, 'd/M/yyyy', $null)
        }
    } catch {
        # $dtInn = $minDate
    }

    # write-host ("getType={0}" -f $dtInn.getType() )
    return $dtInn
}

# ------------------------------------
# settaggi iniziali
$currPath = (Split-Path $PSCommandPath)
Set-Location $currPath
# Write-Host ("Current path:{0}" -f $currPath)
if ( $args.Count -gt 0 ) {
    $filNam = $args[0]
} else {
    $filNam = get-fileMovimenti
}
if ( ! $filNam ) {
  $filNam = "F:\Google Drive\gennari\banca CARISP\estrattoconto_2301-2306.xlsx"
}
$pth = Resolve-Path $filNam
$filNam = $pth
Write-Host ("Analizzo il file: {0}" -f $filNam)

$minDate = [datetime]::ParseExact('02/01/1753', 'dd/MM/yyyy', $null)
$Motore = "localhost, 1433"
$userna = "sqlgianni"
$psw = "sicuelserver"
$nomeDB = "Banca"
$nomeTab = "movimentiCarisp"

$rowDt, $colDt = 2, 1
$rowVl, $colVl = 2, 2
$rowDa, $colDa = 2, 3
$rowAv, $colAv = 2, 4
$rowDs, $colDs = 2, 5
$rowCa, $colCa = 2, 6


class Movimento {
    [datetime]  $dtmov
    [datetime]  $dtval
    [double]    $dare
    [double]    $avere
    [string]    $descr
    [string]    $caus

    [string]ToString() {
        $sz1 = $this.dtmov.ToString( "dd/MM/yyyy")
        $sz2 = $this.dtval.ToString( "dd/MM/yyyy")
        return "$($sz1)`t$($sz2)`t$($this.dare)`t$($this.avere)`t$($this.descr)`t$($this.caus)"
    }
}

$ext = (Split-Path -Path $filNam -Leaf).Split(".")[1].ToLower() 
Write-Host ("esten:{0}" -f $ext)
$arrMovs = New-Object System.Collections.ArrayList

# ---------------------------------------------------------------------------------
function read-MovToDB {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true )]
        [Movimento] $mov
    )
    
    begin {
        Write-Host ("Inserimento in DB")
        $qtaIns = 0
        # -------------------------------------
        #  Inserimento nel DB dei valori
        # ------------------------------------
        # SQL statement for insert

        [Data.SqlClient.SqlConnection] $conn = New-Object System.Data.SqlClient.SqlConnection

        $conn.ConnectionString = "Server=$Motore;Database=$nomeDB;User Id=$userna;Password=$psw;"
        $conn.Open()

        if ($conn.State -ne [Data.ConnectionState]::Open) {
            Write-Host "No Connect to DB $DBName" -ForegroundColor DarkRed
            Exit
        }


        $sqlQuery = New-Object System.Data.SqlClient.SqlCommand
        $sqlQuery.connection = $conn
        $qryCount = "SELECT count(*)
                        FROM dbo.{0}
                        WHERE dtmov=@dtMov
                          and dtval=@dtVal
                          and dare=@dare
                          and avere=@avere
                          and descr=@descr
                          and abicaus=@abicaus
        " -f $nomeTab
        $sqlQuery.CommandText = $qryCount


        $sqlQuery.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@dtmov", [Data.SQLDBType]::DateTime))) | Out-Null
        $sqlQuery.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@dtval", [Data.SQLDBType]::DateTime))) | Out-Null
        $sqlQuery.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@dare", [Data.SQLDBType]::Money))) | Out-Null
        $sqlQuery.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@avere", [Data.SQLDBType]::Money))) | Out-Null
        $sqlQuery.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@descr", [Data.SQLDBType]::NChar))) | Out-Null
        $sqlQuery.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@abicaus", [Data.SQLDBType]::NChar))) | Out-Null

        # --------------------------------------------------------
        $sqlCommand = New-Object System.Data.SqlClient.SqlCommand
        $sqlCommand.Connection = $conn

        $qryUpd = "INSERT INTO dbo.{0}
            (dtmov
            ,dtval
            ,dare
            ,avere
            ,descr
            ,abicaus)
      VALUES
            (@dtmov
            ,@dtval
            ,@dare
            ,@avere
            ,@descr
            ,@abicaus )
  " -f $nomeTab
        $sqlCommand.CommandText = $qryUpd

        $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@dtmov", [Data.SQLDBType]::DateTime))) | Out-Null
        $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@dtval", [Data.SQLDBType]::DateTime))) | Out-Null
        $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@dare", [Data.SQLDBType]::Money))) | Out-Null
        $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@avere", [Data.SQLDBType]::Money))) | Out-Null
        $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@descr", [Data.SQLDBType]::NChar))) | Out-Null
        $sqlCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@abicaus", [Data.SQLDBType]::NChar))) | Out-Null
    }
    
    process {
        $ret = 0
        $q = 0
        $sqlQuery.Parameters[$q++].Value = $mov.dtmov
        $sqlQuery.Parameters[$q++].Value = $mov.dtval
        $sqlQuery.Parameters[$q++].Value = $mov.dare
        $sqlQuery.Parameters[$q++].Value = $mov.avere
        $sqlQuery.Parameters[$q++].Value = $mov.descr
        $sqlQuery.Parameters[$q++].Value = $mov.caus
        try {
            $ret = $sqlQuery.ExecuteScalar()
            # Write-Host $ret
        }
        catch {
            Write-Host ( "Errore in select! msg={0}" -f $_.ToString() )
        }
        # se non ho il record da inserire lo inserisco
        if ( $ret -eq 0) {
            $q = 0
            $sqlCommand.Parameters[$q++].Value = $mov.dtmov
            $sqlCommand.Parameters[$q++].Value = $mov.dtval
            $sqlCommand.Parameters[$q++].Value = $mov.dare
            $sqlCommand.Parameters[$q++].Value = $mov.avere
            $sqlCommand.Parameters[$q++].Value = $mov.descr
            $sqlCommand.Parameters[$q++].Value = $mov.caus
            try {
                $sqlCommand.ExecuteScalar()
                $qtaIns++
            }
            catch {
                Write-Host ( "Errore in insert! msg={0}" -f $_.ToString() )
            }
        } else {
            Write-Host ("Esiste gia: {0}" -f $mov.ToString() )
        }
    }
    
    end {
        Write-Host ( "End ! qta Ins = {0} su {1} recs" -f $qtaIns, $arrMovs.Count)        
        if ($conn.State -eq [Data.ConnectionState]::Open) {
            $conn.Close()
        }

    }
}
# --------------------------------------------------------------------------------
function read-csv {
    param (
        [string]$filn
    )
    $fiCsv = Import-Csv -Path $filn -Header "DATA", "VALUTA", "DARE", "AVERE", "CAUSALE", "CAUSABI" -Delimiter ";"
    [nullable[datetime]]$dtCsv = $null
    foreach ( $r in $fiCsv ) {
        $dtCsv = $null
        if ( $r.DATA ) {
            $sz = $r.DATA.Trim()
            $dtCsv = convertFrom-String2dt $sz
            if ( $dtCsv -and $dtCsv.CompareTo($Global:minDate) -gt 0 ) {
                [Movimento]$mov = New-Object -TypeName Movimento

                # Write-Host ( "Letto: {0},{1},{2},{3},{4},{5}" -f $r.DATA,  $r.VALUTA,  $r.DARE,  $r.AVERE,  $r.CAUSALE,  $r.CAUSABI)
                $sz = $r.DATA ? $r.DATA.trim() : $null
                $mov.dtmov = $sz ? [datetime]::ParseExact($sz, 'dd/MM/yyyy', $null) : 0

                $sz = $r.VALUTA ? $r.VALUTA.trim() : $null
                $mov.dtval = $sz ? [datetime]::ParseExact($sz, 'dd/MM/yyyy', $null) : 0
        
                $sz = $r.DARE ? $r.DARE.trim() : $null
                $mov.dare = $sz ? [double]::Parse($sz) : 0;
        
                $sz = $r.AVERE ? $r.AVERE.trim() : $null
                $mov.avere = $sz ? [double]::Parse($sz) : 0;
        
                $mov.descr = $r.CAUSALE.trim()
        
                $sz = $r.CAUSABI ? $r.CAUSABI.trim() : $null
                $mov.caus = $sz -and $sz.Length -gt 0 ? $sz : ""   # $sz -and $sz.Length -gt 0 ? [convert]::ToInt32($sz) : 0
        
                if ( $mov.dtval -gt $Global:minDate ) {
                    $arrMovs.add($mov) | Out-Null
                }
            }
        }
    }  
}
# -----------------------------------------------------------------------------

function read-excel() {
    param (
        [string]$filn
    )
    begin {
        # ------------------------------------
        # lettura delle qta dei candidati da EXCEL
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false

        $workbook = $excel.Workbooks.Open($filn)
        $sheet = $workbook.Worksheets.Item(1)

        $rowMax = ($sheet.UsedRange.Rows).count
        $rigaCurr = $rowDt
        $maxListe = 0
    }
    process {
        [nullable[datetime]]$dt = $null
        for ($i = 0; $rigaCurr -le $rowMax ; $i++) {
            $rigaCurr = $rowDt + $i
            [Movimento]$mov = New-Object -TypeName Movimento

            $sz = ($sheet.Cells.Item($rigaCurr, $colDt).text).trim()
            $dt = convertFrom-String2dt($sz) 
            # $obj = convertFrom-String2dt($sz) 
            # if ( $obj -is [array]) {
            #     $dt = $obj[1] 
            # }
            # else {
            #     $dt = $obj
            # }
            try {
              $mov.dtmov = $dt
            } catch {
                Write-Host "Errore dtMov"
            }

            $sz = ($sheet.Cells.Item($rigaCurr, $colVl).text).trim()
            $dt = convertFrom-String2dt $sz
            # $obj = convertFrom-String2dt($sz) 
            # if ( $obj -is [array]) {
            #     $dt = $obj[1] 
            # }
            # else {
            #     $dt = $obj
            # }
            $mov.dtval = $dt

            $sz = ($sheet.Cells.Item($rigaCurr, $colDa).text).trim()
            $mov.dare = $sz.Length -gt 0 ?  [double]::Parse($sz) : 0;

            $sz = ($sheet.Cells.Item($rigaCurr, $colAv).text).trim()
            $mov.avere = $sz.Length -gt 0 ?  [double]::Parse($sz) : 0;

            $mov.descr = ($sheet.Cells.Item($rigaCurr, $colDs).text).trim()

            $sz = ($sheet.Cells.Item($rigaCurr, $colCa).text).trim()
            $mov.caus = $sz.Length -gt 0 ? [convert]::ToInt32($sz) : 0

            if ( $mov.dtval -gt $minDate ) {
                $arrMovs.add($mov) | Out-Null
            }
        }
    }
    end {
        $maxListe = $arrMovs.Count
        $workbook.close($false)
        $excel.quit()
        Write-Host (" Chiuso Excel:elenco {0}" -f $maxListe )
    }
}
# -----------------------------------------------------------------------------
if ( $ext.CompareTo("csv") -eq 0) {
    read-csv $filNam
}
elseif ( $ext.CompareTo("xlsx") -eq 0 ) {
    read-excel $filNam
}
$arrMovs | read-MovToDB 

