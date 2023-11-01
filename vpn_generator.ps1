if((Test-Path -Path C:\Users\$env:USERNAME\Desktop\config.txt)){ 
Remove-Item "C:\Users\$env:USERNAME\Desktop\config.txt" 
} 
clear 

function Presentation{

Write-Host "
         _  _ ___  _  _    ____ ____ _  _ ____ ____ ____ ___ ____ ____ 
         |  | |__] |\ |    | __ |___ |\ | |___ |__/ |__|  |  |  | |__/ 
          \/  |    | \|    |__] |___ | \| |___ |  \ |  |  |  |__| |  \                                                            
                                                              
"
Write-Host "                                  ^^
          ^^      /\                                       /\
                  []                                       []
                .:[]:_          ^^                       ,:[]:.
              .: :[]: :-.                             ,-: :[]: :.
            .: : :[]: : :'._                       ,.': : :[]: : :.
          .: : : :[]: : : : :-._               _,-: : : : :[]: : : :.
      _..: : : : :[]: : : : : : :-._________.-: : : : : : :[]: : : : :-._
COTE  _:_:_:_:_:_:[]:_:_:_:_:_:_:_:_:_:_:_:_:_:_:_:_:_:_:_:[]:_:_:_:_:_:_   COTE
      !!!!!!!!!!!![]!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!![]!!!!!!!!!!!!!
 A    ^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^   B
                  []                                       []
                  []                                       []
                  []                                       []
       ~~^-~^_~^~/  \~^-~^~_~^-~_^~-^~_^~~-^~_~^~-~_~-^~_^/  \~^-~_~^-~~-
      ~ _~~- ~^-^~-^~~- ^~_^-^~~_ -~^_ -~_-~~^- _~~_~-^_ ~^-^~~-_^-~ ~^
         ~ ^- _~~_-  ~~ _ ~  ^~  - ~~^ _ -  ^~-  ~ _  ~~^  - ~_   - ~^_~
           ~-  ^_  ~^ -  ^~ _ - ~^~ _   _~^~-  _ ~~^ - _ ~ - _ ~~^ -
              ~^ -_ ~^^ -_ ~ _ - _ ~^~-  _~ -_   ~- _ ~^ _ -  ~ ^-
                  ~^~ - _ ^ - ~~~ _ - _ ~-^ ~ __- ~_ - ~  ~^_-
                      ~ ~- ^~ -  ~^ -  ~ ^~ - ~~  ^~ - ~"
write-host ""
write-host ""
}

function AfficherMenu {
Write-Host "                           **********************"
Write-Host "                           * [1] Ipsec          *"
Write-Host "                           * [2] GRE            *"
Write-Host "                           * [3] GRE over Ipsec *"
Write-Host "                           **********************"
Write-Host ""

}
   
function PoserQuestion($p_question){ 
    do {           
        $saisie = Read-Host "$p_question" 

    } while ($saisie -eq "") 
    return $saisie 
} 

function PoserQuestionDefaut($p_question, $p_defaut){    
    $saisie = Read-Host "$p_question"
    if($saisie -ne ""){
        return $saisie 
    } 
    return $p_defaut 
}

function PoserQuestionXChoix{ 
param($question,
      $choix1,
      $choix2,
      $choix3 = 0,
      $choix4 = 0)   
    for(;;){
        $saisie = PoserQuestion "$question"
        if($saisie -eq $choix1 -or $saisie -eq $choix2 -or $saisie -eq $choix3 -or $saisie -eq $choix4){
            return $saisie 
        } 
    }
} 

function LireDH{
param($p_question,
      $p_defaut)
    do{
        $DH = PoserQuestionDefaut $p_question $p_defaut
        if($DH -ne "1" -and $DH -ne "2" -and $DH -ne "5" -and $DH -ne "14" -and $DH -ne "15" -and $DH -ne "16" -and $DH -ne "19" -and $DH -ne "20" -and $DH -ne "21" -and $DH -ne "24"){
            Write-Host "ERREUR : Entrer un numero valide." -ForegroundColor red
        }
    }while($DH -ne "1" -and $DH -ne "2" -and $DH -ne "5" -and $DH -ne "14" -and $DH -ne "15" -and $DH -ne "16" -and $DH -ne "19" -and $DH -ne "20" -and $DH -ne "21" -and $DH -ne "24")
return $DH
}
   
function RecupererWildcard{
param([string]$netmask)
    Switch ("$netmask") 
    { 
        "/24"{
        $wildcard = "0.0.0.255"       
        }    
        "/25"{
        $wildcard = "0.0.0.127"
        }    
        "/26"{
        $wildcard = "0.0.0.63"
        }
        "/27"{
        $wildcard = "0.0.0.31"
        }   
        "/28"{
        $wildcard = "0.0.0.15"
        }
        "/29"{
        $wildcard = "0.0.0.7"
        }
        "/30"{
        $wildcard = "0.0.0.3"
        }
    }       
return $wildcard  
}

function RecupererMasque{
param([string]$netmask)
    Switch ("$netmask") 
    { 
        "/24"{
        $masque = "255.255.255.0"       
        }    
        "/25"{
        $masque = "255.255.255.128"
        }    
        "/26"{
        $masque = "255.255.255.192"
        }
        "/27"{
        $masque = "255.255.255.224"
        }   
        "/28"{
        $masque = "255.255.255.240"
        }
        "/29"{
        $masque = "255.255.255.248"
        }
        "/30"{
        $masque = "255.255.255.252"
        }
    }       
return $masque  
} 

function Recuperer3DerniersCaractes{
param([string]$adresse)
    if($adresse -ne ""){
        $netmask = $adresse.Substring($adresse.Length - 3)
        return $netmask
    }
}

function Supprimer3DerniersCaracteres{
param([string]$adresseCIDR)
    if($adresseCIDR -ne ""){
        $adresseFinal = $adresseCIDR.Substring(0, $adresseCIDR.Length - 3)
        return $adresseFinal
    }
}

function ValiderAdresseCIDR {
    param([string]$adresseCIDR)
    $verification = $false
    $pattern = "^\d{1,3}(\.\d{1,3}){3}/\d{1,2}$"

    if ($adresseCIDR -match $pattern) {
        $adresseIP, $masqueCIDR = $adresseCIDR -split '/'
        $ipValid = $adresseIP -split '\.' | ForEach-Object { [int]$_ -ge 0 -and [int]$_ -le 255 }
        $cidrValid = [int]$masqueCIDR -ge 24 -and [int]$masqueCIDR -le 30
        if ($ipValid -and $cidrValid) {
            $verification = $true
        } 
    }
    return $verification
}

function ObtenirAdresseCIDR {
param($question,
      $adresseAVTI = 0)
    for(;;){
        $saisie = PoserQuestion "$question"
        if(ValiderAdresseCIDR $saisie){
            if($adresseAVTI -eq 0){return $saisie}
            else{
                $netmaskAVTI = Recuperer3DerniersCaractes $adresseAVTI
                $netmaskBVTI = Recuperer3DerniersCaractes $saisie
                if($adresseAVTI -eq $saisie){
                    Write-Host "ERREUR : Cette adresse ip est déja utilisé" -ForegroundColor red
                }
                elseif($netmaskAVTI -ne $netmaskBVTI){
                    Write-Host "ERREUR : L'adresse doit avoir le masque $netmaskAVTI" -ForegroundColor red
                }
                else{return $saisie}
            }
        }
        else{
            Write-Host "ERREUR : Veuillez entrer une adresse ip valide [exemple : 192.168.1.0/24]" -ForegroundColor red     
        }
    }   
}

function ObtenirAdresseIP {
param($question,
      $interface,
      $adresseA = 0)
    for(;;){
        if ($interface -eq $null){
            $saisie = PoserQuestion "$question"
        }
        else{
            $saisie = PoserQuestion "Entrer l'adresse ip de l'interface $interface"
        }

        if(ValiderAdresseIP $saisie){
            if($adresseA -ne 0 -and $adresseA -eq $saisie){
                Write-Host "ERREUR : Cette adresse ip est déja utilisé" -ForegroundColor red
            }
            else{return $saisie}    
        }
        else{
            Write-Host "ERREUR : Veuillez entrer une adresse ip valide" -ForegroundColor red
        }
    }
}

function ObtenirInterface{
param([string]$question)
    for(;;){
        $saisie = PoserQuestion "$question"
        if(ValiderAdresseIP $saisie){
            Write-Host "ERREUR : Veuillez entrer une interface valide" -ForegroundColor red
        }
        else{return $saisie}
    }
}

function ValiderAdresseIP {
    param([string]$adresseIP)
    $verification = $false
    $pattern = "^\d{1,3}(\.\d{1,3}){3}$"
    if ($adresseIP -match $pattern) {
        $octets = $adresseIP -split '\.'
        $ipValide = $true
        foreach ($octet in $octets) {
            $octetNumerique = [int]$octet
            if ($octetNumerique -lt 0 -or $octetNumerique -gt 255) {
                $ipValide = $false
                break
            }
        }
        if ($ipValide) {
            $verification = $true
        }
    }
    return $verification
}

#*****Initialisation des variables*****
$interfaceA = $null
$interfaceB = $null
$adresseA = $null
$adresseB = $null
$adresseFinalA = $null
$adresseFinalB = $null
$adresseAVTI = $null
$adresseBVTI = $null
$adresseFinalAVTI = $null
$adresseFinalBVTI = $null

#******demarrage******
Presentation
AfficherMenu

$choix = PoserQuestionXChoix "Entrer la configuration" "1" "2" "3"

if($choix -eq "1" -or $choix -eq "3"){
    $numeroPolicy = PoserQuestionDefaut "Entrer le numero de politique [Tapez entrer pour 10]" "10"
    $numeroDH = LireDH "Entrer le numero Diffie-Hellman [Tapez entrer pour 15]" "15"
    $lifetime = PoserQuestionDefaut "Entrer la duree en seconde [Tapez entrer pour 3600]" "3600"
    $cle = PoserQuestionDefaut "Entrer la cle [Tapez entrer pour VPNp@ss]" "VPNp@ss"
    write-host ""
}

#*****COTE A*****
if($choix -eq "2" -or $choix -eq "3"){   
    $adresseAVTI = ObtenirAdresseCIDR "Entrer l'adresse VTI CIDR cote A" 
}
$adresseA = ObtenirAdresseCIDR "Entrer l'adresse reseau CIDR du LAN cote A"
if($choix -eq "1" -or $choix -eq "3"){        
    $interfaceA = ObtenirInterface "Entrer l'interface de sortie cote A"
}
$adresseSortieA = ObtenirAdresseIP "Enter l'adresse ip de sortie cote A" $interfaceA
write-host ""

#*****COTE B*****
if($choix -eq "2" -or $choix -eq "3"){   
    $adresseBVTI = ObtenirAdresseCIDR "Entrer l'adresse VTI CIDR cote B" $adresseAVTI
}
$adresseB = ObtenirAdresseCIDR "Entrer l'adresse reseau CIDR du LAN cote B"
if($choix -eq "1" -or $choix -eq "3"){        
    $interfaceB = ObtenirInterface "Entrer l'interface de sortie cote B"
}
$adresseSortieB = ObtenirAdresseIP "Enter l'adresse ip de sortie cote B" $interfaceB $adresseSortieA

#*****Calcul*****
$netmaskA = Recuperer3DerniersCaractes $adresseA
$netmaskB = Recuperer3DerniersCaractes $adresseB
$netmaskAVTI = Recuperer3DerniersCaractes $adresseAVTI
$netmaskBVTI = Recuperer3DerniersCaractes $adresseBVTI

$wildcardA = RecupererWildcard $netmaskA
$wildcardB = RecupererWildcard $netmaskB

$MasqueA = RecupererMasque $netmaskA
$MasqueB = RecupererMasque $netmaskB
$MasqueVTIA = RecupererMasque $netmaskAVTI
$MasqueVTIB = RecupererMasque $netmaskBVTI

$adresseFinalA = Supprimer3DerniersCaracteres $adresseA
$adresseFinalB = Supprimer3DerniersCaracteres $adresseB
$adresseFinalAVTI = Supprimer3DerniersCaracteres $adresseAVTI
$adresseFinalBVTI = Supprimer3DerniersCaracteres $adresseBVTI

#Créer fichier 
Write-output "***** ROUTER A *****" | out-file C:\Users\$env:USERNAME\Desktop\config.txt

Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "conf t"
if($choix -eq "2" -or $choix -eq "3"){
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "interface tunnel 1"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "tunnel mode gre ip"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "ip address $adresseFinalAVTI $MasqueVTIA"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "tunnel source $adresseSortieA"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "tunnel destination $adresseSortieB"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
}
if($choix -eq "1" -or $choix -eq "3"){
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto isakmp policy $numeroPolicy"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "authentication pre-share"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "encryption aes 256"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "group $numeroDH"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "hash sha256"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "lifetime $lifetime"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto isakmp key $cle address $adresseSortieB"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto ipsec transform-set RAtoRB esp-aes esp-sha256-hmac"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "mode transport"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "ip access-list extended VPN-LIST"
    if($choix -eq "1"){
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "ip $adresseFinalA $wildcardA $adresseFinalB $wildcardB"
    }
    if($choix -eq "3"){
        Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "permit gre any any"
    }
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto map RAMAP $numeroPolicy ipsec-isakmp"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "match address VPN-LIST"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "set peer $adresseSortieB"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "set transform-set RAtoRB"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "set security-association lifetime seconds $lifetime"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "int $interfaceA"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto map RAMAP"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
}
if($choix -eq "2" -or $choix -eq "3"){
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "ip route $adresseFinalB $MasqueB $adresseFinalBVTI"
}

Add-Content C:\Users\$env:USERNAME\Desktop\config.txt ""
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt ""
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "***** ROUTER B *****"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "conf t"
if($choix -eq "2" -or $choix -eq "3"){
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "interface tunnel 1"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "tunnel mode gre ip"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "ip address $adresseFinalBVTI $MasqueVTIB"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "tunnel source $adresseSortieB"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "tunnel destination $adresseSortieA"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
}
if($choix -eq "1" -or $choix -eq "3"){    
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto isakmp policy $numeroPolicy"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "authentication pre-share"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "encryption aes 256"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "group $numeroDH"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "hash sha256"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "lifetime $lifetime"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto isakmp key $cle address $adresseSortieA"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto ipsec transform-set RBtoRA esp-aes esp-sha256-hmac"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "mode transport"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "ip access-list extended VPN-LIST"
    if($choix -eq "1"){
        Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "ip $adresseFinalA $wildcardA $adresseFinalB $wildcardB"
    }
    if($choix -eq "3"){
        Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "permit gre any any"
    }
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto map RBMAP $numeroPolicy ipsec-isakmp"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "match address VPN-LIST"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "set peer $adresseSortieA"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "set transform-set RBtoRA"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "set security-association lifetime seconds $lifetime"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "int $interfaceB"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto map RBMAP"
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
}
if($choix -eq "2" -or $choix -eq "3"){
    Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "ip route $adresseFinalA $MasqueA $adresseFinalAVTI"
}

Write-Host ""
Write-Host "Fichier de configuration exporté avec succès !" -ForegroundColor green
start-sleep 1 