#!/bin/bash
# ======================================================
# DESCRIPTION : Ce programme permet de créer un conteneur chiffré et de le monter.
# AUTEUR : Hugo GUTEKUNST
# VERSION : 2.1
# LISENCE : GPL
# PREREQUIS : apt-get install cryptsetup
#		Possedez les droits root
# ======================================================


# ======================================================
# PARAMETRES LEXIQUE
# ======================================================
# Nom du conteneur chiffré
	#box_label='CRYPTOBOX'
# Chemin du point de montage
	#mount_point="/media/$box_label/"
# Périphérique de boucle locale à utiliser. Listing des devices disponoble "ls -l /dev/loop*".
	#ref_loop='loop0'
# Taille du conteneur à créer en Mo.
	#box_size='50' 
# Chemin ou se trouve le conteneur
	#orig_file_path="/tmp/$box_label/"
# ======================================================

clear
echo "============================================="
echo "==    CRYPTOBOX - Le conteneur chriffré    =="
echo "============================================="
echo 'Veuillez taper votre choix :'
echo -e "\t1 - Créer un nouveau conteneur chiffré."
echo -e "\t2 - Monter un conteneur chiffré existant."
echo -e "\t3 - Démonter un conteneur chiffré existant."
read -p "Quel est votre choix ? " choix

create_contenair()
{
	echo ''
	echo '========================>'
	echo 'Création du conteneur ...'
	echo '========================>'
	read -p "[ 1 ] Choisissez la taille du conteneur en Mo (défaut : 10) ? " box_size
		if [ -z "$box_size" ]; then box_size='10'; fi;
	echo '[ 2 ] Choisissez le périphérique de boucle local. Tapez le nom en entier parmis ce choix :'
		echo -e "\tLoop possible :"
		echo -e "\t--------------"
		ls /dev/ |grep loop
		echo -e "\tLoop occupé :"
		echo -e "\t--------------"
		losetup -a
		read -p '=> Tapez le nom en entier parmis la liste ci-dessus (défaut : loop0) ? ' ref_loop
		if [ -z "$ref_loop" ]; then ref_loop='loop0'; fi;
	read -p '[ 3 ] Quel nom voulez-vous donner à votre conteneur (défaut : CRYPTOBOX) ? ' box_label
		if [ -z "$box_label" ]; then box_label='CRYPTOBOX'; fi;
	read -p "[ 4 ] Ou faut-il stocker le conteneur qui va etre créer (défaut : $HOME) ? " orig_file_path
		if [ -z "$orig_file_path" ]; 
			then orig_file_path="$HOME/$box_label"; 
			else orig_file_path="$orig_file_path/$box_label";
		fi;
	read -p "[ 5 ] Quel point de montage pour le conteneur. Le Point de montage sera crée (défaut : /media/$box_label/) ? " mount_point 
		if [ -z "$mount_point" ]; then mount_point="/media/$box_label/"; fi;
	
	echo "Préparation de la création du conteneur en cours ..."
	echo "La clé de chiffrement du conteneur va vous etre demandé."

	# Creation du fichier conteneur
	dd if=/dev/zero of=$orig_file_path bs=1M count=$box_size
	echo '1/6 ==> Creation du conteneur [ done ].'
	
	# Utilisation du device de loopback
	losetup /dev/$ref_loop $orig_file_path
	echo '2/6 ==> Creation du label [ done ].'
	
	#~Chiffrement du conteneur
	cryptsetup --cipher=serpent-xts-plain64 --hash=sha256 --key-size=512 -y create $box_label /dev/$ref_loop
	echo '3/6 ==> Chiffrement du conteneur [ done ].'
	
	# Formatage de la partition en ext4
	mkfs.ext4 /dev/mapper/$box_label
	echo '4/6 ==> Formatage du conteneur en ext4 [ done ].'
	
	# Création du dossier pour le montage
	mkdir $mount_point
	echo '5/6 ==> Création du point de montage [ done ].'
	
	# Montage du conteneur
	mount /dev/mapper/$box_label $mount_point
	echo '6/6 ==> Montage du conteneur [ done ].'

	# Recapitulatif
	echo ''
	echo '-------------------------------------------------------------'
	echo 'Recapitulatif :'
	echo -e "\tNom du conteneur : $box_label."
	echo -e "\tPoint de montage : $mount_point."
	echo -e "\tTaille du conteneur : $box_size Mo."
	echo -e "\tChemin d'origine du conteneur : $orig_file_path."
	echo -e "\tPériphérique de loopback utilisé : `losetup -a |grep $orig_file_path`."
	echo '-------------------------------------------------------------'
	
	# Creation du fichier README
	touch $mount_point/README.txt && echo 'Tous fichiers crées ici seront protégés !' >$mount_point/README.txt
}

mount_container()
{
	echo ''
	echo '========================>'
	echo 'Montage du conteneur ...'
	echo '========================>'
	read -p 'Quel est le chemin du conteneur ? ' orig_file_path	
	echo 'Choisissez le périphérique de boucle local. Tapez le nom en entier parmis ce choix :'
		echo -e "\tLoop possible :"
		echo -e "\t--------------"
		ls /dev/ |grep loop
		echo -e "\tLoop occupé :"
		echo -e "\t--------------"
		losetup -a
	read -p '=> Tapez le nom en entier parmis la liste ci-dessus (défaut : loop0) ? ' ref_loop
	if [ -z "$ref_loop" ]; then ref_loop='loop0'; fi;
	
	losetup /dev/$ref_loop $orig_file_path
	box_label=`basename $orig_file_path`
	cryptsetup --cipher=serpent-xts-plain64 --hash=sha256 --key-size=512 create $box_label /dev/$ref_loop
	if [ -d "/media/$box_label" ];
		then a=1 
		else mkdir /media/$box_label ;
		echo 'Création du point de montage' ; 
	fi
	mount -t ext4 /dev/mapper/$box_label/ /media/$box_label/
}

clear_container()
{
	echo ''
	echo '========================>'
	echo 'Démontage du conteneur ...'
	echo '========================>'
	read -p 'Quel est le nom du conteneur ? ' box_label
	umount /dev/mapper/$box_label
	cryptsetup remove $box_label
	losetup -d `losetup -a |grep "/$box_label)" |cut -d: -f1`
	echo '1/1 ==> Démontage du périphérique [ done ].'
}

case $choix in
	'1')
		create_contenair
		;;
	'2')
		mount_container
		;;
	'3')
		clear_container
		;;
	*)
		echo "Ce choix n'est pas disponible ! Les choix possibles sont 1|2|3.";
		echo "Fermeture du programme ...";
		;;
esac
