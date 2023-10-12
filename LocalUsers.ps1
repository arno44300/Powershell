<#On creer au besoin le dossier TEMP qui servira a deposer nos fichiers
et on rend la manipulation muette afin de ne pas perturber l'utilisateur.#>
if(!(Test-Path -Path C:\TEMP)){
    New-Item -Path "C:\" -name "TEMP" -itemtype Directory > $null
}

[cmdletbinding()]

#Booleen qui servira a valider les sorties de boucles
$verification = $true

do{    
    function PoserQuestion($p_question){
        do{          
            $saisie = Read-Host "$p_question"
        }while($saisie -eq "")
    return $saisie
    }

    function PoserQuestion2Choix{
    [cmdletbinding()]
    param([string]$question,
            [string]$choix1,
            [string]$choix2)
        do{          
            $saisie = PoserQuestion "$question"
            if($saisie -ne $choix1 -and $saisie -ne $choix2){
                Write-Host "ERREUR : Entrer [O] pour oui [N] pour non." -ForegroundColor red
            }
        }while($saisie -ne $choix1 -and $saisie -ne $choix2)
    return $saisie
    }

    function VerifierGroupe($p_groupe){
        return Get-LocalGroup | Where-Object { $_.Name -eq $p_groupe }
    }

    function CreerGroupe{
    [cmdletbinding()]
    param([string]$groupe) 
        New-LocalGroup -Name $groupe -Description "Groupe ajouté avec le script Powershell TP1"
        if($?){
        Write-verbose "Le groupe $groupe a été créé avec succès !"
        Write-Host ""
        }
    }

    function VerifierUtilisateur{
    [cmdletbinding()]
    param([string]$nom)
    $verification = $true
        if(Get-LocalUser | Where-Object { $_.Name -eq $nom }){
            Write-Host "ERREUR : L'utilisateur $nom existe déjà." -ForegroundColor red
            $verification = $false
        }
    return $verification
    }
     
    <#La fonction dispose de deux options. La premiere avec le mot de passe generique importé depuis le fichier csv pour une création entierement automatique
    La deuxieme sans mot de passe pour une creation avec saisie manuelle pour chaque utilisateur.#>    
    function CreerUtilisateur{
    [cmdletbinding()]
            param(
            [string]$nom,
            [string]$pass = 0
        )
        if($pass -ne 0){
            New-LocalUser -Name "$nom" -Password (ConvertTo-SecureString "$pass" -AsPlainText -Force) -Description "Utilisateur ajouté avec le script Powershell TP1"
            if($?){
                Write-verbose "L'utilisateur $nom a été créé avec succès avec le mot de passe : $pass"
                Write-Host ""
                }
            }
        else{
            New-LocalUser -Name "$nom" -Description "Utilisateur ajouté avec le script Powershell TP1"
            if($?){
                Write-verbose "L'utilisateur $nom a été créé avec succès !"
                Write-Host ""
            }
        }
    }

    function AjouterDansGroupe{
    [cmdletbinding()]
        param([string]$goupe,
              [string]$nom
              )
        Add-LocalGroupMember -Group "$groupe" -Member "$nom"
        if($?){
        Write-verbose "L'utilisateur $nom a été ajouté au groupe $groupe avec succès !"
        Write-Host ""
        }
    }

    function CreerNomFichier($p_groupe){
        $date = Get-Date -Format "ddMMyyyyHHmm"
        $nomFichier = "export-$p_groupe-$date.csv"
        return $nomFichier
    }

    #On exporte avec le nom du groupe et un mot de passe générique afin d'offrir plus tard le choix une importation entierement automatique
    function ExporterCSV{
    [cmdletbinding()]
    param([string]$groupe,
          [string]$nomFichier
          )
        if((Get-LocalGroupMember -Group $groupe).count -eq 0) {
            Write-Host "ERREUR : Aucun membre dans le groupe." -ForegroundColor red
        }
        else{
        Get-LocalGroupMember -Group "$groupe" | select-object -Property name, @{Name="Group"; Expression={"$groupe"}}, @{Name="Password"; Expression={"Bonjour1*"}}  | Export-Csv -Path "C:\TEMP\$nomFichier" -NoTypeInformation
        if($?){
            Write-Host ""
            Write-verbose "Fichier exporté avec succès !"
            Write-Host "Emplacement : C:\TEMP\$nomFichier" -ForegroundColor green
            "C:\TEMP\$nomFichier" | Set-Clipboard
            }
        }
    }

    function VerifierChemin($p_chemin){
        Test-Path -Path $p_chemin
    }

    function SupprimerUtilisateur{
    [cmdletbinding()]
    param([string]$user)
         Remove-LocalUser -name $user
         if($?){
            Write-verbose "Utilisateur $($user) supprimé avec succès !"
         }
    }

    function DiviserNomBrut($p_nom){
        $nomBrut = $($p_nom.name)
        $parties = $nomBrut.Split("\")
        $nomFinal = $parties[1]
        return $nomFinal
    }

    #Afficher le menu seulement une fois quand l'operation precedente est terminée
    if($verification){
        Write-Host ""
        Write-Host "***************************************************************"
        Write-Host "* [1] Créer un groupe                                         *"
        Write-Host "* [2] Créer un utilisateur et l’ajouter à un groupe           *"
        Write-Host "* [3] Exporter les utilisateurs d’un groupe                   *"
        Write-Host "* [4] Supprimer des utilisateurs à partir d’un fichier CSV    *"
        Write-Host "* [5] Importer des utilisateurs à partir d’un fichier CSV     *"
        Write-Host "* [Q] Quitter                                                 *"
        Write-Host "***************************************************************"
        Write-Host ""
    }

    $verification = $false
    $choix = PoserQuestion "Veuillez entrer votre choix"

    Switch ("$choix")
    {
        "1" { #Créer un groupe
                do {         
                    $groupe = PoserQuestion "Entrer le nom du groupe"
                    if (VerifierGroupe $groupe) {
                        Write-Host "ERREUR : Le groupe $groupe existe déjà." -ForegroundColor red
                    } 
                    else {
                        CreerGroupe $groupe -verbose
                        $verification = $true
                    }
                }while(!$verification)                      
            }

        "2" { #Créer un utilisateur et l’ajouter à un groupe            
                do {
                    $nom = PoserQuestion "Entrer le nom de l'utilisateur"                            
                    $verification = VerifierUtilisateur $nom
                    }while(!$verification) 

                    $groupe = PoserQuestion "Entrer le nom du groupe pour $nom"
                    CreerUtilisateur -nom $nom -verbose
                    if (VerifierGroupe $groupe) {                    
                        AjouterDansGroupe $groupe $nom -verbose                      
                    }
                    else{
                        CreerGroupe $groupe -verbose                        
                        AjouterDansGroupe $groupe $nom -verbose
                    }
             }                            

        "3" { #Exporter les utilisateurs d’un groupe  
                do {
                    $groupe = PoserQuestion "Entrer le nom du groupe"
                if (!(VerifierGroupe $groupe)) {
                        Write-Host "ERREUR : Le groupe $groupe n'existe pas." -ForegroundColor red
                    } 
                else {
                    $nomFichier = CreerNomFichier $groupe
                    ExporterCSV $groupe $nomFichier -verbose     
                    $verification = $true        
                }
                }while(!$verification) 
            }         
     
        "4" { #Supprimer des utilisateurs à partir d’un fichier CSV        
                do{
                    $chemin = PoserQuestion "Entrer le chemin du fichier CSV"
                    if (VerifierChemin $chemin) {
                        $csv = Import-Csv -Path $chemin
                    
                        foreach ($user in $csv) {
                            $nom = DiviserNomBrut $user
                            SupprimerUtilisateur $nom -verbose
                            $verification = $true
                        }
                    } 
                    else {
                        Write-Host "ERREUR : Fichier inexistant." -ForegroundColor red
                    }
                }while(!$verification) 
            }

        "5" { #Importer des utilisateurs à partir d’un fichier CSV                
                do{
                $chemin = PoserQuestion "Entrer le chemin du fichier CSV"
                    if (VerifierChemin $chemin) {
                        $csv = Import-Csv -Path $chemin
                        if($?){
                            #Donne le choix d'entrer un mot de passe pour chaque utilisateur ou bien de pendre le generique du csv.       
                            $choix = PoserQuestion2Choix "ATTENTION : Voulez-vous saisir manuellement un mot de passe pour chaque utilisateur ? [O] pour oui [N] pour non" "O" "N"

                            foreach ($user in $csv) {                    
                                $nom = DiviserNomBrut $user
                                $groupe = $($user.group)
                                $pass = $($user.password)                                               
                                $verification = VerifierUtilisateur $nom
                                if($verification){ 
                                    if($choix -eq "O"){                                                    
                                        CreerUtilisateur -nom $nom -verbose   
                                    }
                                    else{                                    
                                        CreerUtilisateur -nom $nom -pass $pass -verbose
                                    }                                 
                                AjouterDansGroupe $groupe $nom -verbose           
                                }                                                    
                            }            
                        }
                    $verification = $true  
                    }
                    else{
                        Write-Host "ERREUR : Fichier inexistant." -ForegroundColor red
                    }
                        
                }while(!$verification)                       
            }
            
        "Q"{ 
                if($choix -ceq "q"){
                    Write-verbose "Saisir 'Q' majuscule pour quitter." -verbose
                }
           }                    

   Default {
                Write-Host "ERREUR : Saisir un chiffre entre 1 et 5 ou 'Q' pour quitter." -ForegroundColor red
           }
    }
    
}while($choix -cne "Q")
Write-Host ""