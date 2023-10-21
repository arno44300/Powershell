do{
clear
write-host "    ____    __  ___    ___    ______    ______          ______    __     ______    ___     _   __    ______    ____ 
   /  _/   /  |/  /   /   |  / ____/   / ____/         / ____/   / /    / ____/   /   |   / | / /   / ____/   / __ \
   / /    / /|_/ /   / /| | / / __    / __/           / /       / /    / __/     / /| |  /  |/ /   / __/     / /_/ /
 _/ /    / /  / /   / ___ |/ /_/ /   / /___          / /___    / /___ / /___    / ___ | / /|  /   / /___    / _, _/ 
/___/   /_/  /_/   /_/  |_|\____/   /_____/          \____/   /_____//_____/   /_/  |_|/_/ |_/   /_____/   /_/ |_|"

write-host ""
do {
    $nom = Read-Host "Entrer le nom [0 pour quitter]"
} while ([string]::IsNullOrWhiteSpace($nom))

if($nom -ne "0"){
    do { 
        $chemin = Read-Host "Entrer le chemin du dossier a traiter "
    } while (![System.IO.Directory]::Exists($chemin)) 

    # Mettre tous les fichiers des sous dossiers dans le dossier courant
    $subFolders = Get-ChildItem -Path $chemin -Directory
    foreach ($folder in $subFolders) {
        $files = Get-ChildItem -Path $folder.FullName -File

    foreach ($file in $files) {
            $destinationPath = Join-Path -Path $chemin -ChildPath $file.Name
            Move-Item -Path $file.FullName -Destination $destinationPath -Force -verbose
    }}

    $files = Get-ChildItem $chemin

    # Supprimer les fichiers de petite taille et non JPEG/JPG/PNG/WEBP/JFIF
    $filesToDelete1 = $files | Where-Object {
        ($_.Extension -match ".jpg|.jpeg|.png|.webp|.jfif" -and $_.Length -lt 100KB) -or
        ($_.Extension -notmatch ".jpg|.jpeg|.png|.webp|.jfif")
    }

    foreach ($file in $filesToDelete1) {
        Remove-Item -Path $file.FullName -force -verbose
    }

    # Supprimer les fichiers en double (meme taille et dimensions)
    $filesToDelete2 = @{}

    foreach ($file in $files | Where-Object { $_.Extension -match ".jpg|.jpeg|.png|.webp|.jfif" }) {
        $size = $file.Length
        $dimensions = "$($file.Width) x $($file.Height)"

        $fileKey = "${size}_${dimensions}"
        if ($filesToDelete2.ContainsKey($fileKey)) {
            $filesToDelete2[$fileKey] += @($file)
        } else {
            $filesToDelete2[$fileKey] = @($file)
        }
    }

    foreach ($key in $filesToDelete2.Keys) {
        $filesToDelete2[$key] | Select-Object -Skip 1 | ForEach-Object {
            Remove-Item -Path $_.FullName -Force -verbose
        }
    }

    # Trier par taille decroissante et renommer
    $files = Get-ChildItem $chemin | Sort-Object -property length -Descending 

    for ($i = 0; $i -lt $files.Count; $i++) {
        $extension = $files[$i].Extension
        $nouveauNom = "${nom}$($i + 1)$extension"
        Rename-Item -Path $files[$i].FullName -NewName $nouveauNom -verbose
    }
    Rename-Item -Path $chemin -NewName $nom -verbose
}
}while($nom -ne "0")