$fileProp="c:\temp\psprop.properties"
# -------------------------------------
# $filedata = @'
# app.name=Applicazione
# app.version=1.2
# server=dcciscoop.ciscoop.cis
# zona.prim=ciscoop.cis
# '@
# $filedata | set-content $fileProp
# -------------------------------------

# adesso lo leggo

$AppProps = ConvertFrom-StringData (Get-Content $fileProp -raw)
$AppProps

$AppProps.'app.version'
$SrvName = $AppProps.'server'

"Server = $SrvName"

# record alias
#New-DnsRecord   -Server dcciscoop.ciscoop.cis `
#                -RecordType CNAME `
#                -ZoneName sbrazziamo.dmz-cis.ciscoop.cis `
#                -Hostname aragorn.ciscoop.cis `
#                -Name ghirigoro 
$encPsw   = $AppProps.'db.passwd' | ConvertTo-SecureString
$userCreds = New-Object System.Management.Automation.PSCredential ($AppProps.'db.user', $encPsw)
$txpass = $userCreds.GetNetworkCredential().Password
"decripted  $txpass"
