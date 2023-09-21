#76492d1116743f0423413b16050a5345MgB8AFcAawB6AGYASwB2AGMAbAB2ADIAcAAxAGEAZABSAGIAZgBZAGsAYgB0AHcAPQA9AHwAZQAwAGQAMQAzADkANQA3AGIAYwA5ADUAYwAzADYAMgBmADAAZgAxADQAOAA1ADcAMwA2AGYANAA4ADIAMABlADIANwA2AGEAZgBhADYAZQAwADgAMgA1ADkAYwBjAGIAOQBmADkAOAA4ADYAMQBlADAANwA5AGIAMQBiADEAOAA=
Set-StrictMode -Version 2.0

function encrypt-password( [string] $p_pswd ) {
  return ConvertTo-SecureString -string $p_pswd -AsPlainText -Force | ConvertFrom-SecureString -key (1..16)
  # return ConvertTo-SecureString -string $p_pswd -Key (1..16) -asplaintext -force | convertfrom-securestring
}

function decrypt-password( [string] $p_encr ) {
  $local:secstr = ConvertTo-SecureString  -Key (1..16) -String $p_encr
  $local:bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secstr)
  $local:pswd2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
  return $local:pswd2
}


#foreach ( $psw in @("Pasw04d01#", "Tae!Qual3") ) {
#  $cry = encrypt-password $psw
#  $psw2 = decrypt-password $cry
#  Write-Host ( "{0}={1} `t{2}`t{3}" -f $psw,$psw2,( $psw.Equals( $psw2 ) ), $cry ) 
#}