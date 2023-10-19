<#On creer au besoin le dossier TEMP qui servira a deposer nos fichiers
et on rend la manipulation muette afin de ne pas perturber l'utilisateur.#>
if(!(Test-Path -Path C:\TEMP)){
    New-Item -Path "C:\" -name "TEMP" -itemtype Directory > $null
}

[cmdletbinding()]

#Booleen qui servira a valider les sorties de boucles
$verification = $true

#Titre
Write-Host "
    #    ######     #     #                         #     #                                           
   # #   #     #    #     #  ####  ###### #####     ##   ##   ##   #    #   ##    ####  ###### #####  
  #   #  #     #    #     # #      #      #    #    # # # #  #  #  ##   #  #  #  #    # #      #    # 
 #     # #     #    #     #  ####  #####  #    #    #  #  # #    # # #  # #    # #      #####  #    # 
 ####### #     #    #     #      # #      #####     #     # ###### #  # # ###### #  ### #      #####  
 #     # #     #    #     # #    # #      #   #     #     # #    # #   ## #    # #    # #      #   #  
 #     # ######      #####   ####  ###### #    #    #     # #    # #    # #    #  ####  ###### #    # 
                                                                                                      
"


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

    function VerifierMotDePasse($p_pass){
    $verification = $false
        if($p_pass.length -ge 8){
            if($p_pass -cmatch "[A-Z]"){
                if ($p_pass -cmatch "[0-9]") {
                    $verification = $true
                }
            }
        }        
        return $verification
    }

    function VerifierGroupe($p_groupe){
        return Get-ADGroup -Filter * | Where-Object { $_.Name -eq $p_groupe }
    }

    function CreerGroupe{
    [cmdletbinding()]
    param([string]$groupe) 
        New-ADGroup -Name $groupe -GroupScope Global -Description "Groupe ajouté avec le script Powershell TP1"
        if($?){
        Write-verbose "Le groupe $groupe a été créé avec succès !"
        Write-Host ""
        }
    }

    function VerifierUtilisateurDansGroupe{
        [cmdletbinding()]
    param([string]$groupe,
          [string]$id
          )
          $verification = $true

        if(Get-ADGroupMember -Identity "$groupe" | Where-Object { $_.SamAccountName -eq $id }){
            Write-Host "ERREUR : L'utilisateur $id est déjà dans le groupe $groupe." -ForegroundColor red
            $verification = $false
        }
    return $verification
    }


    function VerifierUtilisateur{
    [cmdletbinding()]
    param([string]$id,
          [string]$nomComplet = 0         
    )
    $verification = $true

        if(Get-ADUser -Filter *| Where-Object { $_.SamAccountName -eq $id }){
            if($nomComplet -ne 0){
                Write-Host "ERREUR : L'ID $id existe déjà." -ForegroundColor red
            }
            $verification = $false
        }

        elseif(Get-ADUser -Filter *| Where-Object { $_.Name -eq $nomComplet }){
            Write-Host "ERREUR : L'utilisateur $nomComplet existe déjà." -ForegroundColor red
            $verification = $false
        }
        
        else{
            if($nomComplet -eq 0){
                Write-Host "ERREUR : L'ID $id n'existe pas." -ForegroundColor red
            }
        }      
    return $verification
    }
     
    function CrypterMotDePasse() { 
    return ConvertTo-SecureString $pass -AsPlainText -Force 
    } 

    <#La fonction dispose de deux options. La premiere avec le mot de passe generique importé depuis le fichier csv pour une création entierement automatique
    La deuxieme sans mot de passe pour une creation avec saisie manuelle lors de l'ajout d'un utilisateur.#>    
    function CreerUtilisateur{
    [cmdletbinding()]
            param(
            [string]$prenom,
            [string]$nom,
            [string]$id,
            [string]$pass = 0
        )
        $verification = $false
        if($pass -ne 0){            
            New-ADUser -Name "$prenom $nom" -GivenName $prenom -Surname $nom -SamAccountName $id -AccountPassword (ConvertTo-SecureString "$pass" -AsPlainText -Force) -PasswordNeverExpires $false -ChangePasswordAtLogon $true -Enabled $true -Description "Utilisateur ajouté avec le script Powershell TP1"
            if($?){
                Write-verbose "L'utilisateur $prenom $nom a été créé avec succès avec le mot de passe : $pass"
                Write-Host "[Le mot de passe sera changé à la prochaine connexion]" -ForegroundColor green
                Write-Host ""
                $verification = $true
                }
            }

        else{
            do{
                $pass = PoserQuestion "Entrez le mot de passe pour $prenom $nom"            
                if(VerifierMotDePasse $pass){
                    $securePass = CrypterMotDePasse $pass
                    New-ADUser -Name "$prenom $nom" -GivenName $prenom -Surname $nom -SamAccountName $id -AccountPassword $securePass -PasswordNeverExpires $false -CannotChangePassword $true -Enabled $true -Description "Utilisateur ajouté avec le script Powershell TP1"
                    if($?){
                        Write-verbose "L'utilisateur $prenom $nom a été créé avec succès !"
                        Write-Host ""
                        $verification = $true
                    }
                }
                else{
                    Write-Host "ERREUR : Entrer un mot de passe contenant au moins [8 caracteres, 1 chiffre et 1 majuscule]." -ForegroundColor red
                }
            }while(!$verification)
        }
    }

    function AjouterDansGroupe{
    [cmdletbinding()]
        param([string]$goupe,
              [string]$id
              )
        Add-ADGroupMember -Identity "$groupe" -Members "$id" 
        if($?){
        Write-verbose "L'utilisateur $id a été ajouté au groupe $groupe avec succès !"
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
        if((Get-ADGroupMember -Identity $groupe).count -eq 0) {
            Write-Host "ERREUR : Aucun membre dans le groupe." -ForegroundColor red
        }
        else{
        Get-ADGroupMember -Identity "$groupe" | select-object -Property name, SamAccountName, @{Name="Group"; Expression={"$groupe"}}, @{Name="Password"; Expression={"Bonjour1*"}}  | Export-Csv -Path "C:\TEMP\$nomFichier" -NoTypeInformation | Set-Clipboard
        if($?){
            Write-Host ""
            Write-verbose "Fichier exporté avec succès !"
            Write-Host "Emplacement : C:\TEMP\$nomFichier [Lien copié dans presse-papier]" -ForegroundColor green
            "C:\TEMP\$nomFichier" | Set-Clipboard
            }
        }
    }

    function VerifierChemin($p_chemin){
        Test-Path -Path $p_chemin
    }

    function SupprimerUtilisateur{
    [cmdletbinding()]
    param([string]$id)
         try{
            Remove-ADUser -identity $id -Confirm:$false -ErrorAction SilentlyContinue 
            Write-verbose "L'utilisateur $id a été supprimé avec succès !"
         }
         catch{
            Write-Host "ERREUR : L'utilisateur $id n'existe pas." -ForegroundColor red
         }
    }

    function ObtenirPrenom($p_user){ 
        $nomBrut = $($p_user.name) 
        $parties = $nomBrut.Split(" ") 
        return $parties[0]
    } 

    function ObtenirNom($p_user){ 
        $nomBrut = $($p_user.name) 
        $parties = $nomBrut.Split(" ") 
        return $parties[1]
    }

    function AfficherListe{
        $liste = Get-ADUser -filter * | Select-Object -ExpandProperty samAccountname
        foreach ($id in $liste) {
            Write-Host $id
        }
        Write-Host ""
    }

    #Afficher le menu seulement une fois quand l'operation precedente est terminée
    if($verification){
        Write-Host ""
        Write-Host "            *****************************************************************************"
        Write-Host "            * [1] Créer un groupe Active Directory                                      *"
        Write-Host "            * [2] Créer un utilisateur Active Directory                                 *"
        Write-Host "            * [3] Ajouter un utilisateur Active Directory à un groupe Active Directory  *"
        Write-Host "            * [4] Exporter les utilisateurs d’un groupe Active Directory                *"
        Write-Host "            * [5] Supprimer des utilisateurs Active Directory à partir d’un fichier CSV *"
        Write-Host "            * [6] Importer des utilisateurs Active Directory à partir d’un fichier CSV  *"
        Write-Host "            * [Q] Quitter                                                               *"
        Write-Host "            *****************************************************************************"
        Write-Host ""
    }

    $verification = $false
    $choix = PoserQuestion "Entrer votre choix"

    Switch ("$choix")
    {
        "1" { #Créer un groupe Active Directory
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

        "2" { #Créer un utilisateur Active Directory           
                do {
                    $prenom = PoserQuestion "Entrer le prenom de l'utilisateur"
                    $nom = PoserQuestion "Entrer le nom de $prenom"                    
                    $id = PoserQuestion "Entrer l'ID de $prenom $nom"
                    $nomComplet = "$prenom $nom" 
                                               
                    $verification = VerifierUtilisateur $id $nomComplet
                    }while(!$verification) 
                  
                    CreerUtilisateur $prenom $nom $id -verbose
             }                            

        "3" { #Ajouter un utilisateur Active Directory à un groupe Active Directory
                do{
                    $id = PoserQuestion "Entrer l'ID de l'utilisateur [Tapez * pour afficher la liste]"
                        if($id -eq "*"){
                            AfficherListe
                            $verification = $true
                        }
                        else{
                            $verification = VerifierUtilisateur $id
                        }                  
                }while($verification) 

                do{
                        $groupe = PoserQuestion "Entrer le nom du groupe"     
                        if (VerifierGroupe $groupe) {                    
                            $verification = VerifierUtilisateurDansGroupe $groupe $id             
                            if($verification){
                                AjouterDansGroupe $groupe $id -verbose
                                $verification = $true
                            }       
                        }
                        else{
                            CreerGroupe $groupe -verbose                        
                            AjouterDansGroupe $groupe $id -verbose
                            $verification = $true
                        }
                }while(!$verification)               
            }

        "4" { #Exporter les utilisateurs d’un groupe Active Directory 
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
     
        "5" { #Supprimer des utilisateurs Active Directory à partir d’un fichier CSV    
                do{
                    $chemin = PoserQuestion "Entrer le chemin du fichier CSV"
                    if (VerifierChemin $chemin) {
                        $csv = Import-Csv -Path $chemin
                    
                        foreach ($user in $csv) {
                            $id = $($user.SamAccountname)
                            SupprimerUtilisateur $id -verbose
                            $verification = $true
                        }
                    } 
                    else {
                        Write-Host "ERREUR : Fichier inexistant." -ForegroundColor red
                    }
                }while(!$verification) 
            }

        "6" { #Importer des utilisateurs Active Directory à partir d’un fichier CSV                 
                do{
                $chemin = PoserQuestion "Entrer le chemin du fichier CSV"
                    if (VerifierChemin $chemin) {
                        $csv = Import-Csv -Path $chemin
                        if($?){
                            $choix = PoserQuestion2Choix "Voulez-vous ajouter les utilisateurs au groupe $($csv.group[0]) ? [O] pour oui [N] pour non" "O" "N"
                            
                            foreach ($user in $csv) {                    
                                $nomComplet = $($user.name)
                                $id = $($user.SamAccountName)
                                $groupe = $($user.group)
                                $pass = $($user.password)                                               
                                $verification = VerifierUtilisateur $id $nomComplet
                                
                                if($verification){
                                    $prenom = ObtenirPrenom $user
                                    $nom = ObtenirNom $user                                                                                                                                                     
                                    CreerUtilisateur $prenom $nom $id $pass -verbose
                                    
                                    if($choix -eq "O"){                                                                       
                                        AjouterDansGroupe $groupe $id -verbose           
                                    }
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
                Write-Host "ERREUR : Saisir un chiffre entre 1 et 6 ou 'Q' pour quitter." -ForegroundColor red
           }
    }
    
}while($choix -cne "Q")
Write-Host ""