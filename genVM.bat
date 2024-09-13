@echo off

REM Chemin vers le dossier d'installation de VirtualBox
set VBOXMANAGE="C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

REM Initialisation des variables du nom de la machine,de la taille de la RAM et de la taille du disque dur
set MV=%2%
set RAM=4096
set DISQUE=65536
REM set ISO_PATH="C:\Users\valen\Downloads\debian-12.7.0-amd64-netinst.iso"

REM Vérification qu'il y a un premier argument (action a faire)
if "%~1"=="" (
    echo Veuillez préciser une action.
    exit /b
)

REM Lister les machines enregistrées
if /i "%1%"=="L" (
for /f "tokens=1" %%a in ('%VBOXMANAGE% list vms') do (
        echo Machine %%a :
        %VBOXMANAGE% getextradata %%~a enumerate
    )
    exit /b
)


REM Vérification qu'il y a un second argument (nom de la machine)
if "%~2"=="" (
    echo Veuillez spécifier le nom de la machine virtuelle.
    exit /b
)


REM Si l'option de création de la machine est choisit
if /i "%1%"=="N" (

REM Vérification dans le cas ou la machine existe deja
%VBOXMANAGE% showvminfo "%MV%" >nul 2>nul
if %errorlevel% equ 0 (

    REM Suppression de la machine pour la recrée si elle existe deja
    echo La machine existait déja, elle a été supprimer
    %VBOXMANAGE% unregistervm "%MV%" --delete
)

REM Création de la machine virtuelle
%VBOXMANAGE% createvm --name "%MV%" --ostype Debian_64 --register

REM Configuration de la machine virtuelle
%VBOXMANAGE% modifyvm %MV% --memory %RAM%
%VBOXMANAGE% createmedium disk --filename "%MV%.vdi" --size %DISQUE%
%VBOXMANAGE% storagectl %MV% --name "SATA Controller" --add sata --bootable on
%VBOXMANAGE% storageattach "%MV%" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "%MV%.vdi"
%VBOXMANAGE% modifyvm %MV% --nic1 nat --nicbootprio1 1


REM Ajout de l'ISO
REM %VBOXMANAGE% storageattach "%MV%" --storagectl "SATA Controller" --port 0 --device 0 --type dvddrive --medium "%ISO_PATH%"

REM Modification de la machine virtuelle pour l'autologon
%VBOXMANAGE% modifyvm "%MV%" --autostart-enabled on
%VBOXMANAGE% modifyvm "%MV%" --vrde on
%VBOXMANAGE% modifyvm "%MV%" --vrdeaddress 127.0.0.1
%VBOXMANAGE% modifyvm "%MV%" --vrdeport 3389
%VBoxManage% modifyvm "%MV%" --autostart-delay 5

REM Activation du PXE, boot d'abord par le pxe puis l'iso
REM %VBOXMANAGE% modifyvm "%MV%" --boot1 net --boot2 dvd

REM Ajouter des métadonnées a la machine virtuelle
%VBOXMANAGE% setextradata "%MV%" "CustomData/Date" "%DATE%"
%VBOXMANAGE% setextradata "%MV%" "CustomData/User" "%USERNAME%"

l
REM Démarage de processus au lacement
REM %VBOXMANAGE% guestcontrol "%MV%" copyto "$SERVICE_SCRIPT" "/tmp/service_startup.sh" --username root --password "password" --target-directory "/tmp/"
REM %VBOXMANAGE% guestcontrol "%MV%" run --exe "/bin/bash" --username root --password "password" --wait-stdout -- "/bin/bash" "-c" "chmod +x /tmp/service_startup.sh && /tmp/service_startup.sh"
REM Lance un appli lors du lancement (ligne du dessus)

echo La machine virtuelle a bien été créée.
exit /b
)

REM Si l'option de démarage de la machine est choisit
if /i "%1%"=="D" (
    %VBOXMANAGE% startvm "%MV%"
    echo La machine virtuelle "%MV%" a bien été démarée.
    exit /b
)

REM Si l'option d'arrêt de la machine est choisit
if /i "%1%"=="A" (
    %VBOXMANAGE% controlvm "%MV%" poweroff
    echo La machine virtuelle "%MV%" a bien été arrêter.
    exit /b
)

REM Si l'option de suppression de la machine est choisit
if /i "%1%"=="S" (
    %VBOXMANAGE% unregistervm "%MV%" --delete
    echo La machine virtuelle "%MV%" a bien été supprimée.
    exit /b
)


echo %1 est inconnu, pour rappel les actions possibles sont:
echo L = Listage des machine virtuelle existante
echo N = Création d'une machine virtuelle
echo D = Démarage de la machine virtuelle
echo A = Arrêt de la machine virtuelle
echo S = Suppression de la machine virtuelle
exit /b
