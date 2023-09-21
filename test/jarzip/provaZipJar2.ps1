Add-Type -Assembly System.IO.Compression.FileSystem
$ErrorActionPreference = 'Stop'

$jarPath ='F:\java\bin\ps1\somejars\xmlworker-5.5.9.jar'
$autModN = 'Automatic-Module-Name'
$modName = 'xmlworker.module'
$autom = ("{0}: {1}" -f $autModN,$modName )
Try {
    $zip = [IO.Compression.ZipFile]::Open($jarPath, "Update")
    $entries = $zip.Entries.Where({$_.name -like 'MANIFEST.MF'})
    foreach ($entry in $entries) {
        $reader = [System.IO.StreamReader]::new($entry.Open())
        $contenuto = $reader.ReadToEnd()
        $reader.Dispose()
        $arr = $contenuto.Split("`n")
        $nu = 0
        $writer = [System.IO.StreamWriter]::new($entry.Open())
        $writer.BaseStream.SetLength(0)
        foreach ( $riga in $arr ) {
            if ( $nu++ -eq 2 ) {
                $writer.Write("{0}`n" -f $autom)
            }
            $writer.Write("{0}`n" -f $riga)
        }
        $writer.Dispose()
    }
} catch {
    Write-Warning $_.Exception.Message
} finally {
    if ( $zip ) {
        $zip.Dispose()
    }
}
