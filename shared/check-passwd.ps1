# Set-StrictMode -version 2.0
function Check-Passwd( [string] $p_psw, [int]$p_minlen, [int]$p_minAlfa, [int]$p_minNum, [int]$p_minChrs   ) {
  $Script:checkPasswdMsg = $null
  if ( $p_minlen -eq $null ) {
    $p_minlen = 8
  }
  if ( $p_minAlfa -eq $null ) {
    $p_minAlfa = 1
  }
  if ( $p_minNum -eq $null ) {
    $p_minNum = 1
  }
  if ( $p_minChrs -eq $null ) {
    $p_minChrs = 0
  }
  if ( $p_psw -eq $null -or $p_psw.Length -lt $p_minlen ) {
    return $false
  }
  $obj = $p_psw.ToCharArray() | Where-Object { $_ -match "[a-zA-Z]" } | Measure-Object
  $lett = $obj.Count
  $obj = $p_psw.ToCharArray() | Where-Object { $_ -match "[0-9]" } | Measure-Object
  $nums = $obj.Count
  $obj = $p_psw.ToCharArray() | Where-Object { $_ -match "[-+!#$*%&(),./:;?@^_=]" } | Measure-Object
  $chrs = $obj.Count
  if ( ( $p_psw.Length - $lett - $nums - $chrs ) -ne 0 ) {
    $Script:checkPasswdMsg = "Carattere non ammesso"
    return $false
  } 
  if ( $lett -lt $p_minAlfa ) {
    $Script:checkPasswdMsg = "Poche lettere"
    return $false
  } 
  if ( $nums -lt $p_minNum ) {
    $Script:checkPasswdMsg = "Pochi numeri"
    return $false
  } 
  if ( $chrs -lt $p_minChrs ) {
    $Script:checkPasswdMsg = "Pochi caratteri speciali"
    return $false
  } 
  # Write-Host ( "{3}`tLett:{0} Nums:{1} Char:{2}" -f $lett,$nums,$chrs,$p_psw )
  return $true
}

# if ( ! ( Check-Passwd "abc!esr898" )  ) { "errore: $script:checkPasswdMsg" }

