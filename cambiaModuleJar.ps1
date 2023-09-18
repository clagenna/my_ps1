Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO
Add-Type -AssemblyName System.XML
Add-Type -AssemblyName PresentationFramework


$DebugPreference = "continue"
$ErrorActionPreference = "stop"
$WarningPreference = "stop"

$DesignCode = @"
/// <summary>
///  Required designer variable.
/// </summary>
private System.ComponentModel.IContainer components = null;

/// <summary>
///  Clean up any resources being used.
/// </summary>
/// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
protected override void Dispose(bool disposing)
{
    if (disposing && (components != null))
    {
        components.Dispose();
    }
    base.Dispose(disposing);
}

#region Windows Form Designer generated code

/// <summary>
///  Required method for Designer support - do not modify
///  the contents of this method with the code editor.
/// </summary>
private void InitializeComponent()
{
    this.lbJar = new System.Windows.Forms.Label();
    this.txFileJar = new System.Windows.Forms.TextBox();
    this.lbNamePrj = new System.Windows.Forms.Label();
    this.txModName = new System.Windows.Forms.TextBox();
    this.btAddPrj = new System.Windows.Forms.Button();
    this.btCerca = new System.Windows.Forms.Button();
    this.SuspendLayout();
    // 
    // lbJar
    // 
    this.lbJar.AutoSize = true;
    this.lbJar.Location = new System.Drawing.Point(51, 17);
    this.lbJar.Name = "lbJar";
    this.lbJar.Size = new System.Drawing.Size(42, 15);
    this.lbJar.TabIndex = 0;
    this.lbJar.Text = "File Jar";
    // 
    // txFileJar
    // 
    this.txFileJar.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
    | System.Windows.Forms.AnchorStyles.Right)));
    this.txFileJar.Location = new System.Drawing.Point(100, 13);
    this.txFileJar.Name = "txFileJar";
    this.txFileJar.Size = new System.Drawing.Size(326, 23);
    this.txFileJar.TabIndex = 1;
    // 
    // lbNamePrj
    // 
    this.lbNamePrj.AutoSize = true;
    this.lbNamePrj.Location = new System.Drawing.Point(8, 50);
    this.lbNamePrj.Name = "lbNamePrj";
    this.lbNamePrj.Size = new System.Drawing.Size(84, 15);
    this.lbNamePrj.TabIndex = 2;
    this.lbNamePrj.Text = "Nome Module";
    // 
    // txModName
    // 
    this.txModName.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
    | System.Windows.Forms.AnchorStyles.Right)));
    this.txModName.Location = new System.Drawing.Point(100, 46);
    this.txModName.Name = "txModName";
    this.txModName.Size = new System.Drawing.Size(326, 23);
    this.txModName.TabIndex = 3;
    // 
    // btAddPrj
    // 
    this.btAddPrj.Enabled = false;
    this.btAddPrj.Location = new System.Drawing.Point(100, 88);
    this.btAddPrj.Name = "btAddPrj";
    this.btAddPrj.Size = new System.Drawing.Size(75, 23);
    this.btAddPrj.TabIndex = 4;
    this.btAddPrj.Text = "Aggiungi";
    this.btAddPrj.UseVisualStyleBackColor = true;
    // 
    // btCerca
    // 
    this.btCerca.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
    this.btCerca.Location = new System.Drawing.Point(437, 14);
    this.btCerca.Name = "btCerca";
    this.btCerca.Size = new System.Drawing.Size(75, 23);
    this.btCerca.TabIndex = 5;
    this.btCerca.Text = "Cerca ...";
    this.btCerca.UseVisualStyleBackColor = true;
    // 
    // fmChiediJar
    // 
    this.AutoScaleDimensions = new System.Drawing.SizeF(7F, 15F);
    this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
    this.ClientSize = new System.Drawing.Size(609, 125);
    this.Controls.Add(this.btCerca);
    this.Controls.Add(this.btAddPrj);
    this.Controls.Add(this.txModName);
    this.Controls.Add(this.lbNamePrj);
    this.Controls.Add(this.txFileJar);
    this.Controls.Add(this.lbJar);
    this.Name = "fmChiediJar";
    this.Text = "Aggiungi Module Name to MANIFEST.MF";
    this.ResumeLayout(false);
    this.PerformLayout();

}

#endregion

private System.Windows.Forms.Label lbJar;
private System.Windows.Forms.TextBox txFileJar;
private System.Windows.Forms.Label lbNamePrj;
private System.Windows.Forms.TextBox txModName;
private System.Windows.Forms.Button btAddPrj;
private System.Windows.Forms.Button btCerca;
"@

function cercaFile() {
    $props = @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') } 
    $props.MultiSelect = $false
    $props.Filter = 'Jar Files (*.jar)|*.jar'
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property $props
    $null = $FileBrowser.ShowDialog()
    $szFile = $FileBrowser.FileName
    Write-Host ("File=" + $szFile)
    return $szFile
}
function removeBackup() {
    if ( $null -eq $Script:fileJarBak) {
        return
    }
    if ( Test-Path -Path $Script:fileJarBak ) {
        Remove-Item $Script:fileJarBak -Force
    }
}
function aggiungiModName($modn) {
    Write-Host "Chiamata Add con:"+$modn
    $autom = ("{0}: {1}" -f $Script:autModN, $Script:modName )
    $Script:fileJarBak = "{0}_{1}" -f $Script:fileJar, (Get-Date -f yyyyMMdd_HHmmss)
    Copy-Item -Path $Script:fileJar -Destination $Script:fileJarBak -Force
    $posf = -1
    Try {
        $zip = [IO.Compression.ZipFile]::Open($Script:fileJar, "Update")
        $entries = $zip.Entries.Where({$_.name -like 'MANIFEST.MF'})
        foreach ($entry in $entries) {
            $reader = [System.IO.StreamReader]::new($entry.Open())
            $contenuto = $reader.ReadToEnd()
            $reader.Dispose()
            $posf = $contenuto.IndexOf($Script:autModN)
            if ( $posf -le 1 ) {
                $arr = $contenuto.Split("`n")
                $nu = 0
                $writer = [System.IO.StreamWriter]::new($entry.Open())
                $writer.BaseStream.SetLength(0)
                foreach ( $riga in $arr ) {
                    if ( $nu++ -eq 2 ) {
                        $writer.Write("{0}`n" -f $autom)
                    }
                    $writer.Write("{0}`n" -f $riga)
                }
                $writer.Dispose()
            } else {
                removeBackup
                $szMsg = "Il MANIFEST.MF contiene gia' {0}" -f $Script:autModN
                [System.Windows.MessageBox]::Show($szMsg, "Attenzione", "Ok", 'Warning')
            } 
        }
        if ( $posf -le 1 ) {
            $szMsg = "Aggiunto `"{0}`" in MANIFEST.MF`ndel jar {1}" -f $autom, $Script:fileJar
            [System.Windows.MessageBox]::Show($szMsg, "Update di JAR", "Ok", 'Info')
            removeBackup
        }
    } catch {
        Write-Warning $_.Exception.Message
        $szMsg = "Errore su Zip {0} `nExc:{1}" -f $Script:fileJar,$_.Exception.Message
        [System.Windows.MessageBox]::Show($szMsg, "Attenzione", "Ok", 'Warning')
    } finally {
        if ( $zip ) {
            $zip.Dispose()
        }
    }

}

function testaVariabili() {
    if ( $null -eq $Script:fileJar -or  ! (Test-Path $Script:fileJar)) {
        [System.Windows.MessageBox]::Show("Non esiste "+ $Script:fileJar,"Attenzione","Ok", 'Warning')
        return $false
    }
    if ( $null -eq $Script:modName -or $Script:modName.Length -lt 4) {
        [System.Windows.MessageBox]::Show("Non hai specificato il nome Modulo","Attenzione","Ok", 'Warning')
        return $false
    }
    return $true
}

$InitCode = @"
	public frmCambiaModule()
	{
		InitializeComponent();
	}
"@

$FormCode="public class frmCambiaModule : System.Windows.Forms.Form { "+$DesignCode+$InitCode+"}";	
$Assembly = ( 
	"System.Windows.Forms",
	"System.Drawing",
	"System.Drawing.Primitives",
    "System.ComponentModel.Primitives"
)

# ### Form frmCambiaModule
Add-Type -ReferencedAssemblies $Assembly -TypeDefinition $FormCode -Language CSharp  
$form = New-Object frmCambiaModule
$form.ClientSize = New-Object System.Drawing.Size(553, 164)
$form.Text = "Cambia Automatic Module Name in MANIFEST.MF"
# ### My data
$Script:fileJar = $null
$Script:fileJarBak = $null
$Script:modName = $null
$Script:autModN = 'Automatic-Module-Name'
# ### controls 
$txFileJar = $form.Controls['txFileJar']
$txFileJar.Add_TextChanged({
    $sz = $txFileJar.Text
    $Script:fileJar = $sz
    checkBottone
})
$txModNam  = $form.Controls['txModName']
$txModNam.Add_TextChanged({
    $sz = $txModNam.Text
    $Script:modName = $sz
    checkBottone
})

function checkBottone() {
  # $szMsg = "jar:`"{0}`" modn:`"{1}`"" -f $Script:fileJar, $Script:modName
  # Write-Host $szMsg
  $bena = $null -ne $Script:fileJar -and $Script:fileJar.Length -gt 5
  if ( $bena) {
    $bena = $null -ne $Script:modName -and $Script:modName.Length -gt 4 
  }
  $btAddPrj.Enabled = $bena
}

$btCerca  = $form.Controls['btCerca']
$btAddPrj = $form.Controls['btAddPrj']
$btCerca.Add_click({
    $sz = cercaFile
    $txFileJar.Text = $sz
    $Script:fileJar = $sz
})
$btAddPrj.Add_click({
    if ( ! (testaVariabili) ) {
      return
    }
    aggiungiModName 
})
$form.showDialog() | Out-Null

if ( $null -ne $form )  {
    $form.Close()
    $form.Dispose()
    $form = $null
}
