Add-Type -Assembly System.IO.Compression.FileSystem

$jarPath ='F:\java\bin\ps1\somejars\xmlworker-5.5.9.jar'
$manifOut = "F:\temp\scan\manif.txt"
$manifOut2 = "F:\temp\scan\manif2.txt"
$autModN = 'Automatic-Module-Name'
$modName = 'xmlworker.module'

$zipFile = [IO.Compression.ZipFile]::OpenRead($jarPath)

$zipFile.Entries | Where-Object { $_.Name -like 'MANIFEST.MF'}  |  ForEach-Object {
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $manifOut, $true)
}
$trov = $null
Select-String -Pattern $autModN -Path $manifOut | foreach {
    $trov = $_
}
Write-Host ("Trovai:" + $trov)
if ( $null -ne $trov ) {
    write-host ("Contiene gia:" + $autModN )
}
$sz = ("{0}: {1}" -f $autModN,$modName )
$nu = 0
foreach ( $riga in Get-Content -Path $manifOut ) {
    if ( $nu++ -eq 2 ) {
        Add-Content -Path $manifOut2 -Value $sz
    }
    Add-Content -Path $manifOut2 -Value $riga
}
Write-Host ("Aggiunto:" + $sz)
