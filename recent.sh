#!/usr/bin/env zsh
# -*- coding: UTF8 -*-

# Author: Guillaume Bouvier -- guillaume.bouvier@pasteur.fr
# https://research.pasteur.fr/en/member/guillaume-bouvier/
# 2020-11-04 00:08:55 (UTC+0100)
set -e  # exit on error
set -o noclobber  # prevent overwritting redirection

function usage () {
    echo 'Print recent history'
    echo '    -h, --help print this help message and exit'
    echo '    -n, --number=NUM number of entries to print'
    echo '    -s, --search=STR string to search for command field'
    echo '    -w, --cwd=STR print only entries for the Current Working Directory'
}

RED="\033[31m"
GREEN="\033[32m"
NOCOLOR="\033[0m"

N=20
CWD=0
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--number) N="$2"; shift ;;
        -s|--search) SEARCH="$2" ; shift ;;
        -w|--cwd) CWD=1 ;;
        -h|--help) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
    shift
done

ROWS="pwd,id,date,return_val,command_raw"
if [ $CWD -eq 1 ]; then
    OUT=$(recsel -e "pwd = '$PWD'" $HOME/.history.rec | recsel -q "$SEARCH" -R $ROWS | sed '/^[[:space:]]*$/d')
else
    OUT=$(recsel -q "$SEARCH" -R $ROWS $HOME/.history.rec | sed '/^[[:space:]]*$/d')
fi
echo $OUT \
    | tail -n$N \
    | awk -v red=$RED -v green=$GREEN -v nocolor=$NOCOLOR -v pwd=$PWD\
    '{
      if ($4>0){for(i=2;i<=NF;++i){printf(red $i nocolor" ")}printf("\n")}
      else if ($1==pwd){for(i=2;i<=NF;++i){printf(green $i nocolor" ")}printf("\n")} 
      else{for(i=2;i<=NF;++i){printf($i" ")}printf("\n")}
      }'
