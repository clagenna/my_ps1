$utente = "administrator"
Write-Host "Dammi la password per: $utente"
read-host -assecurestring | convertfrom-securestring | out-file C:\temp\cred.txt

# una volta salvato in maniera sicura la password la posso ripristinare
$pass = get-content C:\temp\cred.txt | convertto-securestring

# creo delle credenziali da usare con le cmdlets per AD
$credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $utente,$pass

# 
$samaccount = "claudio"
$grps = Get-ADUser  -Identity $samaccount `
                    -Credential $credentials `
                    -Server dcforestdmz.dmz-cis.pa.cis `
                    -Properties memberof | 
  select -ExpandProperty memberOf  
$grps
