#
# Manifesto per il modulo 'chiamaSsh'
#
# Generato da: Claudio Gennari
#
# Generato in data: 27/03/2020
#

@{

# File del modulo di script o del modulo binario associato a questo manifesto.
RootModule = 'chiamaSsh.psm1'

# Numero di versione del modulo.
ModuleVersion = '1.0'

# Edizioni di PS supportate
# CompatiblePSEditions = @()

# ID utilizzato per identificare in modo univoco il modulo
GUID = '0e86b680-d3df-492e-b394-18c0121f9031'

# Autore del modulo
Author = 'Claudio Gennari'

# Società o fornitore del modulo
CompanyName = 'CisCOOP'

# Informazioni sul copyright per il modulo
Copyright = '(c) 2020 Claudio Gennari. Tutti i diritti riservati.'

# Descrizione delle funzionalità offerte dal modulo
Description = 'My chiamaSsh module'

# Versione minima del motore di Windows PowerShell necessaria per il modulo
PowerShellVersion = '3.0'

# Nome dell'host di Windows PowerShell richiesto dal modulo
# PowerShellHostName = ''

# Versione minima dell'host di Windows PowerShell richiesta dal modulo
# PowerShellHostVersion = ''

# Versione minima di Microsoft .NET Framework richiesta dal modulo. Questo prerequisito è valido solo per l'edizione Desktop di PowerShell.
# DotNetFrameworkVersion = ''

# Versione minima di Common Language Runtime (CLR) richiesta dal modulo. Questo prerequisito è valido solo per l'edizione Desktop di PowerShell.
# CLRVersion = ''

# Architettura del processore (None, X86, Amd64, IA64) richiesta dal modulo
# ProcessorArchitecture = ''

# Moduli che devono essere importati nell'ambiente globale prima di importare il modulo
# RequiredModules = @()

# Assembly che devono essere caricati prima di importare il modulo
# RequiredAssemblies = @()

# File script (ps1) eseguiti nell'ambiente del chiamante prima di importare il modulo.
# ScriptsToProcess = @()

# File di tipi (ps1xml) da caricare al momento dell'importazione del modulo
# TypesToProcess = @()

# File di formato (ps1xml) da caricare al momento dell'importazione del modulo
FormatsToProcess = @()

# Moduli da importare come moduli annidati del modulo specificato in RootModule/ModuleToProcess
# NestedModules = @()

# Funzioni da esportare dal modulo. Per ottenere prestazioni ottimali, non usare caratteri jolly e non eliminare la voce. Usare una matrice vuota se non sono presenti funzioni da esportare.
FunctionsToExport = @( 'get-sshText', 'Invoke-miossh',  'find-filechiave',  'clear-filechiave' )

# Cmdlet da esportare dal modulo. Per ottenere prestazioni ottimali, non usare caratteri jolly e non eliminare la voce. Usare una matrice vuota se non sono presenti cmdlet da esportare.
CmdletsToExport = @()

# Variabili da esportare dal modulo
VariablesToExport = @()

# Alias da esportare dal modulo. Per ottenere prestazioni ottimali, non usare caratteri jolly e non eliminare la voce. Usare una matrice vuota se non sono presenti alias da esportare.
AliasesToExport = @()

# Risorse DSC da esportare da questo modulo
# DscResourcesToExport = @()

# Elenco di tutti i moduli inclusi nel modulo
# ModuleList = @()

# Elenco di tutti i file inclusi nel modulo
# FileList = @()

# Dati privati da passare al modulo specificato in RootModule/ModuleToProcess. Può inoltre includere una tabella hash PSData con altri metadati del modulo utilizzati da PowerShell.
PrivateData = @{

    PSData = @{

        # Tag applicati al modulo per semplificarne l'individuazione nelle raccolte online.
        # Tags = @()

        # URL della licenza di questo modulo.
        # LicenseUri = ''

        # URL del sito Web principale per questo progetto.
        # ProjectUri = ''

        # URL di un'icona che rappresenta questo modulo.
        # IconUri = ''

        # Note sulla versione di questo modulo
        # ReleaseNotes = ''

    } # Fine della tabella hash PSData

} # Fine della tabella hash PrivateData

# URI HelpInfo del modulo
# HelpInfoURI = ''

# Prefisso predefinito per i comandi esportati da questo modulo. Per sostituire il prefisso predefinito, utilizzare Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

