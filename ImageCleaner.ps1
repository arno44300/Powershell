Add-Type -AssemblyName System.Drawing

for(;;) {
    Clear-Host
    write-host "
    ______  ______   ____________   ________    _________    _   ____________ 
   /  _/  |/  /   | / ____/ ____/  / ____/ /   / ____/   |  / | / / ____/ __ \
   / // /|_/ / /| |/ / __/ __/    / /   / /   / __/ / /| | /  |/ / __/ / /_/ /
 _/ // /  / / ___ / /_/ / /___   / /___/ /___/ /___/ ___ |/ /|  / /___/ _, _/ 
/___/_/  /_/_/  |_\____/_____/   \____/_____/_____/_/  |_/_/ |_/_____/_/ |_|  
                                                                                                                                                               
         <Fonction multi-dossier : ajouter '$' à la fin du chemin>
"
    write-host ""
    write-host ""

    # Definition des constantes
    $tailleMin = 100KB
    $hauteurMin = 1200
    $multi = $false

    function PoserQuestion{
    param([string]$question,
          [string]$defaut = 0)
        for(;;){
            $saisie = Read-Host "$question"
            if($defaut -ne "0" -and $saisie -eq ""){$saisie = $defaut}
            if($saisie -ne ""){return $saisie} 
        }     
    }

    function VerifierChemin{
    param([string]$chemin)
        if(Test-Path "$chemin"){
            return $true
        }
        elseif($chemin -like "*$"){
            return $true
        }
        Write-Host "ERREUR : Entrer un chemin valide" -ForegroundColor red   
    }

    function EntrerChemin{
    param([string]$question)
        do{
            $saisie = PoserQuestion "$question"
            if("$saisie" -eq "0"){            
                break
            }
        }while(-not (VerifierChemin "$saisie"))
        return $saisie
    }
    
    function RecupererNomDossier {
    param ([string]$chemin)
        if($chemin -like "*_*"){
            $segments = $chemin -split '_'
        }
        else{
            $segments = $chemin -split '\\'
        }
        return $segments[-1]
    }

    function SupprimerDernierCaractere {
        param ([string]$chaine)
        if ($chaine.Length -gt 0) {
            $chaine = $chaine.Substring(0, $chaine.Length - 1)
        }
        return $chaine
    }

    $chemin = EntrerChemin "Entrer le chemin du dossier à traiter [0 pour quitter]"
    if($chemin -like "*$"){
        $multi = $true
        $chemin = SupprimerDernierCaractere $chemin
        $dossiers = (Get-ChildItem -Path $chemin -Directory).FullName
    }

    if ($chemin -eq "0") {
        exit
    }
    
    if($multi -eq $false){
        $nom = RecupererNomDossier $chemin
        $nom = PoserQuestion "Entrer le nom [Entrer pour $nom]" "$nom"
        $dossiers = 1
    }

    foreach($dossier in $dossiers){
        if($multi -eq $true){
            $nom = RecupererNomDossier $dossier
            $chemin = $dossier
        }

        # Mettre tous les fichiers des sous-dossiers dans le dossier courant
        $subFolders = Get-ChildItem -Path $chemin -Directory
        foreach ($folder in $subFolders) {
            $files = Get-ChildItem -Path $folder.FullName -File
            foreach ($file in $files) {
                $destinationPath = Join-Path -Path $chemin -ChildPath $file.Name
                Move-Item -Path $file.FullName -Destination $destinationPath -Force -Verbose
            }
        }

        $files = Get-ChildItem $chemin

        foreach ($file in $files) {
            if ($file | Where-Object {($_.Extension -notmatch ".jpg|.png|.webp|.jfif" -or $_.Length -lt $tailleMin)})
                {
                    Remove-Item -Path $file.FullName -Force -Verbose 
                }
             else{
                 if($file.Extension -ne ".webp"){
                     $image = [System.Drawing.Image]::FromFile($file.FullName)
                     $height = $image.Height
                     $image.Dispose()
                     if ($height -lt $hauteurMin) {
                        Remove-Item $file.FullName -Force -Verbose
                     }
                 }
             }
        }

        $files = Get-ChildItem $chemin
   
        # Supprimer les fichiers en double (même taille en KB et dimensions)
        $filesToDelete = @{}
    
        foreach ($file in $files) {
            $sizeInBytes = $file.Length
            $sizeInKB = [math]::Round($sizeInBytes / 1024)
            $dimensions = "$($image.Width) x $($image.Height)"
    
            $fileKey = "${sizeInKB}KB_${dimensions}"
            if ($filesToDelete.ContainsKey($fileKey)) {
                $filesToDelete[$fileKey] += @($file)
            } 
            else {
                $filesToDelete[$fileKey] = @($file)
            }
        }
    
        foreach ($key in $filesToDelete.Keys) {
            $filesToDelete[$key] | Select-Object -Skip 1 | ForEach-Object {
                Remove-Item -Path $_.FullName -Force -Verbose
            }
        }

        # Trier par taille décroissante et renommer
        $files = Get-ChildItem $chemin | Sort-Object -Property Length -Descending  
        $prenommer = $true
        for ($i = 0; $i -lt $files.Count; $i++) {
            if($prenommer){
                for ($j = 0; $j -lt $files.Count; $j++) {
                    $extension = $files[$j].Extension
                    Rename-Item -Path $files[$j].FullName -NewName "temp$($j + 1)$extension" -Force -Verbose
                }
                $files = Get-ChildItem $chemin | Sort-Object -Property Length -Descending
                $prenommer = $false
            }
            $extension = $files[$i].Extension
            Rename-Item -Path $files[$i].FullName -NewName "${nom}$($i + 1)$extension" -Force -Verbose    
        }
        if((Split-Path $chemin -Leaf) -ne $nom){
            Rename-Item -Path $chemin -NewName $nom -Force -Verbose
        }
    }
}