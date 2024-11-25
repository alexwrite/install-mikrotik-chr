# Installation Mikrotik CHR Script

Ce script automatise le processus d'installation de **Mikrotik CHR** sur votre **VPS Debian 12**. Il permet de :

- Vérifier les verrouillages **APT** avant de procéder à l'installation.
- Télécharger la dernière version de **Mikrotik CHR**.
- Préparer et formater un disque pour l'installation de **Mikrotik CHR**.
- Créer et configurer les partitions nécessaires.
- Effectuer une installation automatisée de **Mikrotik CHR**.
- Configurer un fichier `autorun.scr` pour l'initialisation du système **Mikrotik**.
- Effectuer un redémarrage sécurisé.

## Fonctionnalités principales :

- Mise à jour automatique du système avec `apt-get`.
- Installation des paquets nécessaires (`gzip`, `kpartx`).
- Téléchargement automatique de la dernière version de **Mikrotik CHR**.
- Écriture de l'image **Mikrotik CHR** sur le disque.
- Génération d'un fichier `autorun.scr` avec la configuration de base pour **Mikrotik RouterOS**.
- Synchronisation finale avant redémarrage.

## Prérequis

Avant d'exécuter ce script, assurez-vous que votre système dispose des éléments suivants :

- Un **VPS** avec un accès root.
- **wget**, **curl**, **kpartx**, **gzip**, et **dd** installés.
- Un disque sans configuration de RAID, disponible pour l'installation de l'image.

## Utilisation

1. Clonez ce repository sur votre serveur :

    ```bash
    git clone https://github.com/alexwrite/install-mikrotik-chr.git
    cd install-mikrotik-chr
    ```

2. Rendez le script exécutable et lui assigner les bonnes perms :

    ```bash
    chmod +x install-mikrotik-chr.sh
    chmod 755 install-mikrotik-chr.sh
    ```

3. Exécutez le script avec les privilèges root :

    ```bash
    sudo ./install-mikrotik-chr.sh
    ```

Le script vous guidera tout au long de l'installation, en vous demandant des confirmations pour les actions importantes (comme le choix du disque de destination).

## License / Licence

Ce projet est sous la **licence [MIT](https://opensource.org/licenses/MIT)**.

### Règles de modification et redistribution :

- **Modification obligatoire** : Si vous modifiez ce code, vous devez redistribuer votre version modifiée sous la même licence MIT, et inclure un avis précisant que le code a été modifié.
- **Redistribution** : Vous pouvez redistribuer ce code, sous forme modifiée ou non, dans n'importe quel but, tant que vous respectez les termes de cette licence.

## Contribuer

Si vous souhaitez contribuer à ce projet, vous pouvez forker ce repository et soumettre vos pull requests. Veuillez vous assurer que votre code est bien testé et vérifié sous tous les scénarios possible avant de soumettre vos modifications. Le but étant que ce soit le plus simple possible pour l'utilisateur.

## Avertissements

- Ce script est destiné à un usage sur des serveurs **Linux** (Debian 12) et doit être utilisé avec précaution sur les autres distribution ou version.
- L'exécution du script écrasera les données sur le disque sélectionné, assurez-vous de choisir le bon disque et de sauvegarder vos données avant l'exécution.

## Mots-clés / Keywords

**French (Français)**:
- Mikrotik CHR, installation Mikrotik, VPS, script automatisé, image Mikrotik, autorun.scr, configuration Mikrotik, RouterOS, téléchargement Mikrotik, configuration réseau, partition disque, installation automatique, SSH, serveur VPS, Mikrotik installation sur VPS Debian, Mikrotik sur Linux, Mikrotik image disque, Mikrotik configuration réseau, Mikrotik routeur, Mikrotik pour VPS, automatisation Mikrotik, Mikrotik CHR install, VPS Debian Mikrotik, installation Mikrotik RouterOS, partitionnement disque Mikrotik.

**English (Anglais)**:
- Mikrotik CHR, Mikrotik installation, VPS, automated script, Mikrotik image, autorun.scr configuration, RouterOS, Mikrotik download, network configuration, disk partition, automatic installation, SSH, VPS server, Mikrotik installation on VPS Debian, Mikrotik on Linux, Mikrotik disk image, Mikrotik network setup, Mikrotik router, Mikrotik for VPS, Mikrotik automation, Mikrotik CHR install, VPS Debian Mikrotik, Mikrotik RouterOS install, disk partitioning Mikrotik.

## Contact / Contact

Si vous avez des questions ou des problèmes avec le script, n'hésitez pas à ouvrir un problème sur GitHub.

