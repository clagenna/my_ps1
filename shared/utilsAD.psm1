# ---------------------------------------------------------------
# precarico le OU da AD nel $script:mapAllOUs --> shortName_0
# gli omonimi hanno shortName_n++
function out-OUsDaScartare() {

$Global:scartaOUs = 'users', 
               #    'applicazioni', 
                    'utenti', 
                    'domaincontrollers', 
                    'builtin', 
                    'computers', 
                    'system', 
                    'managedserviceaccounts', 
                    'foreignsecurityprincipals'



$Global:ousDaScartare = 
           #   "OU=Applicazioni", 
               "OU=AIF", 
               "OU=ISS", 
               "OU=BANCA CENTRALE",
               "OU=unascribed",
               "OU=Esterni",
               "OU=ISIS"
}

# ---------------------------------------------------------------
function decodificaEnte( [int]$pente ) {
  $ret = "800"
  if ( $script:mapAziende -ne $null -and $script:mapAziende.count -gt 0 )  {
    $ret = $script:mapAziende[$pente]
    return $ret
  }

  switch ( $pente ) {
      1	{ $ret = "ciscoop" }
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
  $ret = $ret  -replace "/"," " -replace "'"," " -replace ",","" -replace "  "," "

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
  if ( $p_par -is [System.Collections.CollectionBase] ) {
    return ( $p_par.Count -gt 0 )
  }
  $local:ll = $p_par.toString().Trim().Length
  return ( $local:ll -gt 0 ) 
}

# ---------------------------------------------------------------
function caricaTutteOUs ( $p_ADServer, $p_base ) {
    $global:mapAllOUs = @{}
    $global:mapIdufuOU = @{}
    $global:mapIdOrg = @{}
    $global:mapCanonOU = @{}
    caricaEnteAziende( $p_ADServer )
    $filtr = "name -like '*'"
    $local:allADou = Get-ADOrganizationalUnit -filter $filtr `
                                       -properties description,passIdAzienda,passIdUfu,passIdPadre,passIdSezione,passIdOrgUfu,passIdOrgPadre,passNomeUfu `
                                       -SearchBase $p_base `
                                       -SearchScope Subtree `
                                       -Server $p_ADServer 

    $caricacerca="Boh!CheNeSo"
    foreach ( $ou in $allADou ) {
      $local:descr = $ou.description
      $local:nomcorto = accorciaAdNome $ou.name
      $local:distName = $ou.DistinguishedName
      $local:canonName = accorciaDistName $local:distName 
      if ( $ou.DistinguishedName.IndexOf($caricacerca) -ge 0 ) {
        Write-Host "Trovato $caricacerca"
      }
      # Write-Host $local:nomcorto, $ou.DistinguishedName
      if ( $Global:scartaOUs -icontains $local:nomcorto ) {
        continue
      }
      if ( $local:distName.ToLower().Contains( "ou=utenti" ) ) {
        continue
      }
      if ( $local:distName.ToLower().Contains( "ou=uffici," ) ) {
        continue
      }
      # nome accorciato dalla accorciaAdNome
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
      $ufu | Add-Member -type NoteProperty -name idOrgUfu   -value $ou.passIdOrgUfu
      $ufu | Add-Member -type NoteProperty -name idOrgPadre -value $ou.passIdOrgPadre
      $ufu | Add-Member -type NoteProperty -name azienda    -value $ou.passIdAzienda
      $ufu | Add-Member -type NoteProperty -name idPadre    -value $ou.passIdPadre
      $ufu | Add-Member -type NoteProperty -name szIdUfu    -value $null
      $ufu | Add-Member -type NoteProperty -name idUfu      -value $ou.passIdUfu
      $ufu | Add-Member -type NoteProperty -name idSez      -value $ou.passIdSezione

      $ufu | Add-Member -type NoteProperty -name passIdOrgUfu -value $ou.passIdOrgUfu
      $ufu | Add-Member -type NoteProperty -name passIdOrgPadre -value $ou.passIdOrgPadre

      $ufu | Add-Member -type NoteProperty -name NomeUfu    -value $ou.name
      $ufu | Add-Member -type NoteProperty -name ADou       -value $ou
      $ufu | Add-Member -type NoteProperty -name Descr      -value $local:descr
      $ufu | Add-Member -type NoteProperty -name shortName  -value $local:nomcorto2

      $local:idOrgUfu = 0

      $local:ii  = calcolaIdOrgUFU $ufu.azienda $ufu.idUfu $ufu.idSez
      if ( $local:ii -ne $ufu.idOrgUfu ) {
        $ufu.idOrgUfu = $local:ii
      }
      # ---------------------------
      # idOrgPadre
      $local:ii = calcolaIdOrgUFU $ufu.azienda $ufu.idPadre 0
      if ( $local:ii -ne $ufu.idOrgPadre ) {
        $ufu.idOrgPadre = $local:ii
      }
      # ---------------------------

      $global:mapAllOUs.Add($local:nomcorto2, $ufu)
      if (  $ufu.idOrgUfu   -ne    $null  ) {
        $global:mapIdOrg[$ufu.idOrgUfu] = $ufu
      }
      if ( $local:canonName -ne $null -and $local:canonName -gt 2 ) {
        $global:mapCanonOU[$local:canonName ] = $ufu 
      }
    }
    # Write-Host "Creato global:mapAllOUs ( shortname -> ufu )"
    # write-host "Creato global:mapIdufuOU( idufu -> ufu )"
}

# ----------------------------------------------------------------------------
function calcolaIdOrgUFU( [Parameter(Mandatory=$true)][int]$p_idAzienda
                        , [Parameter(Mandatory=$true)][int]$p_idUFU
                        , [Parameter(Mandatory=$false)][int]$p_idSezione ) 
{
  [int]$nRetIdOrgUfu = 0
  # ---------------------------
  # calcolo della idOrgUfu
  if ( $p_idAzienda -lt 1 ) {
    return $nRetIdOrgUfu
  }
  $nRetIdOrgUfu  = $p_idAzienda * 10
  if ( $p_idSezione -ne $null -and $p_idSezione -is [int32] -and $p_idSezione -gt 0 ) {
    # idOrgUnit X la sezione (c'ha un '1')
    $nRetIdOrgUfu  = $nRetIdOrgUfu  + 1
    $nRetIdOrgUfu  = $nRetIdOrgUfu  * 10000 + $p_idSezione
  } else {
    $nRetIdOrgUfu  = $nRetIdOrgUfu  * 10000 + $p_idUFU
  }
  return $nRetIdOrgUfu 
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


#-----------------------------------------------
# creo un nome canonico accorciato per i distinguished
function accorciaDistName( $szDn ) {
    $arr = separaOUs $szDn
    $canon = ""
    foreach ( $ele in $arr ) {
      if ($ele.tolower().startsWith("cn=") ) {
        continue
      }
      if ($ele.tolower().indexOf("dc=") -ge 0 ) {
        continue
      }
      if ($ele.tolower().indexOf("ou=enti") -ge 0 ) {
        continue
      }
      if ( $canon.Length -gt 2 ) {
        $canon += "/"
      }
      $canon += accorciaAdNome ($ele.toLower() -replace "ou=")
    }

    return $canon  
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
  foreach ( $sz in $Global:ousDaScartare ) {
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
    $ouUfu | Add-Member -type NoteProperty -name szIdUfu   -value $null
    $ouUfu | Add-Member -type NoteProperty -name idUfu     -value $null
    $ouUfu | Add-Member -type NoteProperty -name szIdPadre -value $null
    $ouUfu | Add-Member -type NoteProperty -name idPadre   -value $null
    $ouUfu | Add-Member -type NoteProperty -name idSez     -value $null

    # idufu:800_S146
    # padre=800_129
    $arrAll = $p_desc.Split(",")
    if ( $arrAll -eq $null -or $arrAll.Length -lt 2 ) {
      return "Descr errata:$p_desc"
    }

    # -> szIdUfu:800_S146
    $szUfu = $arrAll[0].Split(":")[1]
    $ouUfu.szIdUfu  = $szUfu
    # -> 800_S146
    $arrUfu = $szUfu.Split("_")
    # $arrUfu -> 800, S146
    $ouUfu.azienda = [int]$arrUfu[0]
    if ( $szUfu.ToLower().IndexOf("s") -ge 0 ) {
      # se c'è una 's' è una sezione
      $ouUfu.idUfu   = 0
      $ouUfu.idsez   = [int]$arrUfu[1].Substring(1)
    } else {
      # altrimenti è un Ufu
      $ouUfu.idUfu   = [int]$arrUfu[1]
      $ouUfu.idsez   = $null
    }
    # -> 
    $ouUfu.szIdPadre   =  $arrAll[1].Split("=")[1]
    if ( $ouUfu.szIdPadre.indexOf("_") -ge 0 ) {
        $arrUfu = $ouUfu.szIdPadre.Split("_")
        $ouUfu.idPadre = [int]$arrUfu[1]
    } else {
      $ouUfu.idPadre = -1 # non ho padre
    }
    return $ouUfu
}


# Per la conessione a SQL server pretende che sia già impostato:
#       $Global:SQLHost 
#       $Global:SQLUser
#       $Global:SQLpswd 
# di ritorno imposta la variabile 
#       $Global:inErrore (se 'cè stato un errore
#       $Global:PathPadreOU   con l'ultima OU (foglia)  ricercata
# ---------------------------------------------------------------
function new-OrganizationalUnitDaPass([Parameter(mandatory=$true)][int]$p_idAzienda
                                    , [Parameter(mandatory=$false)][int]$p_idUfu
                                    , [Parameter(mandatory=$false)][int]$p_idSezione
                                ) 
{
    $Global:inErrore = $false
    $szQry  = "SELECT * FROM claudio.funAlberoUfu({0},{1},{2}) order by seq desc"
    $p2 = "null"
    $p3 = "null"
    # se mi specifichi una sezione gli do priorità per trovare suo padre
    if ( $p_idSezione -ne $null -and $p_idSezione -gt 0 ) {
      $p3 = $p_idSezione
    } else {
      $p2 = $p_idUfu 
    }
    $sz = $szQry -f $p_idAzienda, $p2, $p3
    $rowSet = Invoke-Sqlcmd -Query $sz  `
                 -ServerInstance $Global:SQLHost  `
                 -Database "pass"  `
                 -Username $Global:SQLUser  `
                 -Password $Global:SQLpswd 
    if ( $rowSet -eq $null ) {
        $Global:inErrore = $true
        out-Logerr ( "Non trovo in PASS Az:{0} Ufu:{1}  Sez:{2}" -f $p_idAzienda,$p_idUfu,$p_idSezione )
    }
     
    $local:arrSeq = @()
# seq     idOrg           idOrgPadre      IdAzienda       IdUFu   idSezione       idPadre idufu2          idPadre2        Descrizione                     NomeUFu
# ---     --------        ----------      ---------       -----   ---------       ------- --------        --------        ----------------------------    ----------------------------
# 3       80000000        0               800             0       0               0       800_0           0               idufu:800_0,padre=0             Pubblica Amministrazione                                                             
# 2       80000009        80000000        800             9       0               0       800_9           800_0           idufu:800_9,padre=800_0         DIP. ISTRUZIONE
# 1       80000136        80000009        800             136     0               9       800_136         800_9           idufu:800_136,padre=800_9       SCUOLA SECONDARIA SUPERIORE
# 0       80010116        80000136        800             0       116             136     800_s116        800_136         idufu:800_s116,padre=800_136    Insegnanti
    ForEach  ( $riga in $rowSet ) {
        $objOrgUn = "" | select seq, idOrg, idOrgPadre, IdAzienda, IdUFu, idSezione, idPadre, idufu2, idPadre2, Descrizione, NomeUFu, adOrgUnit
        $objOrgUn.seq       = $riga.seq     
        $objOrgUn.idOrg     = $riga.idOrg       
        $objOrgUn.idOrgPadre= $riga.idOrgPadre  
        $objOrgUn.IdAzienda = $riga.IdAzienda   
        $objOrgUn.IdUFu     = $riga.IdUFu       
        $objOrgUn.idSezione = $riga.idSezione   
        $objOrgUn.idPadre   = $riga.idPadre 
        $objOrgUn.idufu2    = $riga.idufu2  
        $objOrgUn.idPadre2  = $riga.idPadre2    
        $objOrgUn.Descrizione= $riga.Descrizione    
        $objOrgUn.NomeUFu   = $riga.NomeUFu 
        $objOrgUn.adOrgUnit = $null

        $ldapFiltr = "(passIdOrgUfu={0})" -f $objOrgUn.idOrg
        try {
        $objOrgUn.adOrgUnit = Get-ADOrganizationalUnit `
                            -SearchBase $Global:ADBase  `
                            -Server $Global:ADServer  `
                            -LDAPFilter $ldapFiltr  `
                            -Properties description,passIdAzienda,passIdOrgPadre,passIdOrgUFu,passIdPadre,passIdSezione,passIdUFU,passNomeUFU 
        } Catch {
            $Global:inErrore = $true
            $outMsg = $_.Exception.Message
            out-Logerr ( "Err cerca OU {0} in {1}`tcausa:{2}" -f $riga.NomeUFu, $Global:ADBase, $outMsg )
            return
        }
        $Global:PathPadreOU = $null
        $local:msg = "nuova OU {0} in ( az={1} orgPadre={2}" -f $objOrgUn.NomeUFu, $objOrgUn.IdAzienda, $objOrgUn.idOrgPadre 
        if ( $objOrgUn.adOrgUnit -eq $null ) {
            out-logInfo "devo creare $local:msg"
            if ( $local:arrSeq.count -gt 0 ) {
                $local:ADpadreOU    = $local:arrSeq[$local:arrSeq.count - 1].adOrgUnit
                $Global:PathPadreOU = $local:ADpadreOU.distinguishedName
            }
            if ( $Global:PathPadreOU -eq $null ) {
                out-logErr "Non ho il padre per la $local:msg"
                $Global:inErrore = $true
                return
            }
            $local:nomeOU = normalizzaOUName $objOrgUn.NomeUFu
            $attrs = @{
                  passIdAzienda     = $objOrgUn.IdAzienda
                ; passIdOrgPadre    = $objOrgUn.IdOrgPadre
                ; passIdOrgUFu      = $objOrgUn.idOrg
                ; passIdPadre       = $objOrgUn.IdPadre
                ; passIdSezione     = $objOrgUn.IdSezione
                ; passIdUFU         = $objOrgUn.IdUFU
                ; passNomeUFU       = $objOrgUn.NomeUfu
                ; description       = $objOrgUn.Descrizione
            }
            $local:messerr = $null
            Try {

            New-ADOrganizationalUnit -Server $Global:ADServer  `
                                     -Name $local:nomeOU `
                                     -Path $Global:PathPadreOU `
                                     -OtherAttributes $attrs `
                                     -ErrorAction stop
            
            out-logInfo ( "Creato nuova OU {0} sotto la {1}" -f $local:nomeOU, $Global:PathPadreOU )
            } Catch {
                $Global:inErrore = $true
                $local:messerr = $_.Exception.Message
                out-Logerr ( "Errore crea OU {0} in {1}`tcausa:{2}" -f $local:nomeOU, $Global:ADBase, $local:messerr )
            }
            # ------------------  se mi da errore la precedente provo con le credenziali -----------------------
            Try {
            if ( $Global:inErrore  -and $local:messerr -ne $null -and $local:messerr -imatch "acces" ) {
                $Global:inErrore = $false
                $local:messerr   = $null
                $local:cred = getCredenziali
                New-ADOrganizationalUnit -Server $Global:ADServer  `
                                         -Name $local:nomeOU `
                                         -Credential $local:cred `
                                         -Path $Global:PathPadreOU `
                                         -OtherAttributes $attrs `
                                         -ErrorAction stop
                out-logInfo ( "Creato nuova OU {0} sotto la {1}" -f $local:nomeOU, $Global:PathPadreOU )
            }
            } Catch {
                $Global:inErrore = $true
                $local:messerr = $_.Exception.Message
                out-Logerr ( "Errore crea OU {0} in {1}`tcausa:{2}" -f $local:nomeOU, $Global:ADBase, $local:messerr )
            }




            $objOrgUn.adOrgUnit = Get-ADOrganizationalUnit -Server $Global:ADServer  `
                                                           -LDAPFilter $ldapFiltr `
                                                           -SearchBase $Global:PathPadreOU `
                                                           -properties description,passIdAzienda,passIdOrgPadre,passIdOrgUFu,passIdPadre,passIdSezione,passIdUFU,passNomeUFU
            set-UltaggAD $objOrgUn.adOrgUnit
        } 
        if ( $objOrgUn.adOrgUnit -ne $null ) {
            $Global:PathPadreOU = $objOrgUn.adOrgUnit.distinguishedName
        }
        $local:arrSeq += ,$objOrgUn
    }
    # in uscita, se tutto OK, avrò il valore della OU in $Global:PathPadreOU 
    return $Global:PathPadreOU
}

function getCredenziali() {
  $local:secstr = ConvertTo-SecureString  -Key (1..16) -String $Global:encut
  $local:bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secstr)
  $local:ut   = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
  $local:secstr = ConvertTo-SecureString  -Key (1..16) -String $Global:enpsw
  $local:bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secstr)
  $local:psw  = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
  $credps     = ConvertTo-SecureString $local:psw -asPlainText -Force
  $creds = New-Object System.Management.Automation.PSCredential($local:ut,$credps)
  return $creds
}



function set-UltaggAD ( 
                    [Parameter(Mandatory)]$p_obj, 
                    [string] $p_szUtente,
                    [datetime]$p_dt ) {
  if ( $p_obj -eq $null ) {
    return
  }
  # set non fornito metto adesso
  $local:uAgg  = $null
  $Local:dtagg = $p_dt
  if ( $Local:dtagg -eq $null ) {
    $Local:dtagg = Get-Date
  }
  # utente
  if ( ! ([string]::IsNullOrEmpty($p_szUtente)) ) {
    $local:uAgg = $p_szUtente
  }
  if ( $local:uAgg -eq $null ) {
    $local:uAgg = $env:USERAPP
  }
  if ( $local:uAgg -eq $null ) {
    $local:uAgg = "sconosciuto"
  }

  $Local:mapReplace = @{ passUltagg=$Local:dtagg; passUtenteUltagg=$local:uAgg }
  if ( $p_obj -is  [Microsoft.ActiveDirectory.Management.ADUser] ) {
    $p_obj | Set-ADUser -replace $Local:mapReplace
    return
  }
  if ( $p_obj -is  [Microsoft.ActiveDirectory.Management.ADGroup] ) {
    $p_obj | Set-ADGroup -replace $Local:mapReplace
    return
  }
  if ( $p_obj -is  [Microsoft.ActiveDirectory.Management.ADOrganizationalUnit] ) {
    $p_obj | Set-ADOrganizationalUnit -replace $Local:mapReplace
    return
  }

}





$Global:encut = "76492d1116743f0423413b16050a5345MgB8AHoAcgAzADcARwA3AFYAaAA5AFUAUwA3AGkAKwBuAEMARwBXADYAaABNAGcAPQA9AHwAMABlADkANQBhADUANwAzADMANABiADMAYgA2ADgAZQAwADIAZQBhAGUAZgAyAGQAYgBhAGIANAA3AGIAYgA1ADcAYwBlADkAOQA5ADcAZQBjADcANwA5AGQAYQA5ADMANwBhAGQAZQBlADQAMQAzADkANABmADYAMgAzADYAMQA="
$Global:enpsw = "76492d1116743f0423413b16050a5345MgB8ADAARgBDAHUAOABOAHYAWQAvAHQAMgA3AG0ASgA0AEQANwBxAFEAVwBVAEEAPQA9AHwAMgA2ADIAYQAyAGIAYQBjADgANAA3ADAAMQAwADIAZgA3AGMAMwBlADMAMgA3ADcANAA1AGEAZgA4ADkAMAA4ADAAYgA1ADgAYwA0ADQAMwBlADEANgBmAGMAYQAzAGEAYQAzADYAMgBiAGQAZgA4AGMAMAA4AGMAYQA0ADEAZQA="
$Global:encut = "76492d1116743f0423413b16050a5345MgB8AHoAawBtAG0ASQBjAGUAOABCAFMAVQBEAHIAawBJAFYAZAAyAGsAVwBlAFEAPQA9AHwANQAwAGIAMgAwAGMAOQBhADAAMgAyADQAOQBmADAAMABhAGQAZgBhADEAMgA0ADYANQA0AGUAYgAwAGEAZgBlADkANgA3ADEANgAwAGMAMwAzADYAYQA1ADgANQAwAGEAZQA2AGIAOAA3ADcAZAA3AGYAMAAwADUAYgBlADEANgAzAGYAMgAxAGMANAAxADEAZAAxAGEANwBmADIAZgBiADIAMABkAGQANABkADQAMAAzADMAZQA4ADkAMQA1ADcA"
$Global:enpsw = "76492d1116743f0423413b16050a5345MgB8AHcARABoAG8ANwArAEcAbwA0AEMAMAA5ADYAZwB6AG0AZwBoAEwAegAyAGcAPQA9AHwAYQBlADUAMQAyAGYAYgA0ADQAZQA2AGUAMAA3AGIAMQAyADIAOQBmAGIAOAA2AGQAZgA0ADcAYQA0ADkAMgAyADAAOQA2ADEANgBmAGMAMwA4AGQANgA0AGQAMwAzAGUAZAAwADgAZgBhADUANQA4ADAAZQA3AGQANABkADAAZAA="


Export-ModuleMember -Function out-OUsDaScartare
Export-ModuleMember -Function decodificaEnte
Export-ModuleMember -Function caricaEnteAziende
Export-ModuleMember -Function separaOUs
Export-ModuleMember -Function isValue
Export-ModuleMember -Function caricaTutteOUs
Export-ModuleMember -Function calcolaIdOrgUFU
Export-ModuleMember -Function normalizzaOUName
Export-ModuleMember -Function normalizzaSamAccountName 
Export-ModuleMember -Function accorciaAdNome
Export-ModuleMember -Function convertiDescrCodiss
Export-ModuleMember -Function isOUDaScartare
Export-ModuleMember -Function separaDescription
Export-ModuleMember -Function new-OrganizationalUnitDaPass
Export-ModuleMember -Function accorciaDistName
Export-ModuleMember -Function getCredenziali
Export-ModuleMember -Function set-UltaggAD
