#!/usr/bin/env zsh
# -*- coding: UTF8 -*-

# Author: Guillaume Bouvier -- guillaume.bouvier@pasteur.fr
# https://research.pasteur.fr/en/member/guillaume-bouvier/
# 2020-11-04 00:08:55 (UTC+0100)
set -e  # exit on error
set -o pipefail  # exit when a process in the pipe failsi
set -o noclobber  # prevent overwritting redirection

function usage () {
    echo 'Print recent history'
    echo '    -n, --number=NUM number of entries to print'
    echo '    -s, --search=STR string to search for command field'
}

RED="\033[31m"
GREEN="\033[32m"
NOCOLOR="\033[0m"

N=20
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--number) N="$2"; shift ;;
        -s|--search) SEARCH="$2" ; shift ;;
        *) usage; exit 1 ;;
    esac
    shift
done


OUT=$(recsel -q "$SEARCH" -R date,return_val,command,pwd $HOME/.history.rec | sed '/^[[:space:]]*$/d')
echo $OUT \
    | tail -n$N \
    | awk -v red=$RED -v green=$GREEN -v nocolor=$NOCOLOR -v pwd=$PWD\
        '{if ($2>0){print red $1,$2,$3 nocolor} else if ($4==pwd){print green $1,$2,$3 nocolor} else{print $1,$2,$3}}'
