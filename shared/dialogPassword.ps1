$Script:passwd = $null
function richiediPasswd() {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = "Form per l'introduzione di una password"
    $objForm.Size = New-Object System.Drawing.Size(300,200) 
    $objForm.StartPosition = "CenterScreen"
    $objForm.KeyPreview = $True
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter")   {$Script:passwd=$MaskedTextBox.Text;$objForm.Close()}})
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape")  {$objForm.Close()}})

    $objLabel = New-Object System.Windows.Forms.Label
    $objLabel.Location = New-Object System.Drawing.Size(10,20) 
    $objLabel.Size = New-Object System.Drawing.Size(280,20) 
    $objLabel.Text = "Digita la password qui di seguito:"
    $objForm.Controls.Add($objLabel) 

    $MaskedTextBox = New-Object System.Windows.Forms.MaskedTextBox
    $MaskedTextBox.PasswordChar = '*'
    $MaskedTextBox.Location = New-Object System.Drawing.Size(10,40) 
    $MaskedTextBox.Size = New-Object System.Drawing.Size(260,20) 
    $objForm.Controls.Add($MaskedTextBox) 

    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(75,120)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = "OK"
    $OKButton.Add_Click( {    $Script:passwd=$MaskedTextBox.Text;  $objForm.Close() } )
    $objForm.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(150,120)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click({$objForm.Close()})
    $objForm.Controls.Add($CancelButton)


    $objForm.Topmost = $True
    $objForm.Add_Shown({$objForm.Activate()})
    [void] $objForm.ShowDialog()
    return $Script:passwd
}
$a = richiediPasswd
Write-Host "Hai scritto: $($a)"

