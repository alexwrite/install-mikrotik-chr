#!/bin/bash
export PATH=$PATH:/usr/bin:/bin

# Vérification du type de virtualisation
virt_type=$(systemd-detect-virt)

if [[ "$virt_type" != "kvm" && "$virt_type" != "none" ]]; then
    echo "Ce script ne peut être exécuté que sur des VPS KVM ou des machines physiques."
    echo "Type de virtualisation détecté : $virt_type"
    exit 1
fi

# Définir une fonction pour afficher des messages de statut
function status_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Fonction pour vérifier les verrouillages APT avec une boucle d'attente
function check_apt_lock() {
    while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock &>/dev/null; do
        status_message "Le système est verrouillé par un autre processus APT. Attente de 5 secondes..."
        sleep 5
    done
}

# Mise à jour et préparation du système
status_message "Mise à jour et préparation du système..."
check_apt_lock
if ! sudo apt-get update && sudo apt-get upgrade -y; then
    status_message "Erreur lors de la mise à jour ou de la mise à niveau. Vérifiez votre configuration réseau ou votre gestionnaire de paquets."
    exit 1
fi

# Installation des paquets nécessaires
status_message "Installation des paquets nécessaires..."
check_apt_lock
if ! sudo apt-get -y install gzip kpartx; then
    status_message "Erreur lors de l'installation des paquets gzip et kpartx."
    exit 1
fi

status_message "Mise à jour et installation terminées avec succès."

# Récupérer la dernière version disponible dynamiquement
latest_version=$(curl -s https://mikrotik.com/download | grep -oP 'chr-\K[0-9]+\.[0-9]+\.[0-9]+(?=\.img\.zip)' | sort -V | tail -n 1)

# Construire l'URL de téléchargement
download_url="https://download.mikrotik.com/routeros/$latest_version/chr-$latest_version.img.zip"

# Debug
status_message "Téléchargement et extraction de l'image."

# Télécharger et extraire l'image
if ! wget "$download_url" -O chr.img.zip; then
    echo "Erreur lors du téléchargement !"; exit 1
fi

if ! gunzip -c chr.img.zip > chr.img; then
    echo "Erreur lors de la décompression !"; exit 1
fi

# Identifier automatiquement le disque principal (exclusion des disques montés, RAIDs, CD-ROMs)
disk=$(lsblk -dpno NAME,TYPE,MOUNTPOINT | grep -w disk | grep -vE 'rom|raid|loop' | awk '{print $1}' | head -n 1)

if [ -z "$disk" ]; then
    status_message "Aucun disque disponible pour l'installation détecté !"; exit 1
fi

# Demander une confirmation utilisateur pour le disque sélectionné
echo "Le disque détecté est : $disk"
read -p "Confirmez-vous l'installation sur ce disque ? (oui/non) : " confirmation

# Vérification de la réponse de l'utilisateur
if [[ "$confirmation" != "oui" && "$confirmation" != "y" ]]; then
    status_message "Installation annulée par l'utilisateur."
    exit 1
else
    status_message "Le disque a été correctement sélectionné, lancement de l'installation..."
fi

# Vérification de la présence de l'image
if [ ! -f chr.img ]; then
    status_message "Erreur : Le fichier chr.img est introuvable."
    exit 1
fi

# Création des périphériques de mapping
status_message "Création des périphériques de mapping pour chr.img..."
if ! kpartx -av chr.img; then
    status_message "Erreur : Impossible de mapper les partitions depuis chr.img."
    exit 1
fi

# Vérification de la partition à monter
if [ ! -e /dev/mapper/loop0p2 ]; then
    status_message "Erreur : La partition /dev/mapper/loop0p2 est introuvable."
    exit 1
fi

# Vérification si le point de montage est vide
if [ "$(ls -A /mnt/ 2>/dev/null)" ]; then
    status_message "Erreur : Le répertoire /mnt/ n'est pas vide. Veuillez vérifier."
    exit 1
fi

# Montage de la partition
status_message "Montage de la partition /dev/mapper/loop0p2 sur /mnt/..."
if ! mount /dev/mapper/loop0p2 /mnt/; then
    status_message "Erreur : Impossible de monter /dev/mapper/loop0p2 sur /mnt/."
    exit 1
fi

status_message "Création du fichier autorun.scr avec les configurations nécessaires."
# Identifier l'interface réseau principale et récupérer les informations réseau
interface=$(ip -o -4 addr show up primary scope global | awk '{print $2}' | head -n 1)
ADDRESS=$(ip addr show $interface | grep global | cut -d' ' -f 6 | head -n 1)
GATEWAY=$(ip route list | grep default | cut -d' ' -f 3)

# Créer le fichier de configuration autorun
echo "/ip address add address=$ADDRESS interface=[/interface ethernet find where name=ether1]
/ip route add gateway=$GATEWAY
/ip dns set servers=1.1.1.1,1.0.0.1 allow-remote-requests=yes
/ip service disable [find]
/ip service enable winbox
/ip service set winbox port=8481
/user set 0 name=admin password=poiuy" > /mnt/rw/autorun.scr

# Vérification de la création du fichier
if [ -f /mnt/rw/autorun.scr ]; then
    echo "Fichier autorun.scr créé avec succès."
else
    echo "Erreur : le fichier autorun.scr n'a pas été créé."
    exit 1
fi

# Assurer la synchronisation et démonter proprement
sync && umount /mnt/

# Supprimer les périphériques de mappage existants
status_message "Démontage des périphériques de mappage de l'image..."
if ! sudo kpartx -dv chr.img; then
    status_message "Erreur lors de la suppression des périphériques de mappage."
    exit 1
else
    status_message "Périphériques de mappage supprimés."
fi

# Préparer le système pour l'écriture de l'image
status_message "Préparation pour l'écriture de l'image sur le disque..."
echo u > /proc/sysrq-trigger

# Écrire l'image sur le disque
status_message "Écriture de l'image sur le disque /dev/sda..."
if ! sudo dd if=chr.img bs=1024 of=/dev/sda status=progress; then
    status_message "Erreur lors de l'écriture de l'image sur le disque."
    exit 1
else
    status_message "Écriture de l'image sur le disque terminée."
fi

# Synchronisation finale
status_message "Synchronisation finale avant redémarrage..."
sync && echo s > /proc/sysrq-trigger

# Attente pour s'assurer que tout est correctement écrit
status_message "Attente de 5 secondes pour assurer que l'écriture est terminée..."
sleep 5

# Extraire l'adresse IP sans le suffixe CIDR
IP=$(echo $ADDRESS | cut -d'/' -f1)
# Récapitulatif avant redémarrage
status_message "Récapitulatif avant redémarrage :"
status_message "Une fois le VPS redémarré, vous pourrez vous connecter à votre Mikrotik CHR via Winbox à l'adresse suivante :"
status_message "Adresse : $IP:8481"
status_message "Utilisateur : admin"
status_message "Mot de passe : poiuy"
status_message "Assurez-vous que tout est correct avant de procéder au redémarrage."

# Demander à l'utilisateur s'il est prêt à redémarrer
read -p "Souhaitez-vous redémarrer maintenant ? (oui/non) : " answer
if [[ "$answer" == "oui" || "$answer" == "y" ]]; then
    status_message "Redémarrage du système..."
    echo b > /proc/sysrq-trigger
    status_message "Le système redémarre maintenant."
else
    status_message "Redémarrage annulé. Vous pouvez redémarrer manuellement plus tard."
    exit 0
fi

# Fin du script
status_message "Script terminé. Le système redémarre maintenant."
