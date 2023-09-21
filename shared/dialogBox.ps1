[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$computer = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a computer name", "Computer", "$env:computername")
Write-Host "Hai scritto : $computer"
# fintanto che va
