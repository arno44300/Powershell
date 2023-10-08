if((Test-Path -Path C:\Users\$env:USERNAME\Desktop\config.txt)){
    Remove-Item "C:\Users\$env:USERNAME\Desktop\config.txt"
}

clear

function AfficherDessin{
Write-Host "              _________
            /'        /|
           /         / |_
          /         /  //|
         /_________/  ////|
        |   _ _    | 8o////|
        | /'// )_  |   8///|
        |/ // // ) |   8o///|
        / // // //,|  /  8//|
       / // // /// | /   8//|
      / // // ///__|/    8//|
     /.(_)// /// |       8///|
    (_)' `(_)/ /| |       8////|___________
   (_) /_\ (_)'| |        8///////////////
   (_) \-/ (_)'|_|         8/////////////
    (_)._.(_) d' Hb         8oooooooopb'
       (_)'  d'  H'b
            d'   'b'b
           d'     H 'b
          d'      'b 'b
         d'           'b
        d'             'b
 ____________ ______   _   __ _____  _      _      _____ ______ 
|___  /| ___ \|  ___| | | / /|_   _|| |    | |    |  ___|| ___ \
   / / | |_/ /| |_    | |/ /   | |  | |    | |    | |__  | |_/ /
  / /  | ___ \|  _|   |    \   | |  | |    | |    |  __| |    / 
./ /___| |_/ /| |     | |\  \ _| |_ | |____| |____| |___ | |\ \ 
\_____/\____/ \_|     \_| \_/ \___/ \_____/\_____/\____/ \_| \_|"
write-host ""
}

function AfficherMenu{
Write-Host "             ******************************"
Write-Host "             * [1] outside - dmz          *"
Write-Host "             * [2] inside - dmz           *"
Write-Host "             * [3] inside - outside       *"
Write-Host "             * [4] inside - outside - dmz *"
Write-Host "             ******************************"
Write-Host ""

}

function PoserQuestion($p_question){
    do {          
        $saisie = Read-Host "$p_question"
    } while ($saisie -eq "")
    return $saisie
}

function ChoisirProtocole($p_question) {
    $protocole = @()
    do {
        $proto = Read-host "$p_question"
            if($proto -ne ""){
                $protocole += $proto
            }
    } while ($proto -ne "")
    return $protocole
}

function ChoisirZones {
    param([string]$choix)
    switch ($choix) {
        "1" {
            $zones = "outside", "dmz", "dmz", "outside"
        }

        "2" {
            $zones = "inside", "dmz", "dmz", "inside"
        }

        "3" {
            $zones = "inside", "outside", "outside", "inside"
        }

        "4" {
            $zones = "inside", "outside", "dmz", "inside", "outside"
        }

        default {
            Write-Host "Entrer un chiffre entre 1 et 4"
        }
    }
    return $zones
}

function CalculerCas{
    param([string]$zone)

    if($NbZones -eq "3"){
        $NbCas = 3
    }
    else{
        $NbCas = 1
    }
    return $NbCas
}

AfficherDessin
AfficherMenu

do{
    $configuration = PoserQuestion "Entrer la configuration"  
    $zones = ChoisirZones -choix $configuration
}while($configuration -ne "1" -and $configuration -ne "2" -and $configuration -ne "3" -and $configuration -ne "4")

$NbZones = ($zones.Count)-2
$NbCas = CalculerCas -zone $NbZones
Write-Host ""

$interfaces = @()

#Entrer les interfaces
$interfaces = @()
for ($i = 0; $i -lt $NbZones; $i++) {
    do{
        $verification = $true
        $int = PoserQuestion "Entrer l'interface pour $($zones[$i])"        

            foreach($interface in $interfaces){
                if($interface -eq $int){
                    Write-Host "ERREUR : l'interface doit etre differente !"
                    $verification = $false
                }   
            }            
    }while(!$verification)
    $interfaces += $int    
}

#Créer fichier
Write-output "conf t" | out-file C:\Users\$env:USERNAME\Desktop\config.txt 

#Créer les zones 
for ($i = 0; $i -lt $NbZones; $i++) {
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "zone security $($zones[$i])"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
}

#Attitrer les zones aux interfaces physiques
for ($i = 0; $i -lt $NbZones; $i++) {
    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "int $($interfaces[$i])"
    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "zone-member security $($zones[$i])"
    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "exit"
}

Write-Host ""

#Choisir les protocoles
for ($i = 0; $i -lt $NbCas; $i++) {
    $protocoles = @()
    if($NbZones -eq "3"){
        $protocoles = ChoisirProtocole "Protocoles pour $($zones[$i])/$($zones[$i+2]) [Entrer] pour quitter"
    }
    else{
        $protocoles = ChoisirProtocole "Protocoles [Entrer] pour quitter"
    }
    Write-Host ""

    #Créer les class map 
    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "class-map type inspect match-any $($zones[$i])_to_$($zones[$i+2])"
        foreach($protocole in $protocoles){
            Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "match protocol $protocole"
        }
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"

    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "class-map type inspect match-any $($zones[$i+2])_to_$($zones[$i])"
        foreach($protocole in $protocoles){
            Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "match protocol $protocole"
        }
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
}

#Créer les policy map
for ($i = 0; $i -lt $NbCas; $i++) {
    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "policy-map type inspect $($zones[$i])_to_$($zones[$i+2])_policy"
    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "class type inspect $($zones[$i])_to_$($zones[$i+2])"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "inspect"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "class class-default "
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"

    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "policy-map type inspect $($zones[$i+2])_to_$($zones[$i])_policy"
    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "class type inspect $($zones[$i+2])_to_$($zones[$i])"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "inspect"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "class class-default "
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
}

#Créer les zones pair 
for ($i = 0; $i -lt $NbCas; $i++) {
    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "zone-pair security $($zones[$i])_to_$($zones[$i+2])_zonepair source $($zones[$i]) destination $($zones[$i+2])"
    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "service-policy type inspect $($zones[$i])_to_$($zones[$i+2])_policy"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"

    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "zone-pair security $($zones[$i+2])_to_$($zones[$i])_zonepair source $($zones[$i+2]) destination $($zones[$i])"
    Add-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" -Value "service-policy type inspect $($zones[$i+2])_to_$($zones[$i])_policy"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
}

Get-Content -Path "C:\Users\$env:USERNAME\Desktop\config.txt" | Set-Clipboard
Write-Host ""
Write-Host "Configuration copie dans le presse papier !"
start-sleep 1