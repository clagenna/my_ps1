Get-WMIobject win32_networkadapterconfiguration | 
   Where-Object {$_.IPEnabled -eq “True”} | 
   Select-Object pscomputername,ipaddress,defaultipgateway,ipsubnet,dnsserversearchorder,winsprimaryserver | 
   format-Table -Auto