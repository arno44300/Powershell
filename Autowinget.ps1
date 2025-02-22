param(
    [parameter (mandatory=$true)]
    [string] $ordre
)
$xapps = @()
$apps = @()
$softs = @()

$xapps = @(
    "WindowsAlarms",
    "WindowsCamera",
    "OutlookForWindows",
    "Getstarted",
    "WindowsMaps",
    "Microsoft.People",
    "PowerAutomateDesktop",
    "GetHelp",
    "BingWeather",
    "BingNews",
    "Clipchamp.Clipchamp",
    "ZuneMusic",
    "ZuneVideo",
    "QuickAssist",
    "windowscommunicationsapps",
    "549981C3F5F10",
    "WindowsSoundRecorder",
    "WindowsFeedbackHub",
    "MicrosoftStickyNotes",
    "MicrosoftSolitaireCollection",
    "YourPhone",
    "MicrosoftOfficeHub",
    "Todos"
    "WindowsMaps"
    "spotify"
    "LinkedIn"
    "Wallet"
    "Office.OneNote"
    "SkypeApp"
    "Messaging"
    "Microsoft3DViewer"
    "MixedReality.Portal"
    "OneConnect"
    "BingSearch"
    "maxxaudiopro"
    "MSPaint"
    "Paint"
    "Copilot"
    "Journal"
    "Whiteboard"
    "XboxIdentityProvider"
    "XboxSpeechToTextOverlay"
    "XboxGameOverlay"
    "XboxApp"
    "Xbox.TCUI"
    "MSTeams"
    "GamingApp"
    "devhome"
    "MicrosoftTeams"
    "Family"
    "Xerox"
)

$apps = @(
    "McAfee",
    "Dolby Audio",
    "Global VPN Client"
    "Teams"
)

$softs = @(
    "Google Chrome",
    "7-zip",
    "Adobe Acrobat"
)

$erreur = $true

function VerifierApplicationNative{
param ($p_app)
    return Get-AppxPackage -name *$p_app*
}

function SupprimerApplicationNative{
param ($p_app)
    Get-AppxPackage -AllUsers -name *$p_app* | Remove-AppxPackage
}

function VerifierApplication{
param ($p_app)
    return Get-Package | Where-Object { $_.Name -like "*$p_app*" }
}

function SuprimerApplication{
param ($p_app)
    winget uninstall *$p_app*
}

function InstallerApplication{
param($p_app)
    Write-Host "Installation de $p_app en cours..."
    if($p_app -eq "Google Chrome"){
        winget install -e --id Google.Chrome
    }
    if($p_app -eq "7-zip"){
        winget install -e --id 7zip.7zip
    }
    if($p_app -eq "Adobe Acrobat"){
        winget install -e --id Adobe.Acrobat.Reader.64-bit
    }
}

function RecupererVersionWindows{
    return Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' CurrentBuild
}

function AfficherDossiersCachesEtExtensions{
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1 *>$null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0 *>$null
}

function AfficherIconesBureau{
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -PropertyType DWORD -Force *>$null
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value 0 -PropertyType DWORD -Force *>$null
}

function DesactiverUAC{
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA -Value 0 *>$null
}

function DesactiverBing{
    reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve *>$null
}

function RestaurerAncienMenu{
    New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Force *>$null
	New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1 -PropertyType DWord -Force *>$null
}

function SupprimerAccueilEtGalerie{
    Rename-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" -NewName "-{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" *>$null
	reg add "HKEY_CURRENT_USER\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 *>$null
}

function OuvrirCePC{
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -Value 1 *>$null
}

function RedemarrerExplorer{
    Stop-Process -Name explorer -Force
    Start-Process explorer
}

function RedemarrerPC{
    Write-Host "`nVotre PC va redemarrer dans quelques instant..."
    for ($i=3; $i -gt 0; $i--) {
        Start-Sleep -Seconds 1
    }
    Restart-Computer -Force
}

if ($ordre -eq "remove" -or $ordre -eq "all"){
    $erreur = $false
    Write-Host "Desinstallation des programmes en cours..."
    foreach ($xapp in $xapps){
        if (VerifierApplicationNative $xapp){
            SupprimerApplicationNative $xapp
            if($?){
                Write-Host "L'application $xapp a ete supprimee du systeme." -ForegroundColor Green
            }
        }
        else{
            Write-Host "L'application $xapp n'est pas presente sur le systeme." -ForegroundColor Yellow
        }
    }

    foreach ($app in $apps){
        if (VerifierApplication $app){
            SuprimerApplication $app
            if($?){
                Write-Host "L'application $app a ete supprimee du systeme." -ForegroundColor Green
            }
        }
        else{
            Write-Host "L'application $app n'est pas presente sur le systeme." -ForegroundColor Yellow
        }
    }
}

if ($ordre -eq "install" -or $ordre -eq "all"){
    $erreur = $false
    Write-Host "Verification des programmes en cours..."
    foreach ($soft in $softs){
        if (-not (VerifierApplication $soft)){
            InstallerApplication $soft
        }
        else{
            Write-Host "L'application $soft est deja presente sur le systeme." -ForegroundColor Yellow
        }
    }
}

if ($ordre -eq "boost" -or $ordre -eq "all"){
    $erreur = $false
    powercfg.exe /hibernate off
    if($?){
        Write-Host "Mode d'hibernation desactive." -ForegroundColor Green
        }
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
    if($?){
        Write-Host "`nMode performance optimale active." -ForegroundColor Green
        }
}

if ($ordre -eq "custom" -or $ordre -eq "all"){
    $erreur = $false
    $WinVersion = RecupererVersionWindows
    if ($WinVersion -ge 22000){
	    SupprimerAccueilEtGalerie
        RestaurerAncienMenu
	    DesactiverBing
    }
    OuvrirCePC
    AfficherDossiersCachesEtExtensions
    AfficherIconesBureau
    RedemarrerExplorer
    DesactiverUAC
    if($?){
        Write-Host "`nCustomisation terminee." -ForegroundColor Green
        }
    RedemarrerPC
}

if ($erreur){
     Write-Host "ERREUR : Veuillez entrer un parametre [install] [remove] [boost] [custom] [all]" -ForegroundColor red
}