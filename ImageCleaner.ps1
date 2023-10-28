do {
    Clear-Host
    write-host "    ____    __  ___    ___    ______    ______          ______    __     ______    ___     _   __    ______    ____ 
   /  _/   /  |/  /   /   |  / ____/   / ____/         / ____/   / /    / ____/   /   |   / | / /   / ____/   / __ \
   / /    / /|_/ /   / /| | / / __    / __/           / /       / /    / __/     / /| |  /  |/ /   / __/     / /_/ /
 _/ /    / /  / /   / ___ |/ /_/ /   / /___          / /___    / /___ / /___    / ___ | / /|  /   / /___    / _, _/ 
/___/   /_/  /_/   /_/  |_|\____/   /_____/          \____/   /_____//_____/   /_/  |_|/_/ |_/   /_____/   /_/ |_|"

write-host ""

#Definition des constantes
$tailleMin = 1000KB
$hauteurMin = 1600

do {
    $nom = Read-Host "Entrer le nom [0 pour quitter]"
} while ([string]::IsNullOrWhiteSpace($nom))

if ($nom -ne "0") {
    do {
        $chemin = Read-Host "Entrer le chemin du dossier à traiter"
    } while (![System.IO.Directory]::Exists($chemin))

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
        if ($file | Where-Object {
            ($_.Extension -match ".jpg|.jpeg|.png|.webp|.jfif" -and $_.Length -lt $tailleMin) -or
            ($_.Extension -notmatch ".jpg|.jpeg|.png|.webp|.jfif")}){
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
   
    # Supprimer les fichiers en double (même taille et dimensions)
    $filesToDelete = @{}
    
    foreach ($file in $files) {
        $size = $file.Length
        $dimensions = "$($image.Width) x $($image.Height)"
    
        $fileKey = "${size}_${dimensions}"
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
    
    for ($i = 0; $i -lt $files.Count; $i++) {
        $extension = $files[$i].Extension
        $nouveauNom = "${nom}$($i + 1)$extension"
        Rename-Item -Path $files[$i].FullName -NewName $nouveauNom -Force -Verbose
    }

    Rename-Item -Path $chemin -NewName $nom -Force -Verbose

    }
} while ($nom -ne "0")