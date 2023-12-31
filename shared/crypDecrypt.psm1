# 76492d1116743f0423413b16050a5345MgB8AFcAawB6AGYASwB2AGMAbAB2ADIAcAAxAGEAZABSAGIAZgBZAGsAYgB0AHcAPQA9AHwAZQAwAGQAMQAzADkANQA3AGIAYwA5ADUAYwAzADYAMgBmADAAZgAxADQAOAA1ADcAMwA2AGYANAA4ADIAMABlADIANwA2AGEAZgBhADYAZQAwADgAMgA1ADkAYwBjAGIAOQBmADkAOAA4ADYAMQBlADAANwA5AGIAMQBiADEAOAA=
# Set-StrictMode -Version 2.0

<#
.SYNOPSIS
Converte la password da plain text a secure-string

.DESCRIPTION
Converte la password da plain text a secure-string in formato esadecimale

.PARAMETER p_pswd
Mandatory. la password da convertire

#>
function convertTo-cryptPassword( [string] $p_pswd ) {
  return ConvertTo-SecureString -string $p_pswd -AsPlainText -Force | ConvertFrom-SecureString -key (1..16)
  # return ConvertTo-SecureString -string $p_pswd -Key (1..16) -asplaintext -force | convertfrom-securestring
}


<#
.SYNOPSIS
Converte la password in formato esadecimale a plain text

.DESCRIPTION
Converte la password da formato esadecimale a plain text 

.PARAMETER p_encr
Mandatory. la password in formato stringa esadecimale da decrittare
#>
function convertFrom-cryptPassword( [string] $p_encr ) {
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

Export-ModuleMember convertTo-cryptPassword, convertFrom-cryptPassword

