
# ------------------------------------------------------
# routine di richesta parametri
# 
function askParam([string] $pMsg, [boolean] $pIsObbl, [boolean] $pIsPaswd) {
  $rtry=0
  while ( $rtry -lt 2 ) {
    $rtry++
    $script:inErrore = $false
    if ( $pIsPaswd ) {
      $pass = Read-Host 'Dammi la password?' -AsSecureString
      $val = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
    } else {
      $val = Read-Host $pMsg
    }
    if ( ! $pIsObbl ) {
      break
    } 
    if ( $val.Length -ge 1 ) {
      $rtry = 9999
    }  else {
      $script:inErrore = $true
      Write-Host "Il campo è obbligatorio" -ForegroundColor Red
    }
  }
  if ( $inErrore ) {
      errMsg "Non ho un parametro indispensabile per:$pMsg . Chiudo!" 
      exit
      }
  return $val
}