Add-Type -AssemblyName System.Drawing

for(;;) {
    Clear-Host
    write-host "
    ______  ______   ____________   ________    _________    _   ____________ 
   /  _/  |/  /   | / ____/ ____/  / ____/ /   / ____/   |  / | / / ____/ __ \
   / // /|_/ / /| |/ / __/ __/    / /   / /   / __/ / /| | /  |/ / __/ / /_/ /
 _/ // /  / / ___ / /_/ / /___   / /___/ /___/ /___/ ___ |/ /|  / /___/ _, _/ 
/___/_/  /_/_/  |_\____/_____/   \____/_____/_____/_/  |_/_/ |_/_____/_/ |_|  
                                                                                                                                                               
"
    write-host ""

    # Definition des constantes
    $tailleMin = 100KB
    $hauteurMin = 1400

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
    $segments = $chemin -split '\\'
    return $segments[-1]
    } 

    $chemin = EntrerChemin "Entrer le chemin du dossier à traiter [0 pour quitter]"
    $nom = RecupererNomDossier $chemin

    if ($chemin -eq "0") {
        exit
    }
    
    $nom = PoserQuestion "Entrer le nom [Entrer pour $nom]" "$nom"

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
             $image = [System.Drawing.Image]::FromFile($file.FullName)
             $height = $image.Height
             $image.Dispose()
             if ($height -lt $hauteurMin) {
                Remove-Item $file.FullName -Force -Verbose
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
    Rename-Item -Path $chemin -NewName $nom -Force -Verbose   
}