

function new-SqlParam([Parameter(Mandatory=$true)][string]$name
                    , [Parameter(Mandatory=$true)][System.Data.DbType]$type
                    , [Parameter(Mandatory=$false)][int]$size = -1 
                    , [Parameter(Mandatory=$false)][int]$dir = [System.Data.ParameterDirection]::Input ) {
  $outParameter = new-object System.Data.SqlClient.SqlParameter;
  $outParameter.ParameterName = "@$name";
  $outParameter.DbType = $type
  switch ($type ) {
    { @( [System.Data.DbType]::String,
        ,[System.Data.DbType]::AnsiString ) -contains $_ } 
        {
          if ( $size -le 0 ) {
            out-logErr "Manca il size per $name"
            exit
          }
          $outParameter.Size = $size;
        }
     default { 
        $outParameter.Size = 0 
     }
  }
  $outParameter.Direction = $dir
  return $outParameter
}

Export-ModuleMember -Function new-SqlParam