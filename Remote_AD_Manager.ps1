#Activation du module Active-Directory
Import-Module ActiveDirectory

if (!(Test-Path -Path C:\TEMP)) {
    New-Item -Path "C:\" -name "TEMP" -itemtype Directory > $null
    New-SmbShare -Name "TEMP" -Path "C:\TEMP"  -FullAccess "Tout le monde"
}

function PoserQuestion($p_question) {
    do {          
        $saisie = Read-Host "$p_question"
    }while ($saisie -eq "")
    return $saisie.Trim()
}

function TesterConnexion {
    param($computer,
        $port) 
    if ($port -eq "$null") {
        return Test-Connection -ComputerName $computer -count 1 -erroraction silentlycontinue       
    }
    else {
        return Test-NetConnection -computername $computer -Port $port | where-object { $_.TcpTestSucceeded -eq $true } -erroraction silentlycontinue
    }
} 

function Journalisation {
    param([string]$message)
    $date = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    Add-Content -Path $cheminLog -Value "$date $message"
}

function ObtenirMotDePasse {
    return ConvertTo-SecureString -String $passTemp -AsPlainText -Force
}

function VerifierOU {
    param($nom)
    return Get-ADOrganizationalUnit -Filter { Name -eq $nom }
}

function VerifierUtilisateur {
    param([string]$id)
    return Get-ADUser -Filter * | Where-Object { $_.SamAccountName -eq $id }
}

function VerifierGroupe {
    param($groupe)
    return Get-ADGroup -Filter * | Where-Object { $_.Name -eq $groupe }
}

function ReninitialiserMotDePasse {
    param($utilisateur)
    $Password = ObtenirMotDePasse
    Set-ADAccountPassword -Identity $utilisateur -NewPassword $Password -Reset -verbose
    Set-ADUser -Identity $utilisateur -ChangePasswordAtLogon $true
    if ($?) {
        Write-Host "Le mot de passe $passTemp de $utilisateur sera changé à la prochaine connexion" -ForegroundColor magenta
    }
}

function RecupererUserDansGroupe {
    param($groupe)
    $adUser = @()
    $id = Get-ADGroupMember -Identity $groupe | Select-Object -Property SamAccountName
    foreach ($user in $id) {
        $adUser += $($user.SamAccountName)
    }
    return $adUser
}

function ExporterUtilisateur {
    param($utilisateurs)
    $utilisateurs | Export-Csv -Path $cheminCsvUser -NoTypeInformation
    foreach ($utilisateur in $utilisateurs) {
        if ($?) { Journalisation "[STANDARD] exportation de l'utilisateur $($utilisateur.SamAccountName)" }
        else { Journalisation "[ERREUR] Echec de l'exportation de l'utilisateur $($utilisateur.SamAccountName)" }
    }
}

function ExporterGroupe {
    param([array]$utilisateurs,
        [array]$groupes)
    $utilisateurs | Export-Csv -Path $cheminCsvGroup -NoTypeInformation
    foreach ($groupe in $groupes) {
        if ($?) { Journalisation "[STANDARD] exportation du groupe $groupe" }
        else { Journalisation "[ERREUR] Echec de l'exportation du groupe $groupe" }
    }
}

function ObtenirADUser {
    param($utilisateurs,
        $groupe = 0,
        $OU = 0)
    $resultat = @()
    foreach ($utilisateur in $utilisateurs) {
        $adUser = Get-ADUser -Identity $utilisateur -Properties GivenName, Name, SamAccountName, Surname
        $resultat += [PSCustomObject]@{
            GivenName      = $adUser.GivenName
            Name           = $adUser.Name
            SamAccountName = $adUser.SamAccountName
            Surname        = $adUser.Surname
            Group          = $groupe
            OU             = $OU
        }      
    }
    return $resultat
}

function AccederHoteDistant {
    $Username = $account
    $Password = ConvertTo-SecureString $accountPassword -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
    Enable-PSRemoting -force
    $session = New-PSSession -ComputerName $hoteDistant -Credential ($Credential)
    return $session
}

function AfficherListeUtilisateur {
    $liste = ObtenirTousLesUtilisateurs
    Write-Host "*****LISTE*****"
    foreach ($id in $liste) {
        Write-Host $($id.SamAccountName)
    }
    Write-Host ""
}

function ObtenirTousLesUtilisateurs {
    return Get-ADUser -Filter * | Where-Object { 
        $_.samAccountName -notlike '*$*' -and
        $_.samAccountName -notlike 'krbtgt' -and
        $_.samAccountName -notlike 'Administrat*' -and
        $_.samAccountName -notlike 'Invit*'
    }
}

function AfficherListeGroupe {
    $liste = Get-ADGroup -filter * | Select-Object name
    Write-Host "*****LISTE*****"
    foreach ($nom in $liste) {
        Write-Host $($nom.Name)
    }
    Write-Host ""
}

function AfficherListeOU {
    $liste = Get-ADOrganizationalUnit -Filter * -SearchBase $domaine  | Where-Object { $_.name -notlike 'Domain Controllers' } | Select-object name
    Write-Host "*****LISTE*****"
    foreach ($ou in $liste) {
        Write-Host $($ou.Name)
    }
    Write-Host ""
}

function RecupererNomDomaine { 
    $dc = Get-ADDomainController -Discover -Service PrimaryDC
    $nom = $dc.Domain
    return $nom
}

function RecupererParties {
    param($nom)
    $parties = @()
    $partie = $nom.split(".")
    for ($i = 0; $i -lt $partie.Count; $i++) {
        $parties += $partie[$i]
    }
    return $parties
}

function RecupererCheminDomaine {
    $nomDomaine = RecupererNomDomaine
    $parties = RecupererParties $nomDomaine
    $nom = $parties[0]
    $ext = $parties[1]
    return "DC=$nom,DC=$ext"
}
    
function AfficherSousMenu {
    Write-Host ""
    Write-Host "REINITIALISER LE MOT DE PASSE"
    Write-Host "[1] D'un utilisateur"
    Write-Host "[2] D'un groupe"                                    
    Write-Host "[3] D'une OU"                         
    Write-Host "[Q] Quitter"
    Write-Host ""                                                               
}

function AfficherMenu {
    Write-Host ""
    Write-Host "********************************************************"
    Write-Host "* [1] Afficher le contenu du fichier de journalisation *"
    Write-Host "* [2] Tester une connexion à un ordinateur distant     *"                                    
    Write-Host "* [3] Réinitialiser les mots de passe                  *"                         
    Write-Host "* [4] Exporter une ou plusieurs OU                     *"
    Write-Host "* [5] Exporter un ou plusieurs groupe(s)               *"
    Write-Host "* [6] Exporter un ou plusieurs utilisateur(s)          *"
    Write-Host "* [Q] Quitter                                          *"
    Write-Host "********************************************************"
    Write-Host ""                                                               
}

#Definition des variables global
$global:hoteDistant = "SRV3.enfant.script.lan"
$global:cheminCsvGroup = "C:\TEMP\exportGroup.csv" #Doit etre dans C:\TEMP
$global:cheminCsvUser = "C:\TEMP\exportUser.csv" #Doit etre dans C:\TEMP   
$global:cheminLog = "C:\TEMP\journal.log" #Doit etre dans C:\TEMP
$global:passTemp = "Bonjour1*"
$global:account = "Administrateur"
$global:accountPassword = "Passw0rd"
$global:domaine = RecupererCheminDomaine

Clear-Host
do {
    AfficherMenu
    $verification = $false
    $choix = PoserQuestion "Entrer votre choix"
    
    #Initialisation des variables
    $utilisateurs = $null
    $port = $null

    Switch ("$choix") {
        "1" {
            #Afficher le contenu du fichier de journalisation
            Get-Content -Path $cheminLog
            Pause
            Clear-Host            
        }

        "2" {
            #Tester une connexion à un ordinateur distant           
            $computer = PoserQuestion "Entrer le nom de domaine ou l'adresse ip a tester"
            $port = Read-Host "Entrer le port a tester [Entree pour quitter]"
            $resultat = TesterConnexion $computer $port
            if ($port -eq "") {
                if ($resultat) {
                    Journalisation "[STANDARD] Test de connexion a $computer"
                    write-Host "Connexion a l'hote $computer REUSSI" -ForegroundColor green       
                
                }
                else {
                    Journalisation "[ERREUR] Echec du test de la connexion a $computer"
                    write-Host "Connexion a l'hote $computer ECHOUEE" -ForegroundColor red
                }
            }

            else {
                if ($resultat) {
                    Journalisation "[STANDARD] Test de connexion a $computer sur le port $port"
                    write-Host "Connexion a l'hote $computer sur le port $port REUSSI" -ForegroundColor green       
                }
                else {
                    Journalisation "[ERREUR] Echec du test de la connexion a $computer sur le port $port"
                    write-Host "Connexion a l'hote $computer sur le port $port ECHOUEE" -ForegroundColor red
                }
            }
        }                          

        "3" {
            #Réinitialiser les mots de passe (utilisateur, groupe ou OU)                  
            do {
                AfficherSousMenu
                $choix2 = PoserQuestion "Entrer votre choix"
                $verification = $false
                Write-Host ""

                Switch ("$choix2") {
                    "1" {
                        #Utilisateurs
                        while (!$verification) {    
                            $utilisateur = PoserQuestion "Entrer l'identifiant de l'utilisateur ['*' Afficher liste]"
                            if ($utilisateur -eq "*") { AfficherListeUtilisateur }
                            elseif (VerifierUtilisateur $utilisateur) {
                                ReninitialiserMotDePasse $utilisateur
                                if ($?) {
                                    Journalisation "[STANDARD] Réinitialisation du mot de passe de $utilisateur"
                                }
                                else {
                                    Journalisation "[ERREUR] Echec de la réinitialisation du mot de passe de $utilisateur"
                                }
                                $verification = $true
                            }
                            else {
                                Write-Host "ERREUR : L'utilisateur $utilisateur n'existe pas." -ForegroundColor red
                            }
                        }
                    }

                    "2" {
                        #Goupes
                        while (!$verification) { 
                            $groupe = PoserQuestion "Entrer le nom du groupe ['*' Afficher liste]"
                            if ($groupe -eq "*") { AfficherListeGroupe }
                            elseif (VerifierGroupe $groupe) {
                                $membres = Get-ADGroupMember -Identity $groupe
                                if ($membres.Count -eq 0) {
                                    Write-Host "ERREUR : Le groupe $groupe est vide." -ForegroundColor red
                                }
                                else {
                                    foreach ($membre in $membres) {           
                                        ReninitialiserMotDePasse $($membre.SamAccountName)
                                        if ($?) {
                                            Journalisation "[STANDARD] Réinitialisation du mot de passe de $($membre.Name)"
                                        }
                                        else {
                                            Journalisation "[ERREUR] Echec de la réinitialisation du mot de passe de $($membre.Name)"
                                        }
                                    }
                                    $verification = $true 
                                }                                           
                            }
                            else {
                                Write-Host "ERREUR : Le groupe $groupe n'existe pas." -ForegroundColor red
                            }
                        }
                    }

                    "3" {
                        #OU
                        while (!$verification) { 
                            $OU = PoserQuestion "Entrer le nom de l'OU ['*' Afficher liste]"
                            $OUPath = "OU=$OU,$domaine"
                            if ($OU -eq "*") { AfficherListeOU }
                            elseif (VerifierOU $OU) {
                                $OU = Get-ADUser -Filter * -SearchBase $OUPath
                                $ADUser = Get-ADUser -Filter * -SearchBase $OUPath | Select-Object SamAccountName
                                
                                #Verifie si l'OU est vide
                                if ($ADUser.Count -eq 0) {
                                    Write-Host "ERREUR : L'OU est vide" -ForegroundColor Red
                                }
                                else {
                                    foreach ($user in $OU) { 
                                        ReninitialiserMotDePasse $($user.SamAccountName)
                                        if ($?) {
                                            Journalisation "[STANDARD] Réinitialisation du mot de passe de $($user.Name)"
                                        }
                                        else {
                                            Journalisation "[ERREUR] Echec de la réinitialisation du mot de passe de $($user.Name)"
                                        }
                                    }
                                    $verification = $true
                                }
                            }
                            else {
                                Write-Host "ERREUR : L'OU $OU n'existe pas." -ForegroundColor red
                            }
                        }
                    }

                    "Q" { 
                        if ($choix2 -ceq "q") { Write-verbose "Saisir 'Q' majuscule pour quitter." -verbose }
                    }

                    Default { Write-Host "ERREUR : Saisir un chiffre entre 1 et 3 ou 'Q' pour quitter." -ForegroundColor red }
                }
            }while ($choix2 -cne "Q") 
        }

        "4" {
            #Exporter une ou plusieurs OU
            while (!$verification) {
                $Demarrage = $false
                $ADUser = @()
                $ADGroup = @()
                $resultat = @()
                $utilisateurs = @() 

                $nomOU = PoserQuestion "Entrez le nom de l'OU à exporter ['*' Afficher liste, 'Q' Quitter]"

                switch ($nomOU) {
                    "Q" { $verification = $true }
                    "*" { AfficherListeOU }
                    default {
                        if (VerifierOU $nomOU) {
                            $OU = "OU=$nomOU,$domaine"
                            $ADUser = Get-ADUser -Filter * -SearchBase $OU | Select-Object SamAccountName
                            $ADGroup = Get-ADGroup -Filter * -SearchBase $OU | Select-Object SamAccountName
                            
                            if ($ADUser.Count -eq 0 -and $ADGroup.Count -eq 0) {
                                Write-Host "ERREUR : L'OU est vide" -ForegroundColor Red
                            }
                            else { $Demarrage = $true }
                        }
                        else {
                            Write-Host "ERREUR : L'OU n'existe pas" -ForegroundColor Red             
                        }
                    }
                }
          
                #Demarrage de la procedure d'exportation
                if ($Demarrage -eq $true) { 

                    #Exportation des groupes
                    foreach ($groupe in $ADGroup) {
                        $nomGroupe = "$($groupe.SamAccountName)"
                        $utilisateurs = RecupererUserDansGroupe $nomGroupe
                        $resultat += ObtenirADUser $utilisateurs $nomGroupe $nomOU
                        $groupes += ($groupe.SamAccountName)
                    } 
                    ExporterGroupe $resultat $groupes

                    #Exportation des utilisateurs seuls
                    $utilisateurs = @()
                    foreach ($user in $ADUser) {
                        $utilisateurs += "$($user.SamAccountName)"
                    }
                    $resultat = ObtenirAdUser $utilisateurs $null $nomOU
                    ExporterUtilisateur $resultat

                    #Demarrage de la procedure d'importation                   
                    $session = AccederHoteDistant
                    if ($?) {
                        Write-Host "Connexion à l'hote distant $hoteDistant REUSSI" -ForegroundColor green
                        Journalisation "[STANDARD] Connexion a l'hôte  distant $hoteDistant"
                    }
                    else { Journalisation "[ERREUR] Echec de la connexion à l'hôte distant $hoteDistant" }
                    Invoke-Command -Session $session -ScriptBlock {
                        $date = Get-Date -Format "yyyy/MM/dd HH:mm:ss"

                        #Importation des utilisateurs seuls
                        $csv = Import-Csv "\\SRV1\TEMP\exportUser.csv"
                        foreach ($user in $csv) {               
                            $prenom = $($user.GivenName)                   
                            $nomComplet = $($user.Name)
                            $id = $($user.SamAccountName)
                            $nom = $($user.Surname)
                            $OU = $($user.OU)
                                        
                            #Verifier si l'OU existe
                            if (!(Get-ADOrganizationalUnit -Filter { Name -eq $OU })) {
                                New-ADOrganizationalUnit -name $OU -Path "DC=enfant,DC=script,DC=lan"
                                if ($?) {
                                    Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [STANDARD] Importation de l'OU $OU sur 'SRV3.enfant.script.lan'"
                                }
                                else {
                                    Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] Echec de l'importation de de l'OU $OU sur 'SRV3.enfant.script.lan'"
                                }  
                            }

                            #Verifier si l'utilisateur existe
                            $user = Get-ADUser -Filter { SamAccountName -eq $id }
                            if (!$user) {
                                New-ADUser -GivenName $prenom -Name $nomComplet -SamAccountName $id -Surname $nom -Path "OU=$OU,DC=enfant,DC=script,DC=lan" -AccountPassword (ConvertTo-SecureString "Bonjour1*" -AsPlainText -Force) -PasswordNeverExpires $false -ChangePasswordAtLogon $true -Enabled $true -Description "Utilisateur ajouté avec le script Powershell TPSynthese" -verbose                                                                                     
                                if ($?) {
                                    Write-Host "Le mot de passe Bonjour1* de $id sera changé à la prochaine connexion" -ForegroundColor magenta
                                    Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [STANDARD] Importation de l'utilisateur $id sur 'SRV3.enfant.script.lan'"
                                }
                                else {
                                    Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] Echec de l'importation de l'utilisateur $id sur 'SRV3.enfant.script.lan'"
                                }   
                            } 

                            #Si l'utilisateur existe mais n'est pas dans l'OU, le deplacer dans l'OU
                            elseif (($user.DistinguishedName -notlike "*OU=$OU,DC=enfant,DC=script,DC=lan*")) {
                                Get-ADUser -Identity $id | Move-ADObject -TargetPath "OU=$OU,DC=enfant,DC=script,DC=lan" -verbose
                                if ($?) {
                                    Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [STANDARD] Déplacement de l'utilisateur $id dans l'OU $OU sur 'SRV3.enfant.script.lan'"
                                }
                                else {
                                    Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] Echec du déplacement de l'utilisateur $id dans l'OU $OU sur 'SRV3.enfant.script.lan'"
                                }   
                            }

                            else {
                                Write-host "ERREUR : L'utilisateur $id est déjà dans l'OU $OU" -ForegroundColor red
                                Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] L'utilisateur $id est déjà dans l'OU $OU sur 'SRV3.enfant.script.lan'"
                            }
                        }

                        #Importation des groupes
                        $csv = Import-Csv "\\SRV1\TEMP\exportGroup.csv"
                        foreach ($user in $csv) {               
                            $prenom = $($user.GivenName)                   
                            $nomComplet = $($user.Name)
                            $id = $($user.SamAccountName)
                            $nom = $($user.Surname)
                            $groupe = $($user.Group)
                            $OU = $($user.OU)

                            #Verifier si le groupe existe
                            $group = Get-ADGroup -Filter { Name -eq $groupe }
                            if (!$group) { 
                                New-ADGroup -Name $groupe -Path "OU=$OU,DC=enfant,DC=script,DC=lan" -GroupScope Global -Description "Groupe ajouté avec le script Powershell TPSynthese" -verbose
                                if ($?) {
                                    Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [STANDARD] Importation du groupe $groupe sur 'SRV3.enfant.script.lan'"
                                }
                                else {
                                    Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] Echec de l'importation du groupe $groupe sur 'SRV3.enfant.script.lan'"
                                } 
                            }

                            #Si le groupe existe mais n'est pas dans l'OU, le deplacer dans l'OU
                            elseif (($group.DistinguishedName -notlike "*OU=$OU,DC=enfant,DC=script,DC=lan*")) {
                                Get-ADGroup -Identity $groupe | Move-ADObject -TargetPath "OU=$OU,DC=enfant,DC=script,DC=lan" -verbose
                                if ($?) {
                                    Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [STANDARD] Déplacement du groupe $groupe dans l'OU $OU sur 'SRV3.enfant.script.lan'"
                                }
                                else {
                                    Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] Echec du déplacement du groupe $groupe dans l'OU $OU sur 'SRV3.enfant.script.lan'"
                                }   
                            }
                            
                            else {
                                Write-host "ERREUR : Le groupe $groupe est déjà dans l'OU $OU" -ForegroundColor red
                                Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] Le groupe $groupe est déjà dans l'OU $OU sur 'SRV3.enfant.script.lan'"
                            }
                                        
                            #Verifier si l'utilisateur est déjà dans le groupe sinon l'ajouter
                            if (!(Get-ADGroupMember -Identity "$groupe" | Where-Object { $_.SamAccountName -eq $id })) {
                                Add-ADGroupMember -Identity "$groupe" -Members "$id" -verbose
                                if ($?) {
                                    Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [STANDARD] Ajout de l'utilisateur $id dans le groupe $groupe sur 'SRV3.enfant.script.lan'"
                                }
                                else {
                                    Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] Echec de l'ajout de l'utilisateur $id dans le groupe $groupe sur 'SRV3.enfant.script.lan'"
                                }
                            }
                        }
                    }#Fin de la procedure d'importation
                }
                    
                if ($demarrage -eq $true) {
                    Remove-PSSession -Session $session
                    if ($?) { 
                        Write-Host "Fin de la connexion" -ForegroundColor cyan
                        Journalisation "[STANDARD] Fin de la connexion à l'hôte distant $hoteDistant"
                    }
                }
            }#Fin de la boucle while                       
        }                      
     
        "5" {
            #Exporter un ou plusieurs groupe(s)
            $resultat = @()
            $utilisateurs = @()
            $groupes = @()
            while (!$verification) {
                $groupe = PoserQuestion "Entrez le nom du groupe à exporter ['*' Afficher liste, 'Q' Quitter]"
                
                switch ($groupe) {                   
                    "Q" { $verification = $true }
                    "*" { AfficherListeGroupe }
                    default { 
                        if (VerifierGroupe $groupe) {
                            if ((Get-ADGroupMember -Identity $groupe).count -eq 0) {
                                Write-Host "ERREUR : Aucun membre dans le groupe." -ForegroundColor red
                            }
                            else {
                                $groupes += $groupe  
                            }  
                        } 
                        else {
                            Write-Host "ERREUR : Le groupe $groupe n'existe pas." -ForegroundColor red 
                        }
                    }
                }
            } 

            #Demarrage de l'exportation
            if ($groupes -ne $null) {         
                foreach ($groupe in $Groupes) {
                    $utilisateurs = RecupererUserDansGroupe $groupe
                    $resultat += ObtenirADUser $utilisateurs $groupe
                }
                ExporterGroupe $resultat $groupes

                #Demarrage de la procedure d'importation
                $session = AccederHoteDistant
                if ($?) {
                    Write-Host "Connexion à l'hote distant $hoteDistant REUSSI" -ForegroundColor green
                    Journalisation "[STANDARD] Connexion a l'hôte  distant $hoteDistant"
                }
                
                else { Journalisation "[ERREUR] Echec de la connexion à l'hôte distant $hoteDistant" }
                Invoke-Command -Session $session -ScriptBlock {
                    $date = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
                    $csv = Import-Csv "\\SRV1\TEMP\exportGroup.csv"
                    foreach ($user in $csv) {               
                        $prenom = $($user.GivenName)                   
                        $nomComplet = $($user.Name)
                        $id = $($user.SamAccountName)
                        $nom = $($user.Surname)
                        $groupe = $($user.Group)
                                    
                        #Verifier si l'utilisateur existe                                                                                                                                                     
                        if (!(Get-ADUser -Filter { SamAccountName -eq $id })) {
                            New-ADUser -GivenName $prenom -Name $nomComplet -SamAccountName $id -Surname $nom -AccountPassword (ConvertTo-SecureString "Bonjour1*" -AsPlainText -Force) -PasswordNeverExpires $false -ChangePasswordAtLogon $true -Enabled $true -Description "Utilisateur ajouté avec le script Powershell TPSynthese" -verbose                                                                                     
                            if ($?) {
                                Write-Host "Le mot de passe Bonjour1* de $id sera changé à la prochaine connexion" -ForegroundColor magenta
                                Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [STANDARD] Importation de l'utilisateur $id sur 'SRV3.enfant.script.lan'"
                            }
                            else {
                                Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] Echec de l'importation de l'utilisateur $id sur 'SRV3.enfant.script.lan'"
                            }   
                        }

                        #Verifier si le groupe existe
                        if (!(Get-ADGroup -Filter { Name -eq $groupe })) { 
                            New-ADGroup -Name $groupe -GroupScope Global -Description "Groupe ajouté avec le script Powershell TPSynthese" -verbose
                            if ($?) {
                                Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [STANDARD] Importation du groupe $groupe sur 'SRV3.enfant.script.lan'"
                            }
                            else {
                                Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] Echec de l'importation du groupe $groupe sur 'SRV3.enfant.script.lan'"
                            } 
                        }

                        #Verifier si l'utilisateur est déjà dans le groupe
                        if (!(Get-ADGroupMember -Identity "$groupe" | Where-Object { $_.SamAccountName -eq $id })) {
                            Add-ADGroupMember -Identity "$groupe" -Members "$id" -verbose
                            if ($?) {
                                Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [STANDARD] Ajout de l'utilisateur $id dans le groupe $groupe sur 'SRV3.enfant.script.lan'"
                            }
                            else {
                                Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] Echec de l'ajout de l'utilisateur $id dans le groupe $groupe sur 'SRV3.enfant.script.lan'"
                            }
                        }
                        else {
                            Write-host "ERREUR : L'utilisateur $id est déjà dans le groupe $groupe" -ForegroundColor red
                            Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] L'utilisateur $id est déjà dans le groupe $group sur 'SRV3.enfant.script.lan'"
                        }                                                                                        
                    }            
                }#Fin de la procedure d'importation
                Remove-PSSession -Session $session 

                if ($?) { 
                    Write-Host "Fin de la connexion" -ForegroundColor cyan
                    Journalisation "[STANDARD] Fin de la connexion à l'hôte distant $hoteDistant"
                }
            }       
        }           

        "6" {
            #Exporter un ou plusieurs utilisateur(s)               
            $resultat = @()
            $utilisateurs = @()
            while (!$verification) {

                $utilisateur = PoserQuestion "Entrez l'identifiant de l'utilisateur à exporter ['*' Afficher liste, 'T' Tous les utilisateurs, 'Q' Quitter]"  
                
                Switch ("$utilisateur") {
                    "Q" { $verification = $true }
                    "*" { AfficherListeUtilisateur }
                    "T" {
                        $utilisateurs = ObtenirTousLesUtilisateurs
                        $verification = $true
                    }
                    default { 
                        if (VerifierUtilisateur $utilisateur) {
                            $utilisateurs += $utilisateur
                        }
                        else {
                            Write-Host "ERREUR : L'utilisateur $utilisateur n'existe pas." -ForegroundColor red 
                        }
                    }
                }
            }
            
            #Demarrage de l'exportation
            if ($utilisateurs -ne $null) { 
                $resultat = ObtenirAdUser $utilisateurs
                ExporterUtilisateur $resultat
                
                #Demarrage de la procedure d'importation
                $session = AccederHoteDistant
                if ($?) {
                    Write-Host "Connexion à l'hote distant $hoteDistant REUSSI" -ForegroundColor green
                    Journalisation "[STANDARD] Connexion a l'hôte  distant $hoteDistant"
                }
                else { Journalisation "[ERREUR] Echec de la connexion à l'hôte distant $hoteDistant" }
                Invoke-Command -Session $session -ScriptBlock {
                    $date = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
                    $csv = Import-Csv "\\SRV1\TEMP\exportUser.csv"
                    foreach ($user in $csv) {
                        $prenom = $($user.GivenName)                   
                        $nomComplet = $($user.Name)
                        $id = $($user.SamAccountName)
                        $nom = $($user.Surname)
                            
                        #Verifier si l'utilisateur existe
                        if (!(Get-ADUser -Filter { SamAccountName -eq $id })) {                                                                                                                                                                                                    
                            New-ADUser -GivenName $prenom -Name $nomComplet -SamAccountName $id -Surname $nom -AccountPassword (ConvertTo-SecureString "Bonjour1*" -AsPlainText -Force) -PasswordNeverExpires $false -ChangePasswordAtLogon $true -Enabled $true -Description "Utilisateur ajouté avec le script Powershell TPSynthese" -verbose                                                                                       
                            if ($?) {
                                Write-Host "Le mot de passe Bonjour1* sera changé à la prochaine connexion" -ForegroundColor magenta
                                Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [STANDARD] Importation de l'utilisateur $id sur 'SRV3.enfant.script.lan'"
                            }
                            else {
                                Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] Echec de l'importation de l'utilisateur $id sur 'SRV3.enfant.script.lan'"
                            }
                        }
                        else {
                            Write-host "ERREUR : L'utilisateur $id existe déjà" -ForegroundColor red
                            Add-Content -Path "\\SRV1\TEMP\journal.log" -Value "$date [ERREUR] L'utilisateur $id existe déjà sur 'SRV3.enfant.script.lan'"
                        }
                    }       
                }#Fin de la procedure d'importation
                Remove-PSSession -Session $session 

                if ($?) { 
                    Write-Host "Fin de la connexion" -ForegroundColor cyan
                    Journalisation "[STANDARD] Fin de la connexion à l'hôte distant $hoteDistant"
                }            
            }                 
        }
            
        "Q" { 
            if ($choix -ceq "q") { Write-verbose "Saisir 'Q' majuscule pour quitter." -verbose }
        }                    

        Default { Write-Host "ERREUR : Saisir un chiffre entre 1 et 6 ou 'Q' pour quitter." -ForegroundColor red }
    }

}while ($choix -cne "Q")