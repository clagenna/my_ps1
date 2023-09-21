@{
RootModule = 'utilsAD.psm1'
ModuleVersion = '1.2.3'
GUID = '69ab55d2-2f9b-4570-b148-e58515f582a5'
Author = 'Claudio Gennari'
CompanyName = 'Cis Coop Tecnologia'
Copyright = 'Copyright (c) Claudio Gennari. All rights reserved.'
Description = 'Libreria di gestione utilsAD'
PowerShellVersion = '3.0'
DotNetFrameworkVersion = '4.0'
FunctionsToExport = 'accorciaAdNome','accorciaDistName','calcolaIdOrgUFU','caricaEnteAziende','caricaTutteOUs','convertiDescrCodiss','decodificaEnte','getCredenziali','isOUDaScartare','isValue','new-OrganizationalUnitDaPass','normalizzaOUName','normalizzaSamAccountName','out-OUsDaScartare','separaDescription','separaOUs'
CmdletsToExport = @()
AliasesToExport = @()
FileList = @( 'utilsAD.psm1', 'utilsAD.psd1')
PrivateData = @{
    PSData = @{
        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('AD', 'Linux', 'Unix', 'Cisco', 'Networking')
        ReleaseNotes = 'Un help per AD'
        # External dependent modules of this module
        # ExternalModuleDependencies = ''
    } # End of PSData hashtable
} # End of PrivateData hashtable
}

