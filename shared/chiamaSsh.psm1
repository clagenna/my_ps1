$script:chiamaSshDebug=$false
if ( $env:TEMP -eq $null -or $env:TEMP.Length -lt 4 ) {
  Write-Host "!!!     A T T E N Z I O N E    !!!" -ForegroundColor Red
  Write-Host "Non hai la variabile di Environment TEMP !!!" -ForegroundColor Red
} else {
  $script:myKeyFile = ( "{0}\chiave_{1}.key" -f  ($env:TEMP) , (Get-Date -Format "yyyyMMdd_HHmmss") )
  }


# --------------------------------------------------------------------------
function set-sshKey( [string]$p_key ) {
  $script:myKeyFile = $p_key
}

# --------------------------------------------------------------------------
function clear-filechiave() {
  if ( Test-Path $script:myKeyFile ) {
    Remove-Item -Path $script:myKeyFile -Force
  }
}

# --------------------------------------------------------------------------
function find-filechiave() {
  if ( Test-Path $script:myKeyFile ) {
    return
  }
  "-----BEGIN RSA PRIVATE KEY-----",
"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",
"-----END RSA PRIVATE KEY-----" | Out-File $script:myKeyFile -Encoding ascii 
}

# --------------------------------------------------------------------------
function get-sshText( [string] $p_Host, [string]$p_comando ) {

  $l_retfil = ""

  Try {
        $encpwd = "pippo" | ConvertTo-SecureString -asPlainText -Force
        $creds  = new-object System.Management.Automation.PSCredential("root",$encpwd)
        $sess   = New-SshSession -ComputerName $p_Host -Credential $creds -KeyFile $script:myKeyFile -AcceptKey 
        # $sshObj = Invoke-SshCommand -ComputerName $p_Host -Command $p_comando -Quiet
        # $sshObj = Invoke-SshCommand -SessionId $sess.SessionId -Command $p_comando -TimeOut 16 #-Quiet
        $sshObj = Invoke-SshCommand -SessionId $sess.SessionId -Command $p_comando
        if ( $sshObj -is [array] ) {
          $sshObj = $sshObj[0]
        }
        if ( $sshObj -is [PSCustomObject] ) {
          $l_retfil = $sshObj.Output
          if ( $l_retfil -is [array] ) {
            $l_retfil = $l_retfil -join "`r`n" | Out-String
          }
        }
        if ( $sshObj -is [string] ) {
          $l_retfil += $sshObj
        } 
        $l_retfil += "`n"
        if ( $script:chiamaSshDebug ) {
          out-logDebug ( "letto host: {0} con comando {1}" -f $p_Host, $p_comando )
          out-logDebug ( $sshObj )
        }
        $remSess = Remove-SshSession -SessionId $sess.SessionId
    } Catch {
        $script:inErrore = $true
        $outMsg = $_.Exception.Message
        out-logErr ( "Errore SSH su {0}`tcausa:{1}" -f $p_Host, $outMsg )
        throw $Global:lastErrorText
    }
  
  return $l_retfil
}

# --------------------------------------------------------------------------
function Invoke-miossh( [array]$p_arrHo, [string]$p_comando ) {

  $l_retfil = ""

ForEach ( $ho in $p_arrHo ) {
  Try {
        # $sshObj = New-SshSession -ComputerName $ho -Username root -KeyFile $script:myKeyFile
        # $sshObj = Invoke-SshCommand -ComputerName $ho -Command $p_comando -Quiet
        $encpwd = "pippo" | ConvertTo-SecureString -asPlainText -Force
        $creds   = new-object System.Management.Automation.PSCredential("root",$encpwd)
        $sess = New-SshSession -ComputerName $ho -Credential $creds -KeyFile $script:myKeyFile -AcceptKey
        $sshObj = Invoke-SshCommand -SessionId $sess.SessionId -Command $p_comando # -TimeOut 2 #-Quiet
        if ( $sshObj -is [array] ) {
          $l_retfil += $sshObj -join "`r`n" | Out-String
        }
        if ( $sshObj -is [PSCustomObject] ) {
          $l_obj = $sshObj.Output
          if ( $l_obj -is [array] ) {
            $l_retfil += $l_obj -join "`r`n" | Out-String
          }
        }
        if ( $sshObj -is [string] ) {
          $l_retfil += $sshObj
        } 

        $l_retfil += "`n"
        if ( $script:chiamaSshDebug ) {
          out-logDebug ( "letto host: {0} con comando {1}" -f $ho, $p_comando )
          out-logdebug ( $sshObj )
        }
        $remSes = Remove-SshSession -SessionId $sess.SessionId
    } Catch {
        $script:inErrore = $true
        $outMsg = $_.Exception.Message
        out-logerr ( "Errore SSH su {0}`tcausa:{1}" -f $ho, $outMsg )
    }
  }
  return $l_retfil
}

# --------------------------------------------------------------------------
function Invoke-mioscp( [string]$host , [string]$remfile , [string]$locfile ) {
  Try {
        $encpwd = "pippo" | ConvertTo-SecureString -asPlainText -Force
        $creds   = new-object System.Management.Automation.PSCredential("root",$encpwd)
        # $sess = New-SshSession -ComputerName $host -Credential $creds -KeyFile $script:myKeyFile
        $sshObj = Get-SCPFile -ComputerName $host -Credential $creds -KeyFile $script:myKeyFile  -RemoteFile $remfile  -LocalFile $locfile
    } Catch {
        $script:inErrore = $true
        $outMsg = $_.Exception.Message
        out-logerr ( "Errore SSH su {0}`tcausa:{1}" -f $ho, $outMsg )
    }
 
}

# --------------------------------------------------------------------------
function Invoke-mioscpput( [string]$host , [string]$locfile , [string]$remfile ) {
  Try {
        $encpwd = "pippo" | ConvertTo-SecureString -asPlainText -Force
        $creds   = new-object System.Management.Automation.PSCredential("root",$encpwd)
        # $sess = New-SshSession -ComputerName $host -Credential $creds -KeyFile $script:myKeyFile
        $sshObj = Set-SCPFile -ComputerName $host `
                         -Credential $creds  `
                         -KeyFile $script:myKeyFile   `
                         -RemotePath $remfile   `
                         -LocalFile $locfile
    } Catch {
        $script:inErrore = $true
        $outMsg = $_.Exception.Message
        out-logerr ( "Errore Put SCP su {0}`tcausa:{1}" -f $ho, $outMsg )    }
 
}
# --------------------------------------------------------------------------
Export-ModuleMember -Function 'get-*'
Export-ModuleMember -Function 'set-*'
Export-ModuleMember -Function 'Invoke-miossh'
Export-ModuleMember -Function 'Invoke-mioscp'
Export-ModuleMember -Function 'Invoke-mioscpput'

Export-ModuleMember -Function 'find-filechiave'
Export-ModuleMember -Function 'clear-filechiave'
