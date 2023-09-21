clear
if ( Test-Path Variable:\vvNuovaVar ) { Remove-Item Variable:\vvNuovaVar }
if ( Test-Path Variable:\vvScriptScope ) { Remove-Item Variable:\vvScriptScope }

$vvInizio = "l'ho messa prima"
Write-Host "Prima della funzione" -ForegroundColor Yellow
Get-ChildItem variable:vv*



function chiamata() 
{
  $vvChiamata = "in chiamata"
  $vvInizio = "modificata in funzione"
  Set-Variable -name vvScriptScope -Scope "script" -Value 123456
  Write-Host "Nella funzione" -ForegroundColor Yellow
  Get-ChildItem variable:vv*
}



function chiamata2() 
{
  $vvChiamata = "in chiamata2"
  $script:vvInizio = "modificata in Chiamata2"
  New-Variable -name vvNuovaVar -Value 1234 -Description "la variabile che mi serve" -Option AllScope
  Write-Host "Nella funzioneChiamata2" -ForegroundColor Yellow
  Get-ChildItem variable:vv*
}

chiamata
chiamata2

$vvDopo="l'ho messa dopo"
Write-Host "Dopo della funzione" -ForegroundColor Yellow
Get-ChildItem variable:vv*
