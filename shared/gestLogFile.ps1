Set-StrictMode -Version 2.0
# lev=0 debug
# lev=1 info
# lev=2 warn
$script:debugLev=0
# ---------------------------------------------------------------
# gestione del logfile
$oggi  = Get-Date -Format "yyyy-MM-dd"
$Global:logDir  = "C:\WinApp\ps1log"
$Global:logFile = "{0}\logFile-accounts-{1}.log" -f $logDir, $oggi
# ---------------------------------------------------------------
# colori del output write-host
$script:logDebCol=[System.ConsoleColor] "Gray"
$script:logInfCol=[System.ConsoleColor] "white"
$script:logWarCol=[System.ConsoleColor] "yellow"
$script:logErrCol=[System.ConsoleColor] "red"
$script:logDebColB=$Host.PrivateData.VerboseBackgroundColor
$script:logInfColB=$Host.PrivateData.VerboseBackgroundColor
$script:logWarColB=$Host.PrivateData.VerboseBackgroundColor
$script:logErrColB=$Host.PrivateData.VerboseBackgroundColor
# ---------------------------------------------------------------

$inErrore = $false

function set-LogLevel ( [int] $p_lev ) {
  $script:debugLev=$p_lev
}

function get-LogLevel() {
  return $script:debugLev
}

function set-LogFile( [string] $p_pathLog, [string] $p_logName ) {
    foreach ( $fun in @( 'debMsg', 'logMsg', 'errMsg' ) ) {
      if ( Test-Path function:$fun ) {
        Remove-Item function:$fun
      }
    }

    $oggi  = Get-Date -Format "yyyy-MM-dd"
    $Global:logDir  = $p_pathLog
    if ( ! ( Test-Path $Global:logDir ) ) {
      New-Item $Global:logDir -ItemType Directory
    }
    $Global:logFile = "{0}\{1}-{2}.log" -f $Global:logDir, $p_logName, $oggi
}

function getLogDir() {
  return $Global:logDir 
  }

function getUserApp() {
  $l_usr = ${env:userapp}
  if ( $l_usr -ne $null -and $l_usr.length -gt 1 ) {
    $l_usr = " (${env:userapp})"
  } else {
    $l_usr = ""
  }			   
  return $l_usr
}

function log-debug ( [string] $p_msg ) {
  if ( $script:debugLev -gt 0 ) {
    # Write-Debug $p_msg
    return
  }
  $l_adesso = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
  $l_usr    = getUserApp
  $l_lmsg = "{0}{1} DEB {2}" -f $l_adesso, $l_usr, $p_msg
  Add-Content -Path $Global:logFile -Value $l_lmsg
  Write-Host $l_lmsg -ForegroundColor $script:logDebCol
}

function log-info ( [string] $p_msg ) {
  if ( $script:debugLev -gt 1 ) {
    return
    }
  $l_adesso = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
  $l_usr    = getUserApp
  $l_msg = "{0}{1} LOG {2}" -f $l_adesso, $l_usr, $p_msg
  Add-Content -Path $Global:logFile -Value $l_msg
  Write-Host $l_msg -ForegroundColor $script:logInfCol
}


function log-warn ( [string] $p_msg ) {
  if ( $script:debugLev -gt 2 ) {
    return
    }
  $l_adesso = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
  $l_usr    = getUserApp
  $l_msg = "{0}{1} WAR {2}" -f $l_adesso, $l_usr, $p_msg
  Add-Content -Path $Global:logFile -Value $l_msg
  Write-Host $l_msg -ForegroundColor $script:logWarCol
}


function log-err ( [string] $p_msg ) {
  $l_adesso = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
  $l_usr    = getUserApp
  $l_msg = "{0}{1} ERR {2}" -f $l_adesso, $l_usr, $p_msg
  Add-Content -Path $Global:logFile -Value $l_msg
  Write-Host $l_msg -ForegroundColor $script:logErrCol
}

function set-LogColor ( [int] $p_lev, $p_foreg, $p_backg ) {
  switch ( $p_lev ) {
    #  debug
    0 {  $script:logDebCol  = if ( $p_foreg -ne $null ) { $p_foreg } else { $script:logDebCol }
         $script:logDebColB = if ( $p_backg -ne $null ) { $p_backg } else { $script:logDebColB }
      }
    # info
    1 {  $script:logInfCol  = if ( $p_foreg -ne $null ) { $p_foreg } else { $script:logInfCol }
         $script:logInfColB = if ( $p_backg -ne $null ) { $p_backg } else { $script:logInfColB }
      }
    # warn
    2 {  $script:logWarCol  = if ( $p_foreg -ne $null ) { $p_foreg } else { $script:logWarCol }
         $script:logWarColB = if ( $p_backg -ne $null ) { $p_backg } else { $script:logWarColB }
      }
    # error
    3 {  $script:logErrCol  = if ( $p_foreg -ne $null ) { $p_foreg } else { $script:logErrCol }
         $script:logErrColB = if ( $p_backg -ne $null ) { $p_backg } else { $script:logErrColB }
      }
  }
}