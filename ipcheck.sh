#!/usr/bin/env bash
########################################
# ipcheck.sh v2
# Author: MrNonoss
########################################
# Pretty simple bash script to check IP
# It can query:
#--> https://getipintel.net
#--> https://www.iphunter.info
#--> https://metrics.torproject.org
########################################
# Think about:
#--> adding your getipintel.net api token as a variable below
#--> adding a valid mail adress as a variable below
########################################
#Changelog:
# 05/04/2020 -> First Commit
# 06/04/2020 -> Add timer
# 07/04/2020 -> Add helper
########################################
# SET VARIABLES
########################################
getipintel_contact=mail@exemple.fr
iphunter_api=XXX
lines=$(cat $1 | wc -l)
count=0
########################################
# HELPER
########################################
Help() {
  # Display Help
  echo -e "\e[31mipchek helper\e[0m."
  echo
  echo "Mass IP checker, using iphunter.info, getipintel.net, and metrics.torproject.org"
  echo
  echo -e "The synthax is pretty simple: \"ipcheck.sh \e[93m\$1 \$2\e[0m\""
  echo -e "Where \e[93m\$1\e[0m is your input file and \e[93m\$2\e[0m your destination file."
  echo
  echo "This bash script let user choose between 3 differents checks results with an IP reliability score."
  echo "You are offered the possibility to input a list of raw IPs, or a CSV were you will be able to choose the right column."
  echo
  echo "For it to be functionnal, you will have to provide a valid mail contact that will be used as a token (for getipintel), and also an API key from iphunter."
  echo "TIP: Changes are lines 23 and 24 of the script."
  echo
  echo "Please note two things:"
  echo -e "-->The \e[41mdestination\e[0m file will be \e[41moverwritten\e[0m if previously existant."
  echo -e "--> If you input file contains several columns, every space \e[93m(\" \")\e[0m in input file will be replaced by \e[93m(\"*\")\e[0m"
  echo
}
while getopts ":h" option; do
  case $option in
  h) # display Help
    Help
    exit
    ;;
  esac
done
########################################
# FUNCTIONS
########################################
## IPHUNTER
IPhunter() {
  iphunter=$(curl --silent https://www.iphunter.info:8082/v1/ip/$ip -H "X-Key: $iphunter_api")
  basic=$(echo $iphunter | jq -r '{ip: .data.ip, cc: .data.country_code, isp: .data.isp, block: .data.block} | .ip+","+.cc+","+.isp')
  bloc=$(echo $iphunter | jq -r '.data.block')
  if [[ $bloc == "0" ]]; then
    bloc="Good IP"
  elif [[ $bloc == "1" ]]; then
    bloc="Bad IP"
  else
    [[ $bloc == "2" ]]
    bloc="Not sure"
  fi
}
## IPINTEL
IPintel() {
  getipintel=$(curl --silent "http://check.getipintel.net/check.php?ip=$ip&contact=$getipintel_contact")
  if [[ $getipintel == "-1" ]]; then
    echo 'getipintel error: $ip retuns error "-1 Invalid no input"'
  elif [[ $getipintel == "-2" ]]; then
    echo 'getipintel error: $ip retuns error "-2 Invalid IP address"'
  elif [[ $getipintel == "-3" ]]; then
    echo 'getipintel error: $ip retuns error "-3 Unroutable address / private address"'
  elif [[ $getipintel == "-4" ]]; then
    echo 'getipintel error: $ip retuns error "-4 Unable to reach database"'
  elif [[ $getipintel == "-5" ]]; then
    echo 'getipintel error: $ip retuns error "-5 Your connecting IP has been banned from the system or you do not have permission to access a particular service. Did you exceed your query limits? Did you use an invalid email address?"'
  elif [[ $getipintel == "-6" ]]; then
    echo 'getipintel error: $ip retuns error "-6 You did not provide any contact information with your query or the contact information is invalid."'
  fi
}
## TOR
TOR() {
  onionoo=$(curl -s https://onionoo.torproject.org/summary)
  if [[ $onionoo == *$ip* ]]; then
    onionoo="Tor"
  else
    onionoo="Not Tor"
  fi
}
########################################
#LET'S-BEGIN############################
########################################
clear
echo -e "\e[33m==============================================================================================\e[0m"
echo -e "\e[33m=====================================CHECKIP BY MRNONOSS======================================\e[0m"
echo -e "\e[33m==============================================================================================\e[0m"
################
#PRE-TRAITEMENT####################################
################
while true; do
  read -r -p "Votre fichier doit-il subir un pré-traitement? [o/n] " traitement
  case $traitement in
  ####################
  #AVEC###############
  ####################
  o)
    head -n1 $1 | tr -s " " "*"
    read -p "Quel est votre séparateur de colonnes? " s
    if [[ -z $s ]]; then
      s=" "
    fi
    read -p "Quelle colonne contient les IPs? " c
    if [[ -z $var ]]; then
      c="1"
    fi
    echo -e "\e[33m==============================================================================================\e[0m"
    echo "Vous avez la possibilité de choisir entre trois types de recherches:"
    echo -e "-> Une recherche rapide: (Pays, opérateur et réputation), avec \e[96miphunter \e[1;31m[1]\e[0m (~0,3s/IP)"
    echo -e "-> Une recherche intermédiaire, avec vérification chez \e[96mgetipintel       \e[1;31m[2]\e[0m (~1s/IP)"
    echo -e "-> Une recherche longue, avec vérification des descripteurs \e[96mtor         \e[1;31m[3]\e[0m (~2s/IP)"
    echo -e "\e[33m==============================================================================================\e[0m"
    echo -e "\e[1;31mRappelez vous que vous avez $lines lignes a traiter\e[0m"
    echo -e "\e[33m==============================================================================================\e[0m"
    while true; do
      read -r -p "Quel type de recherche? [1/2/3] " search
      case $search in
      [1])
        echo "IP,CC,ISP,HUNTER" >"$2"
        BEFORE=$SECONDS
        while read ip; do
          ((count++))
          IPhunter
          echo "--> $count ligne(s) sur $lines traitée(s)"
          echo "$basic,$bloc" >>"$2"
        done <<<$(cat $1 | tr -s " " "*" | cut -d "$s" -f"$c")
        duree=$((SECONDS - BEFORE))
        echo "$lines IP traitées en $duree secondes"
        break
        ;;
      [2])
        echo "$basic,$bloc,$getipintel" >>"$2"
        BEFORE=$SECONDS
        while read ip; do
          ((count++))
          IPhunter
          IPintel
          echo "--> $count ligne(s) sur $lines traitée(s)"
          echo "$basic,$bloc,$getipintel" >>"$2"
        done <<<$(cat $1 | tr -s " " "*" | cut -d "$s" -f"$c")
        duree=$((SECONDS - BEFORE))
        echo "$lines IP traitées en $duree secondes"
        break
        ;;
      [3])
        echo "$basic,$bloc,$getipintel,$onionoo" >>"$2"
        BEFORE=$SECONDS
        while read ip; do
          ((count++))
          IPhunter
          IPintel
          TOR
          echo "--> $count ligne(s) sur $lines traitée(s)"
          echo "$basic,$bloc,$getipintel,$onionoo" >>"$2"
        done <<<$(cat $1 | tr -s " " "*" | cut -d "$s" -f"$c")
        duree=$((SECONDS - BEFORE))
        echo "$lines IP traitées en $duree secondes"
        break
        ;;
      *)
        echo -e "Aller Parkinson, on recommence. Choisissez la recherche \e[1;31m[1][2]ou[3]\e[0m"
        ;;
      esac
    done
    break
    ;;
  ####################
  #SANS###############
  ####################
  n)
    echo -e "\e[33m==============================================================================================\e[0m"
    echo "Vous avez la possibilité de choisir entre trois types de recherches:"
    echo -e "-> Une recherche rapide: (Pays, opérateur et réputation), avec \e[96miphunter \e[1;31m[1]\e[0m (~0,3s/IP)"
    echo -e "-> Une recherche intermédiaire, avec vérification chez \e[96mgetipintel       \e[1;31m[2]\e[0m (~1s/IP)"
    echo -e "-> Une recherche longue, avec vérification des descripteurs \e[96mtor         \e[1;31m[3]\e[0m (~2s/IP)"
    echo -e "\e[33m==============================================================================================\e[0m"
    echo -e "\e[1;31mRappelez vous que vous avez $lines lignes a traiter\e[0m"
    echo -e "\e[33m==============================================================================================\e[0m"
    while true; do
      read -r -p "Quel type de recherche? [1/2/3] " search
      case $search in
      [1])
        echo "IP,CC,ISP,HUNTER" >"$2"
        BEFORE=$SECONDS
        while read ip; do
          ((count++))
          IPhunter
          echo "--> $count ligne(s) sur $lines traitée(s)"
          echo "$basic,$bloc" >>"$2"
        done <$1
        duree=$((SECONDS - BEFORE))
        echo "$lines IP traitées en $duree secondes"
        break
        ;;
      [2])
        echo "$basic,$bloc,$getipintel" >>"$2"
        BEFORE=$SECONDS
        while read ip; do
          ((count++))
          IPhunter
          IPintel
          echo "--> $count ligne(s) sur $lines traitée(s)"
          echo "$basic,$bloc,$getipintel" >>"$2"
        done <$1
        duree=$((SECONDS - BEFORE))
        echo "$lines IP traitées en $duree secondes"
        break
        ;;
      [3])
        echo "$basic,$bloc,$getipintel,$onionoo" >>"$2"
        BEFORE=$SECONDS
        while read ip; do
          ((count++))
          IPhunter
          IPintel
          TOR
          echo "--> $count ligne(s) sur $lines traitée(s)"
          echo "$basic,$bloc,$getipintel,$onionoo" >>"$2"
        done <$1
        duree=$((SECONDS - BEFORE))
        echo "$lines IP traitées en $duree secondes"
        break
        ;;
      *)
        echo -e "Aller Parkinson, on recommence. Choisissez la recherche \e[1;31m[1][2]ou[3]\e[0m"
        ;;
      esac
    done
    break
    ;;
  ####################
  #FAUX###############
  ####################
  *)
    echo -e "Pfffff encore un problème d'interface chaise/clavier... Choisissez \e[1;31m[o]ui ou [n]on\e[0m."
    ;;
  esac
done
