param ( [string] $p_motorePort, [string] $p_dbname, [string] $p_taboview, [boolean] $p_ChToVarch = $true )
# param ( [Parameter(Mandatory=$true)][string] $fileProp )

# Add-PSSnapin SqlServerCmdletSnapin100
# Add-PSSnapin SqlServerProviderSnapin100

Set-StrictMode -version 2.0
Set-Location (Split-Path $PSCommandPath)

$DebugPreference        = "continue"
$ErrorActionPreference  = "stop"
$WarningPreference      = "stop"


. ..\shared\askParam.ps1

#Import-Module crypDecrypt
. ..\shared\crypDecrypt.ps1

#$script:dbUser = convertFrom-cryptPassword $script:usr
#$script:dbPass = convertFrom-cryptPassword $script:psw
$script:dbUser = decrypt-password $script:usr
$script:dbPass = decrypt-Password $script:psw


if ( $p_motorePort -eq $null -or $p_motorePort.Length -le 2 ) {
  $p_motorePort = askParam "Motore SQL e port" $true $false
}
$Script:SQLHost  = $p_motorePort

if ( $p_dbname -eq $null -or $p_dbname.Length -le 2 ) {
  $p_dbname = askParam "Dammi il nome DataBase" $true $false
}
$script:dbName   = $p_dbname

if ( $p_taboview -eq $null -or $p_taboview.Length -le 2 ) {
  $p_taboview = askParam "Nome Tabella o View" $true $false
}
$Script:schemaNam = 'dbo'
$Script:tabOrView = $p_taboview
$arr = $Script:tabOrView.split('.')
if ( $arr.Count -gt 1 ) {
  $Script:schemaNam = $arr[0]
  $Script:tabOrView = $arr[1]
} 


if ( $p_ChToVarch -eq $null ) {
  $p_ChToVarch = askParam "Trasformo i char in varchar" $true $false
}
$script:ChToVarch = $p_ChToVarch

$sqlFile = "c:\temp\Cursor_{0}_{1}.sql" -f $script:dbName, $Script:tabOrView
if ( Test-Path ( $sqlFile ) ) {
  Write-Host "Esiste il file:$sqlFile" -ForegroundColor Yellow
  Write-Host "Lo Cancello !"
  Remove-Item $sqlFile
}

$script:qryPK = "SELECT  
        syscolumns.name AS colonna, 
        systypes.name AS tipo, 
        systypes.length AS LenTipo, 
        syscolumns.length AS lung, 
        syscolumns.colid, 
        sysindexes.name AS KeyName
  FROM  syscolumns 
   INNER JOIN sysindexkeys 
      ON syscolumns.id = sysindexkeys.id 
     AND syscolumns.colid = sysindexkeys.colid 
   INNER JOIN systypes 
      ON syscolumns.xtype = systypes.xtype 
   INNER JOIN sysobjects 
      ON syscolumns.id = sysobjects.id 
   INNER JOIN sysindexes 
      ON syscolumns.id = sysindexes.id
	WHERE 1=1
	  AND sysindexkeys.indid = 1 
	  AND sysindexes.indid = 1
	  AND systypes.xusertype < 256
	  and sysobjects.name = '{0}'
  ORDER BY sysobjects.name, syscolumns.colid"

$script:sqlCols = "SELECT syscolumns.name AS colonna, 
             systypes.name AS tipo, 
             systypes.length AS LenTipo, 
             syscolumns.length AS lung, 
             syscolumns.colid
       FROM  syscolumns 
       INNER JOIN systypes 
          ON syscolumns.xtype = systypes.xtype 
       INNER JOIN sysobjects 
          ON syscolumns.id = sysobjects.id
       WHERE systypes.xusertype < 256 
         AND sysobjects.name = '{0}'
ORDER BY  syscolumns.colid"

$script:sqlCols = "SELECT *
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE 1=1
    AND TABLE_SCHEMA=N'{0}'
    AND TABLE_NAME=N'{1}'"



function formatta-Colonna( $objCo , [string]$p_prefix = "@"  ) {
  $szRet = "`t{0}{1} `t{2}"
  $colnam = $objCo.colonna
  $tipo   = $objCo.tipo
  $szRet  = $szRet -f $p_prefix, $colnam, $tipo
  return $szRet
}

# INFORMATION_SCHEMA.COLUMNS
# --------------------------
# TABLE_CATALOG	TABLE_SCHEMA	TABLE_NAME          COLUMN_NAME	    ORDINAL_POSITION	COLUMN_DEFAULT	IS_NULLABLE	
# consfeder	    imp	            view_RichImpianto	idRichiestaImp	1	                NULL	        NO	        
# --------------------------
#DATA_TYPE	CHARACTER_MAXIMUM_LENGTH	CHARACTER_OCTET_LENGTH	NUMERIC_PRECISION	NUMERIC_PRECISION_RADIX	NUMERIC_SCALE	
#int	    NULL	                    NULL					10					10						0				
# --------------------------
#DATETIME_PRECISION	CHARACTER_SET_CATALOG	CHARACTER_SET_SCHEMA	CHARACTER_SET_NAME	COLLATION_CATALOG	COLLATION_SCHEMA	COLLATION_NAME	DOMAIN_CATALOG	DOMAIN_SCHEMA	DOMAIN_NAME
#NULL				NULL					NULL					NULL				NULL				NULL				NULL			NULL			NULL			NULL
# --------------------------
function crea-ObjColonna ( $row ) {
  $obj = New-Object psobject

  $tipo   = $row.DATA_TYPE
  if ( $tipo -eq "char" -and $script:ChToVarch ) {
    $tipo = "nvarchar"
  }
  $conLen = $false
  $lungCol = 0
  if ( $row.CHARACTER_MAXIMUM_LENGTH -isnot [DBNull] -and  $row.CHARACTER_MAXIMUM_LENGTH  -gt 1 ) {
    $tipo += "({0})" -f $row.CHARACTER_MAXIMUM_LENGTH  
    $lungCol = $row.CHARACTER_MAXIMUM_LENGTH
    $conLen = $true
  }
  Add-Member -InputObject $obj -MemberType NoteProperty -Name "colonna" -Value $row.COLUMN_NAME.ToLower()
  Add-Member -InputObject $obj -MemberType NoteProperty -Name "tipo"    -Value $tipo
  Add-Member -InputObject $obj -MemberType NoteProperty -Name "conLen"  -Value $conLen
  Add-Member -InputObject $obj -MemberType NoteProperty -Name "lung"    -Value $lungCol
  $pkey = $script:arrPKeys -contains $row.COLUMN_NAME.ToLower()
  Add-Member -InputObject $obj -MemberType NoteProperty -Name "isPkey"  -Value $pkey
  return $obj
}

$l_qry = $script:qryPK -f $Script:tabOrView
$Error.Clear()
$resSet = Invoke-Sqlcmd -Query $l_qry   `
                        -ServerInstance $Script:SQLHost  `
                        -Database $script:dbName  `
                        -Username $script:dbUser  `
                        -Password $script:dbPass `
                        -TrustServerCertificate
$script:primKey     = ""
$script:arrPKeys    = @()
foreach ( $row in $resSet ) {
  $script:primKey += formatta-Colonna $row  
  $script:arrPKeys += , $row.colonna
}

$script:arrKeys = @()
$script:arrColsObj = @()
$script:allCols = ""
$script:allColsVar = ""

$l_qry = $script:sqlCols -f $Script:schemaNam, $Script:tabOrView
$Error.Clear()
$resSet = Invoke-Sqlcmd -Query $l_qry   `
                            -ServerInstance $Script:SQLHost  `
                            -Database $script:dbName  `
                            -Username $script:dbUser  `
                            -Password $script:dbPass `
                            -TrustServerCertificate
$eleColsDeclare =""
if (  $resSet -eq $null -or $resSet.Count -lt 1 ) {
  Write-Host "La tab/view $p_taboview non esiste !" -ForegroundColor Cyan
  exit 1957
}

foreach ( $row in $resSet ) {
  if ( $eleColsDeclare.Length -gt 2 ) {
    $eleColsDeclare += "`n`t, "
    $script:allCols += "`n`t, "
    $script:allColsVar += "`n`t, "
  }
  $objColonna            = crea-ObjColonna $row 
  $script:arrColsObj    += , $objColonna
  $eleColsDeclare       += formatta-Colonna $objColonna
  if ( $script:ChToVarch -and  $objColonna.conLen ) {
    $script:allCols       += ( "RTRIM({0}) as {0}" -f  $objColonna.colonna )
  } else {
    $script:allCols       += $objColonna.colonna
  }
  
  $script:allColsVar    += "@{0}" -f $objColonna.colonna
}

# Write-Host "Primary: $script:primKey"
Write-Host "`ndeclare: $eleColsDeclare"
# Write-Host "`ncols : $script:allCols"
# Write-Host "`ncols Var: $script:allColsVar"

$script:arrColsObj | ft *

$riga = "USE {0}
GO

-- =============================================
-- Metti una descrizione qui
-- =============================================
SET NOCOUNT ON 

DECLARE " -f $script:dbName
$riga | Out-File $sqlFile -Append
"`t" + $eleColsDeclare | Out-File $sqlFile -Append

$riga = ( "

DECLARE curs_{1} CURSOR   READ_ONLY	FOR 
    SELECT 	
`t" + $script:allCols + "
         FROM {0}.{1}
         WHERE 1=1" ) -f $Script:schemaNam, $Script:tabOrView
$riga | Out-File $sqlFile -Append

$riga = "
OPEN curs_{0} " -f $Script:tabOrView
$riga | Out-File $sqlFile -Append

$riga =( "

FETCH NEXT FROM curs_{0} INTO 
`t" +  $script:allColsVar ) -f $Script:tabOrView
$riga | Out-File $sqlFile -Append
			
$riga = "
WHILE (@@fetch_status <> -1)
BEGIN
	IF (@@fetch_status <> -2)
	BEGIN
      --  Metti il codice cursore qui !
	  PRINT 'Rigo letto '
    END
"
$riga | Out-File $sqlFile -Append


$riga =( "

  FETCH NEXT FROM curs_{0} INTO 
`t" +  $script:allColsVar + "
END

CLOSE curs_{0}
DEALLOCATE curs_{0}

GO
") -f $Script:tabOrView
$riga | Out-File $sqlFile -Append
Write-Host "Scritto file: $sqlFile" -ForegroundColor Green
