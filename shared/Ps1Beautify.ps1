 param (  [Parameter(mandatory=$true)][string]$ps1path )
 $szoggi =(get-date).ToString("yyyy-MM-dd_HH-mm")
 if ( ! ( Test-Path $ps1path ) ){
   Write-Host ("Non trovo {0}, Esco!" -f $ps1path) -ForegroundColor Yellow
   exit 1957
 }
 $szBakPath = "{0}_{1}.ps1" -f ($ps1path -ireplace ".ps1",""), $szoggi
 Copy-Item -Path $ps1path -Destination $szBakPath -Force 
  
 Edit-DTWBeautifyScript -SourcePath $szBakPath `
                        -DestinationPath $ps1path
                       
    
    