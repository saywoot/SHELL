#! /bin/bash

# scan_fichier
# vérifie si le dossier stockant les informations du programmes existe
# ${1} : dossier chercher
scan_fichier() {
    dossier=${1}
    fichier_trouve=0
    if [ -d $dossier ] ; then # si le fichier existe
        fichier_trouve=1   
    else
        fichier_trouve=0
    fi
    echo $fichier_trouve
}

# creation_dossier
# créé les dossiers et les fichiers nécessaire au programme
# ${1} : booleen qui retourné par scan fichier
# ${2} : nom du dossier que l'on veut créer
# ${3} : nom du fichier que l'on veut créer
creation_dossier() {
dossier=${1}
fichier_horaire=${2}
fichier_pid=${3}
found=$(scan_fichier "$dossier")
cd $HOME
if [ -d $dossier ] ; then
    cd $HOME/$dossier
    if [ -f "$fichier_horaire" ] ; then                      # vérifie si $fichier_horaire existe
        echo "$fichier_horaire trouvé"
    else
        touch "$fichier_horaire"                           
        op_error=$?
        if [ "$op_error" -eq 0 2>/dev/null ] ; then                      # vérifie si la création du fichier n'a pas échoué 
            echo "******file $fichier_horaire is created******"
        else
            echo "******ERROR $fichier_horaire can't be created******"
        fi
    fi

    if [ -f "$fichier_pid" ] ; then                          # vérifie si le fichier $fichier_pid existe
        echo "$fichier_pid trouvé"
    else
        touch "$fichier_pid"
        op_error=$?
        if [ "$op_error" -eq 0 2>/dev/null ] ; then                      # vérifie si la cration du fichier n'a pas échoué
            echo "******file $fichier_pid is created******"
        else
            echo "******ERROR $fichier_pid can't be created******"
        fi
    fi 
else
    mkdir "$dossier" 
    if [ "$op_error" -eq 0 2>/dev/null ] ; then                             # vérifie si la creation du dossier .quitter a réussi
        echo "******directory $dossier is created******"
        cd $HOME/$dossier
        touch "$fichier_horaire"
        op_error=$?
        if [ "op_error" -eq 0 2>/dev/null ] ; then                      # vérifie si la création du fichier_horaire a réussi
            echo "******file $fichier_horaire is created******"
        else
            echo "******ERROR $fichier_horaire can't be created******"
        fi

        touch "$fichier_pid"
        op_error=$?
        if [ "op_error" -eq 0 2>/dev/null ] ; then                      # vérifie si la création du fichier boucle_pid a réussi
            echo "******file $fichier_pid is created******"
        else
            echo "******ERROR $ficher_pid cant be created******"
        fi
    fi
fi

}

# evenement
# permet de comparer l'heure actuelle avec l'heure de l'événement
# puis affiche avec xmessage le message lié à l'horaire
# stocker dans le fichier horaire.db
evenement(){
    fichier_horaire="horaire.db"
    while true ; do                                             # Parcourt chacune des lignes du fichier horaire.db
        while read line ; do                                    # et les stocke dans la variable line.
            heure=$(echo $line | cut -d'|' -f1)                 # On récupère l'heure
            message=$(echo $line | cut -d'|' -f2)               # On récupère le message a affiché
            if [ "$heure" = $(date +%H%M) ] ; then              # Si l'heure dans la variable est l'heure actuelle
                xmessage -center -timeout 10 $message
                data=$(cat $fichier_horaire | sed -e "/$heure/d") 2>/dev/null 
                                                                # On récupère l'output de cat puis on la filtre 
                                                                # avec sed et on stocke le résultat.
                echo "$data" > $fichier_horaire 2>/dev/null     # On affiche le résultat et on envoit le flux dans
            fi                                                  # le fichier qui sera donc modifié.
        done < $fichier_horaire
        sleep 30
    done
}

# kill_app
# permet de tuer le processus dont le pid est stocker dans boucle.pid
# ${1} : nom du fichier dans lequel le pid est stocké
kill_app() {
    kill $(cat "$1")
    op_error=$?
    if [ "$op_error" -eq 0 ] ; then 
        echo "-- dead --"
    else
        echo "-- run --"
    fi
}

# remove_event
# permet de supprimer un événement dans le fichier horaire.db
# $1 : nom du fichier qui contient les horaires
# $2 : heure de l'événement que l'on veut supprimer
remove_event(){
    cat "$1" | grep "$2"                                # on vérifie si l'événement recherché existe

    output_error=$?                                     # si il existe la sortie d'erreur de grep est 0 sinon c'est 1
    if [ $output_error -eq 0 2>/dev/null ] ; then       # si la sortie d'erreur de grep est de 0
        data=$(cat "$1" | sed -e "/$2/d") 2>/dev/null   # on procède exactement de la même façon pour mettre à jour le 
        echo "$data" > "$1" 2>/dev/null                 # le fichier horaire.db que dans la fonction événement
        echo "******delete done******"
    else
        echo "******error******"
    fi
}

if [ $# -lt 1 ] ; then                              # si le script est lancé sans argument on renvoit la valeur 2
    echo "Erreur: il faut au moins un argument."    # sur la sortie d'erreur
    exit 2
else
    dossier=".quitter/"
    fichier_horaire="horaire.db"
    fichier_pid="boucle.pid"
    cd $HOME
    commande=$*

    heure=$(echo ${commande%%' '*})                 # extraction de l'heure dans $*
    minute=$(echo ${heure: -2})                     # extraction des minutes dans $*
    action=$(echo ${commande##*[0-9]})              # extraction du message à afficher
    # Vérification de la validité de l'heure
    if [ $heure -ge 0 2>/dev/null ] && [ $heure -le 2359 2>/dev/null ] && [ $minute -lt 60 2>/dev/null ] ; then
        creation_dossier "$dossier" "$fichier_horaire" "$fichier_pid"   # Création du dossier et des fichiers que nécessite  
        cd $HOME/$dossier 2>/dev/null                                   # le programme.
        echo "$heure|$action" >> $fichier_horaire                       # Dans le fichier texte on sépare l'heure 
                                                                        # et le texte a affiché par un pipe.
        cat "$fichier_pid" 2>/dev/null | grep '[0-9]' >/dev/null                    # On test avec cat et grep le fichier qui
        op_error=$?                                                     # stocke le pid de la fonction evenement 
                                                                        # qui est en arrière plan.
        if [ "$op_error" -eq 1 ] ; then             # Si grep ne trouve pas le pid, on lance le processus
            evenement &                             # et on stocke son pid
            echo "$!" > $fichier_pid
        else
            echo "******le programme est en cours d'execution******"
        fi
    else    # Si l'heure n'est pas valide on vérifie la validité de la commande
        creation_dossier "$dossier" "$fichier_horaire" "$fichier_pid"    
        cd $HOME/$dossier
        option="$1"

        case "$option" in                   
            "-q")                           # Tue le processus lancé en arrière-plan
                kill_app "$fichier_pid"     # et vide le fichier qui stocke son pid
                > "$fichier_pid"
                ;;
            "-r")                           # Supprime un événement
                remove_event "$fichier_horaire" "$2"
                ;;
            "-l")                           # Affiche le contenu e horaire.db soit tout les horaires
                cat -n "$fichier_horaire"
                ;;
            *)                              # affiche l'aide afin d'utiliser le programme
                echo -e "#############\n# ./quitter #\n#############"
                echo -e "Commandes : \n\tHHMM événement : ajoute un événement et lance le programme"
                echo -e "\t-q : quitte le programme \n\t-r HHMM : supprime l'événement de HHMM"
                echo -e "\t-l : affiche l'ensemble des horaires\n"
                ;;
        esac
    fi
fi
