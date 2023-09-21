#Requires -RunAsAdministrator
Param(
    [Parameter(Mandatory=$true)]  [String]$modName,
    [Parameter(Mandatory=$true)]  [String]$versione
)
# $modName = "sqlUtil"
# $versione = "1.0"


$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() ) 
if ( ! $currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator ) ) { 
   clear-host 
   write-host "Warning: Devi lanciare PowerShell come Administrator.`n" -ForegroundColor Red
   exit
}
Set-Location (Split-Path $PSCommandPath)
$modFile = "{0}\{1}.psm1" -f (Split-Path $PSCommandPath), $modName
if ( ! ( Test-Path $modFile ) ) {
  Write-Warning "Non trovo il file $modFile da installare"
  exit 1957
}

$modBase = "C:\Program Files\WindowsPowerShell\Modules"
$modPath = "{0}\{1}\{2}" -f $modBase,$modName,$versione
$fulPath = "{0}\{1}\{2}\{1}.psm1" -f $modBase,$modName,$versione
$psdPath = "{0}\{1}\{2}\{1}.psd1" -f $modBase,$modName,$versione
$guid    = ( New-Guid ).Guid
if ( ! ( Test-Path $modPath ) ) {
  Write-Information "Creo il direttorio $modPath"
  New-Item -ItemType Directory -Path $modPath -Force
}
try {
  Copy-Item -Path $modFile -Destination $fulPath -Force
} Catch {
  $msg = $_.exception
  Write-Warning $msg
  exit 1957
}
Set-Location $modPath
# Import-Module $fulPath -Force
# $a = (Get-Module $modName -ListAvailable ).ExportedCommands.Values -split "," | sort -Unique

$script:arr = @()
Get-Content -Path $fulPath |
    ForEach-Object {
      if ( $_ -match ".*function +(?<nome>[a-zA-Z][a-zA-Z0-9\-_]+)" ) {
        $fun = $Matches.nome
        Write-Host $fun -ForegroundColor Yellow
        if ( $script:arr -notcontains $fun ) {
          $script:arr += ,$fun        
        }
      }
    }
# $script:arr

$paramHash = @{
 Path = $psdPath
 RootModule = ( "{0}.psm1" -f $modName )
 Author = "Claudio Gennari"
 CompanyName = "CisCOOP"
 ModuleVersion = "1.0"
 Guid = $guid
 PowerShellVersion = "3.0"
 Description = "My $modName module"
 FormatsToProcess = ""
 FunctionsToExport = $script:arr
 AliasesToExport = ""
 VariablesToExport = ""
 CmdletsToExport = $script:arr
}
New-ModuleManifest @paramHash

