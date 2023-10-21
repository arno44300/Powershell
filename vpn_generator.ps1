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

function Recuperer3DerniersCaractes{
param([string]$adresse)
    $netmask = $adresse.Substring($adresse.Length - 3)
    return $netmask
}

function Supprimer3DerniersCaracteres{
param([string]$adresseCIDR)
    $adresseFinal = $adresseCIDR.Substring(0, $adresseCIDR.Length - 3)
    return $adresseFinal
}

function ValiderAdresseCIDR {
    param(
        [string]$adresseCIDR
    )
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

function ValiderAdresseIP {
    param(
        [string]$adresseIP
    )
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

Presentation
#******demarrage******
$numeroPolicy = PoserQuestionDefaut "Entrer le numero de politique [Tapez entrer pour 10]" "10"
$numeroDH = LireDH "Entrer le numero Diffie-Hellman [Tapez entrer pour 15]" "15"
$lifetime = PoserQuestionDefaut "Entrer la duree en seconde [Tapez entrer pour 3600]" "3600"
$cle = PoserQuestionDefaut "Entrer la cle [Tapez entrer pour VPNp@ss]" "VPNp@ss"
write-host ""

#*****COTE A*****
do{
    $saisie = PoserQuestion "Entrer l'adresse reseau CIDR du LAN cote A"
    $verification = ValiderAdresseCIDR $saisie
    if($verification){    
        $adresseA = $saisie      
    }
    else{
        Write-Host "ERREUR : Veuillez entrer une adresse ip valide [exemple : 192.168.1.0/24]" -ForegroundColor red
    }
}while(!$verification)

$interfaceA = PoserQuestion "Entrer l'interface de sortie cote A"

for(;;){
    $saisie = PoserQuestion "Entrer l'adresse ip de l'interface $interfaceA"
    if(ValiderAdresseIP $saisie){
        $adresseSortieA = $saisie
        break
    }
    else{
        Write-Host "ERREUR : Veuillez entrer une adresse ip valide" -ForegroundColor red
    }
}

write-host ""

#*****COTE B*****
do{
    $saisie = PoserQuestion "Entrer l'adresse reseau CIDR du LAN cote B"
    $verification = ValiderAdresseCIDR $saisie
    if($verification){    
        $adresseB = $saisie      
    }
    else{
        Write-Host "ERREUR : Veuillez entrer une adresse ip valide [exemple : 192.168.1.0/24]" -ForegroundColor red
    }
}while(!$verification)

$interfaceB = PoserQuestion "Entrer l'interface de sortie cote B"

for(;;){
$saisie = PoserQuestion "Entrer l'adresse ip de l'interface $interfaceB"
    if((ValiderAdresseIP $saisie)-and ($saisie -ne $adresseSortieA)){
        $adresseSortieB = $saisie
        break
    }
    else{
        Write-Host "ERREUR : Veuillez entrer une adresse ip valide" -ForegroundColor red
    }
} 

$netmaskA = Recuperer3DerniersCaractes $adresseA
$netmaskB = Recuperer3DerniersCaractes $adresseB

$wildcardA = RecupererWildcard $netmaskA
$wildcardB = RecupererWildcard $netmaskB

$adresseFinalA = Supprimer3DerniersCaracteres $adresseA
$adresseFinalB = Supprimer3DerniersCaracteres $adresseB

#Créer fichier 
Write-output "***** ROUTER A *****" | out-file C:\Users\$env:USERNAME\Desktop\config.txt

Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "conf t"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto isakmp policy $numeroPolicy"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "authentication pre-share"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "encryption aes 256"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "group $numeroDH"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "hash sha256"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "lifetime $lifetime"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto isakmp key $cle address $adresseSortieB"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto ipsec transform-set RAtoRB esp-aes esp-sha256-hmac"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "access-list 100 permit ip $adresseFinalA $wildcardA $adresseFinalB $wildcardB"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto map RAMAP $numeroPolicy ipsec-isakmp"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "match address 100"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "set peer $adresseSortieB"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "set transform-set RAtoRB"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "set security-association lifetime seconds $lifetime"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "int $interfaceA"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto map RAMAP"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"

Add-Content C:\Users\$env:USERNAME\Desktop\config.txt ""
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt ""

Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "***** ROUTER B *****"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "conf t"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto isakmp policy $numeroPolicy"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "authentication pre-share"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "encryption aes 256"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "group $numeroDH"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "hash sha256"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "lifetime $lifetime"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto isakmp key $cle address $adresseSortieA"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto ipsec transform-set RBtoRA esp-aes esp-sha256-hmac"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "access-list 100 permit ip $adresseFinalB $wildcardB $adresseFinalA $wildcardA"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto map RBMAP $numeroPolicy ipsec-isakmp"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "match address 100"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "set peer $adresseSortieA"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "set transform-set RBtoRA"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "set security-association lifetime seconds $lifetime"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "int $interfaceB"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "crypto map RBMAP"
Add-Content C:\Users\$env:USERNAME\Desktop\config.txt "exit"

Write-Host ""
Write-Host "Fichier de configuration exporte avec succes !" -ForegroundColor green
start-sleep 1 