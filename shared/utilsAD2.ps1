
#-----------------------------------------------
# precarico le OU da AD nel $script:mapAllOUs --> shortName_0
# gli omonimi hanno shortName_n++
$script:scartaOUs = 'users', 'domaincontrollers', 'builtin', 'computers', 
                    'system', 'managedserviceaccounts', 
                    'foreignsecurityprincipals'

function caricaTutteOUs ( $p_ADServer, $p_base ) {
    $global:mapAllOUs = @{}
    $global:mapIdufuOU = @{}
    $filtr = "name -like '*'"
    $local:allADou = Get-ADOrganizationalUnit -filter $filtr `
                                       -properties description `
                                       -SearchBase $p_base `
                                       -Server $p_ADServer
    foreach ( $ou in $allADou ) {
      $local:descr = $ou.description
      $local:nomcorto = accorciaAdNome $ou.name
      Write-Host $local:nomcorto, $ou.DistinguishedName
      if ( $script:scartaOUs -icontains $local:nomcorto ) {
        continue
      }
      
      $local:nomcorto2 = $local:nomcorto
      if (  $script:mapAllOUs.Contains($local:nomcorto) ) {
        $local:doppione = $script:mapAllOUs[$local:nomcorto]
        # Write-Host $local:doppione.DistinguishedName -ForegroundColor Yellow
        # append di "_n"++
        $local:i = 1
        while ( $script:mapAllOUs.Contains($local:nomcorto2) ) {
          $local:nomcorto2 = "{0}_{1}" -f $local:nomcorto, $local:i++
        }
      }

      $ufu = New-Object System.Object
      $ufu | Add-Member -type NoteProperty -name azienda   -value $null
      $ufu | Add-Member -type NoteProperty -name idUfu     -value $null
      $ufu | Add-Member -type NoteProperty -name idPadre   -value $null
      $ufu | Add-Member -type NoteProperty -name NomeUfu   -value $ou.name
      $ufu | Add-Member -type NoteProperty -name ADou      -value $ou
      $ufu | Add-Member -type NoteProperty -name shortName -value $local:nomcorto2

      $arr = $null
      if ( $local:descr -ne $null ) {
        $arr = $local:descr.ToLower()
      } 
      if ( $arr -ne $null -and $arr.contains("idufu:") ) {
        $arr = $arr -replace "idufu:","" -replace "padre=","" -split ","
        if ( $arr -is [array] ) {
          $idufu = $arr[0]
          $arr2 = $idufu -split "_"
          $ufu.azienda = $arr2[0]
          $ufu.idUfu = $idufu
          $ufu.idPadre = $arr[1]
          $global:mapIdufuOU[$idufu] = $ufu

        }
      }
      $global:mapAllOUs.Add($local:nomcorto2, $ufu)
    }
}

#-----------------------------------------------
# tolgo tutti i caratteri speciali dal nome 
function accorciaAdNome( [string] $p_nam ) {
  $local:l_sz = $p_nam
  if ( $local:l_sz -eq $null ) {
    return $local:l_sz
  }
  $local:l_sz = $local:l_sz `
         -replace " ","" `
         -replace ",","" `
         -replace "/","" `
         -replace "'","" `
         -replace "\.","" `
         -replace "\-",""
  $local:l_sz = $local:l_sz.ToLower().Trim()
  return $local:l_sz
}

# ---------------------------------------------------------------
# Active Directory
$script:ADServer= "dcforestdmz"
$script:ADBase  = "DC=pa,DC=cis"

caricaTutteOUs $script:ADServer $script:ADBase
$global:mapAllOUs 

