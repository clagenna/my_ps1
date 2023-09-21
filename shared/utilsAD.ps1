

#-----------------------------------------------
# precarico le OU da AD nel $script:mapAllOUs --> shortName_0
# gli omonimi hanno shortName_n++
$script:scartaOUs = 'users', 
                    'utenti', 
                    'domaincontrollers', 
                    'builtin', 
                    'computers', 
                    'system', 
                    'managedserviceaccounts', 
                    'foreignsecurityprincipals'



$script:ousDaScartare = 
               "OU=Applicazioni", 
               "OU=AIF", 
               "OU=ISS", 
               "OU=BANCA CENTRALE",
               "OU=unascribed",
               "OU=Esterni",
               "OU=ISIS"


# ---------------------------------------------------------------
function decodificaEnte( [int]$pente ) {
  $ret = "800"
  if ( $script:mapAziende -ne $null -and $script:mapAziende.count -gt 0 )  {
    $ret = $script:mapAziende[$pente]
    if ( $ret -ne $null ) {
      return $ret
    }
  }

  switch ( $pente ) {
      1	{ $ret = "ciscoop" }
      2	{ $ret = "800" } # banca centrale
      3	{ $ret = "800" } # AIF
      6	{ $ret = "800" } # camera di commercio

    100	{ $ret = "CONS" }
    200	{ $ret = "Universita" }
    300	{ $ret = "AASP" }
    400	{ $ret = "800" }
    700	{ $ret = "ISS" }
    800	{ $ret = "800" }
    900	{ $ret = "AASS" }
  }
  return $ret
}

# ---------------------------------------------------------------
function caricaEnteAziende( $p_ADServer ) {
    $szbase = "OU=enti,DC=pa,DC=cis"
    $adOUs = Get-ADOrganizationalUnit `
                   -Filter "*" `
                   -properties 'description' `
                   -server $p_ADServer `
                   -SearchBase $szbase  `
                   -SearchScope OneLevel
    $script:mapAziende = @{}
    foreach ( $ou in $adOUs ) {
      # Write-Host $ou.description
      $objou = separaDescription $ou.description
      # Write-Host $ou.DistinguishedName
      if ( ! ( $objou -is [string] ) ) {
        [int]$iiAzie = [int]$objou.azienda
        $script:mapAziende[$iiazie] = $ou.Name
      } else {
        Write-Host $ou.Description -ForegroundColor Yellow
      }
    }
}

# ---------------------------------------------------------------
Function normalizzaSamAccountName ( [string] $p_nome , [string] $p_cognome, [int] $p_lung = 99  ) {
    $szRet  = "{0}.{1}" -f $p_nome.trim(), $p_cognome.Trim()
    $szRet  = $szRet -replace " ","" `
                     -replace "'","" `
                     -replace "à","a" `
                     -replace "è","e" `
                     -replace "é","e" `
                     -replace "ì","i" `
                     -replace "ò","o" `
                     -replace "ù","u" 
    if ( $szRet.Length -gt $p_lung ) {
      $szRet = $szRet.Substring(0,$p_lung)
    }
    $szRet = $szRet.ToLower()
    return $szRet
}


# ---------------------------------------------------------------
Function normalizzaOUName ( [string] $pnome  ) {
  $ret = $pnome
  
  if ( $ret -eq $null ) { return $ret; }
  # esc delle virg mal digerite da LDAP di AD
  # claudio 2016-05-04, le virgole fanno troppo casino nei nomi OU!
  # $ret = $ret  -replace ",","\,"
  # tolgo le virgole
  $ret = $ret.Trim()
  $ret = $ret  -replace ",","" -replace "  "," " -replace "'",""

  # il nome può essere max 64 chars
  if ( $ret.Length -gt 64 ) { $ret = $ret.Substring(0,64) }
  return $ret
}

# ---------------------------------------------------------------
function separaOUs ( [string] $p_distName ) {
    $local:arr = $null
    if ( $p_distName -eq $null ) {
      return $local:arr
      }
    $local:arr = $p_distName.Split(",")
    $local:arrOU = @()
    $local:precTok=$null
    forEach ( $tok in $local:arr ) {
        $pos = $tok.IndexOf("=")
        if ( $pos -lt 0 ) {
          $local:precTok += ","
          $local:precTok += $tok
        } else {
          if ( $local:precTok -ne $null ) {
            $local:arrOU += $local:precTok
          }
          $local:precTok = $tok
        }
    }
    if ( $local:precTok -ne $null ) {
      $local:arrOU += $local:precTok
    }
    return $local:arrOU
}
						 
# ---------------------------------------------------------------
function isValue($p_par) {
  if ( $p_par -eq $null ) {
    return $false
  }
  if ( $p_par -is [dbnull] ) {
    return $false
  }
  $local:ll = $p_par.toString().Trim().Length
  return ( $local:ll -gt 0 ) 
}

# ---------------------------------------------------------------
function caricaTutteOUs ( $p_ADServer, $p_base ) {
    $global:mapAllOUs = @{}
    $global:mapIdufuOU = @{}
    caricaEnteAziende( $p_ADServer )
    $filtr = "name -like '*'"
    $local:allADou = Get-ADOrganizationalUnit -filter $filtr `
                                       -properties description `
                                       -SearchBase $p_base `
                                       -SearchScope Subtree `
                                       -Server $p_ADServer
    $caricacerca="Boh!CheNeSo"
    foreach ( $ou in $allADou ) {
      $local:descr = $ou.description
      $local:nomcorto = accorciaAdNome $ou.name
      $local:distName = $ou.DistinguishedName
      if ( $ou.DistinguishedName.IndexOf($caricacerca) -ge 0 ) {
        Write-Host "Trovato $caricacerca"
      }
      # Write-Host $local:nomcorto, $ou.DistinguishedName
      if ( $script:scartaOUs -icontains $local:nomcorto ) {
        continue
      }
      if ( $local:distName.ToLower().Contains( "ou=utenti" ) ) {
        continue
      }
      if ( $local:distName.ToLower().Contains( "ou=uffici," ) ) {
        continue
      }
      
      $local:nomcorto2 = $local:nomcorto
      

      if (  $global:mapAllOUs.Contains($local:nomcorto) ) {
        $local:doppione = $global:mapAllOUs[$local:nomcorto]
        # Write-Host $local:doppione.DistinguishedName -ForegroundColor Yellow
        # append di "_n"++
        $local:i = 1
        while ( $global:mapAllOUs.Contains($local:nomcorto2) ) {
          $local:nomcorto2 = "{0}_{1}" -f $local:nomcorto, $local:i++
        }
      }
      
      $ufu = New-Object System.Object
      $ufu | Add-Member -type NoteProperty -name azienda   -value $null
      $ufu | Add-Member -type NoteProperty -name idPadre   -value $null
      $ufu | Add-Member -type NoteProperty -name idUfu     -value $null
      $ufu | Add-Member -type NoteProperty -name idSez     -value $null
      $ufu | Add-Member -type NoteProperty -name NomeUfu   -value $ou.name
      $ufu | Add-Member -type NoteProperty -name ADou      -value $ou
      $ufu | Add-Member -type NoteProperty -name Descr     -value $local:descr
      $ufu | Add-Member -type NoteProperty -name shortName -value $local:nomcorto2

      $arr = $null
      if ( $local:descr -ne $null -and $local:descr.length -gt 2 ) {
        $arr = $local:descr.ToLower()
      } 
      # else {
      #   Write-Host ("La OU {0} non ha descr !" -f  $local:distName ) -ForegroundColor Cyan
      # }
      if ( $arr -ne $null -and $arr.contains("idufu:") ) {
        $arr = $arr -replace "idufu:","" -replace "padre=","" -split ","
        if ( $arr -is [array] ) {
          # idufu = 800_103
          $idufu = $arr[0]
          $arr2 = $idufu -split "_"
          if ( $arr2 -is [array] -and $arr2.Length -gt 1 )  {
              $ufu.azienda = $arr2[0]
              if ( $arr2[1].toLower().IndexOf('s') -ge 0 ) {
                $ufu.idSez =  $arr2[1]
              } 
          }
          $ufu.idUfu = $idufu
          $ufu.idPadre = $arr[1]
          $global:mapIdufuOU[$idufu] = $ufu

        }
      }
      $global:mapAllOUs.Add($local:nomcorto2, $ufu)
    }
    # Write-Host "Creato global:mapAllOUs ( shortname -> ufu )"
    # write-host "Creato global:mapIdufuOU( idufu -> ufu )"
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

#-------------------------------------------------
# converti descrizione in codiss
function convertiDescrCodiss( [string] $p_descr ) {
  [int] $local:l_codiss = -1
  $local:sz = $null
  if (  $p_descr -eq $null -or $p_descr.Length -eq 0 ) {
    return $local:l_codiss
  }
  $arr = $p_descr.split(":")
  if ( $arr.count -gt 1 ) {
    $local:sz = $arr[1]
  }
  if ( $local:sz -ne $null ) {
    if ( $local:sz -match "^[0-9]+$" ) {
      $local:l_codiss = [System.Convert]::ToInt32($local:sz)
    }
  }
  return $local:l_codiss
}

# -------------------------------------------------
# se la OU e' presente nel elenco di quelle da scratare
function isOUDaScartare( [string] $p_dnou ) {
  $bScarta = $false
  foreach ( $sz in $script:ousDaScartare ) {
    if ( $p_dnou.toLower().indexOf( ($sz+",").ToLower() ) -ge 0 ) {
      $bScarta = $true
      break
    }
  }
  return $bScarta
}

#-----------------------------------------------------
# separa la descrizione delle OU nelle sue componenti base
#   esempio: $str="idufu:800_S146,padre=800_129"
# 
#  azienda  idUfu       idPadre     idSez
#  -------  -----       -------     -----
#   800     800_S146    800_129     S146 

function separaDescription( [string] $p_desc ) { 
    $ouUfu = New-Object System.Object
    $ouUfu | Add-Member -type NoteProperty -name azienda   -value $null
    $ouUfu | Add-Member -type NoteProperty -name idUfu     -value $null
    $ouUfu | Add-Member -type NoteProperty -name idPadre   -value $null
    $ouUfu | Add-Member -type NoteProperty -name idSez     -value $null

    # idufu:800_S146
    # padre=800_129
    $arrAll = $p_desc.Split(",")
    if ( $arrAll -eq $null -or $arrAll.Length -lt 2 ) {
      return "Descr errata:$p_desc"
    }

    # -> idufu:800_S146
    $szUfu = $arrAll[0].Split(":")[1]

    # -> 800_S146
    $arrUfu = $szUfu.Split("_")

    # -> 800, S146
    $ouUfu.azienda = [int]$arrUfu[0]
    $ouUfu.idUfu   = $szUfu
    if ( $szUfu.ToLower().IndexOf("s") -ge 0 ) {
      $ouUfu.idsez   = $arrUfu[1]
    }

    # -> 
    $ouUfu.idPadre   =  $arrAll[1].Split("=")[1]
    return $ouUfu
}
