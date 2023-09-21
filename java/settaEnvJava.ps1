Add-Type -AssemblyName PresentationFramework
# XRequiresX RunAsAdministrator
$java='C:\Program Files\java\jdk-17.0.5'
$javaFx = 'C:\Program Files\javafx-sdk-17.0.1'
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )
if ( ! ($currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )) ) {
  $a = [System.Windows.MessageBox]::Show("Non sei Administrator!`nDevi lanciare con privilegi elevati" )
  exit
}
#------------------------------------------------------
# verifica se esistono i path in quei direttori

$test = "{0}\bin\{1}" -f $java,'java.exe'
if ( ! ( Test-Path -Path $test )) {
  $a = [System.Windows.MessageBox]::Show("Non trovo java.exe in `"{0}`"" -f $java)
  exit
}
$test = "{0}\lib\{1}" -f $javafx,'javafx.base.jar'
if ( ! ( Test-Path -Path $test )) {
  $a = [System.Windows.MessageBox]::Show( ("Non trovo javafx in `"{0}`"`n{1}" -f $javafx,$test))
  exit
}


#------------------------------------------------------
# posso settare 
[System.Environment]::SetEnvironmentVariable('JAVA_HOME',  $java,   [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('JRE_HOME',   $java,   [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('JAVAFX_HOME',$javaFx, [System.EnvironmentVariableTarget]::Machine)

