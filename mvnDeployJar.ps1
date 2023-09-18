param ( [switch]$debug )
Set-StrictMode -version 2.0

# $debug=$false

$DebugPreference = "continue"
$ErrorActionPreference = "stop"
$WarningPreference = "stop"
# -----------------------------------------
# import delle funzioni per il logging
Set-Location (Split-Path $PSCommandPath)
. ..\shared\askParam.ps1
$script:fileProp = "mvnDeployJar.properties"
$script:strtDirRepo = "F:\java\maven\repository"

#----------------------------------------------------------------------------------------
Function Get-Folder($initialDirectory="")
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $folder = $null
    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Scegli un direttorio"
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}
#----------------------------------------------------------------------------------------
Function leggi-LastRepo() {
  if ( ! ( Test-Path $script:fileProp ) ) {
    return
  }
  $script:props = ConvertFrom-StringData (Get-Content $script:fileProp -raw)
  if ( $script:props -eq $null ) {
    return
  } 
  $a = $script:props["lastRepoDir"]
  if ( $a -eq $null -or $a.Length -lt 3 ) {
    return
  }
  $script:strtDirRepo = $a
}
#----------------------------------------------------------------------------------------
Function salva-LastRepo() {
  $str = "lastRepoDir={0}" -f $script:strtDirRepo 
  $str = $str -replace '\\',"\\"
  $str | Set-Content $script:fileProp 
}
#----------------------------------------------------------------------------------------

$res = $env:MAVEN_HOME
if ( $res -eq $null -or $res.length -le 3 ) {
  Write-Host "Non ha definito la ENV var MAVEN_HOME !"
  exit 1957
}

leggi-LastRepo

$script:strtDirRepo = Get-Folder $script:strtDirRepo
if ( $script:strtDirRepo -eq $null ) {
  exit 1957
}
# Write-Output $script:strtDirRepo
$arr = Get-ChildItem -Path $script:strtDirRepo -Recurse | where-Object { 
  if (  $_.PSIsContainer ) { return }
  $ext = $_.Extension.ToLower()
  switch ( $ext ) {
    ".pom" { $_ }
    ".jar" { $_ }
  }
} | Select-Object Name,extension,CreationTime,Length,FullName | Out-GridView -PassThru -Title "Scegli i componenti del bundle"

if ( $arr -eq $null ) {
  Write-Host "Non hai scelto alcun chè!" -ForegroundColor Yellow
  exit 1957
}
salva-LastRepo
$pomfi = $null
$jarfi = $null
$srcfi = $null
$arti  = $null
$grou  = $null
$vers  = $null
$plug  = $false
$snap  = $false
$soloPOM = $false
$locFI = $null

ForEach ( $fi in $arr ) {
  switch ( $fi.extension ) {
    ".pom" { $pomfi = $fi.fullName 
             $locFI = $fi.fullName 
           }
    ".jar" { 
      $locFI = $fi.fullName 
      if ( $fi.fullName -match "-source" ) {
        $srcfi = $fi.fullName
      } else {
        $jarfi = $fi.fullName
      }
     }
  }
}

$snap = $locFI.toLower() -match "snapshot"
$plug = $locFI.toLower() -match "plugin"


$numero = 1
if ( $plug ) { $numero = 3 }
if ( $snap ) { $numero++ }
# $mapUrl = "http://mavenrepo:8081/nexus/content/repositories/{0}"
# http://192.168.1.106:8081/artifactory/libs-release-local/
# http://192.168.1.106:8081/artifactory/libs-snapshot-local/
# http://192.168.1.106:8081/artifactory/plugins-release-local/
# http://192.168.1.106:8081/artifactory/plugins-snapshot-local/
$mapUrl = "http://mavenrepo:8081/artifactory/{0}"

switch ( $numero ) {
  1 { $repoid = "libs-release-local"
      $locRep = "releases"
   }
  2 { $repoid = "libs-snapshot-local"
      $locRep = "snapshots"
   }
  3 { $repoid = "plugins-release-local"
      $locRep = "plugins-release"
   }
  4 { $repoid = "plugins-snapshot-local"
      $locRep = "plugins-snapshot"
   }
}

if ( $pomfi -eq $null ) {
  $arti = askParam "Artifact ID" $true $false
  $grou = askParam "Group ID" $true $false
  $vers = askParam "Versione" $true $false
}

Write-Output "Pom= $pomfi"
Write-Output "Jar= $jarfi"
Write-Output "Src= $srcfi"
Write-Output "snap $snap"
Write-Output "repo Id $repoid"
Write-Output "    Url $locRep"

$repoUrl = $mapUrl -f $repoid

#######   Trasmetto i  JAR package  #######################################
$parm = @()

$parm += "/k","call"
$parm += "`"{0}\bin\mvn.cmd`"" -f $env:MAVEN_HOME
if ( $debug ) { $parm += "-e" }
$parm += "install:install-file"
$parm += "deploy:deploy-file"
$parm += " -DrepositoryId={0}" -f $repoid
if ( $jarfi -eq $null ) {
  $soloPOM = $true
  if ( $pomfi -eq $null ) {
    Write-Host "Non ho ne il POM ne il JAR !!"
    exit 1957
  }
  $parm += " -Dfile=`"{0}`"" -f $pomfi
} else {
  $parm += " -Dfile=`"{0}`"" -f $jarfi
}
if ( $srcfi -ne $null ) {
  $parm += " -Dsources=`"{0}`"" -f $srcfi
}
if ( $soloPOM ) {
  $parm += " -Dpackaging=pom"
} else {
  $parm += " -Dpackaging=jar"
}
$parm += " -Durl=`"{0}`"" -f $repoUrl
if ( $pomfi -eq $null ) {
  $parm += " -DgroupId=$grou"
  $parm += " -DartifactId=$arti"
  $parm += " -Dversion=$vers"

  $parm += " -DgeneratePom=true"
} else {
  $parm += " -DpomFile=`"{0}`"" -f $pomfi
}
Write-Debug ( $parm -join " " )
Start-Process -FilePath "C:\Windows\System32\cmd.exe" -ArgumentList $parm

