#!/usr/bin/env zsh
# -*- coding: UTF8 -*-

# Author: Guillaume Bouvier -- guillaume.bouvier@pasteur.fr
# https://research.pasteur.fr/en/member/guillaume-bouvier/
# 2020-11-04 00:08:55 (UTC+0100)
set -e  # exit on error
set -o noclobber  # prevent overwritting redirection

TAGSYMBOL="⬤"
function usage () {
    cat << EOF
Print recent history
    -h, --help print this help message and exit
    -n, --number=NUM number of entries to print
    -s, --search=STR string to search for command field
    -w, --cwd=STR print only entries for the Current Working Directory
    -e, --expression=RECORD_EXPR filter using the given expression
        (See: https://www.gnu.org/software/recutils/manual/SEX-Operators.html#SEX-Operators).
        Current filters:
        - Before a given date:
            - "date<<'2020-11-04T22:53'"
        - After a given date:
            - "date>>'2020-11-04T22:53'"
    -y, --yank=INT display and copy to clipboard the command entry with the given ID. (requires xclip)
    -t, --tag=INT tag the given entry given by ID using this symbol: $TAGSYMBOL
    -u, --untag=INT untag the given entry given by ID
    -p, --pin display only tagged entries
    -d, --duration=INT display commands that ran for longer than duration given in seconds
EOF
}

RED="\033[31m"
GREEN="\033[32m"
CYAN="\033[36m"
NOCOLOR="\033[0m"

N=20
CWD=0
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--number) N="$2"; shift ;;
        -s|--search) SEARCH="$2" ; shift ;;
        -w|--cwd) CWD=1 ;;
        -e|--expression) EXPRESSION="$2"; shift ;;
        -y|--yank) YANK="$2"; shift ;;
        -t|--tag) TAG="$2"; shift ;;
        -u|--untag) UNTAG="$2"; shift ;;
        -p|--pin) EXPRESSION="tag='$TAGSYMBOL'" ;;
        -d|--duration) DURATION="$2"; EXPRESSION="elapsed>='$(( $DURATION*1000 ))'"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
    shift
done

ROWS="pwd,id,date,return_val,command_raw,elapsed,tag"


function quicksearch () {
    # Search for a word in the database
    recsel -q "$SEARCH"
}
function rows () {
    recsel -R $ROWS | sed '/^[[:space:]]*$/d'
}
function cwd () {
    # Filter to get entries of the Current Working Directory only
    recsel -e "pwd = '$PWD'"
}
function filter () {
    # Filter using $EXPRESSION
    recsel -e "$EXPRESSION"
}
function command_raw () {
    # Get the command raw of the id $YANK
    cat $HOME/.history.rec | recsel -e "id=$YANK" | recsel -R 'command_raw'
}


if [ ! -z $YANK ]; then
    OUTCMD=$(command_raw)
    echo $OUTCMD
    echo $OUTCMD | tr -d '\n' | xclip
    exit 0
fi


if [ ! -z $TAG ]; then
    recset -t history -e "id=$TAG" -f tag -s $TAGSYMBOL $HOME/.history.rec
    exit 0
fi

if [ ! -z $UNTAG ]; then
    recset -t history -e "id=$UNTAG" -f tag -s " " $HOME/.history.rec
    exit 0
fi


OUT=$(cat $HOME/.history.rec)
if [ $CWD -eq 1 ]; then
    OUT=$(echo $OUT | cwd)
fi
if [ ! -z $EXPRESSION ]; then
    OUT=$(echo $OUT | filter)
fi
OUT=$(echo $OUT | quicksearch)


for ROW in $(echo $ROWS | tr ',' '\n'); do
    ROWVALS=$(echo $OUT | recsel -P $ROW)
    declare "_${ROW}_=$ROWVALS"
done
function format_out() {
    COLOR1=$1
    COLOR2=$2
    COLOR3=$3
    NOCOLOR_=$4
    _elapsed_formatted=$(echo $_elapsed_ | awk -v cyan=$COLOR3 -v nocolor=$NOCOLOR_ '{x=$1/1000; s=x%60; x/=60; m=x%60; x/=60; h=x%60;
                                                                          if (int(h)>0 && int(m)>0){printf(cyan"%02d:%02d:%02d.%03d"nocolor"\n", h, m, s, $1%1000)}
                                                                          else if (int(m)>0){printf(cyan"    %02d:%02d.%03d"nocolor"\n", m, s, $1%1000)}
                                                                          else {printf(cyan"       %02d.%03d"nocolor"\n", s, $1%1000)}
                                                                          }')
    paste -d',' <(echo $_pwd_) <(echo $_id_) <(echo $_date_) <(echo $_return_val_) \
                <(echo $_elapsed_formatted) <(echo $_tag_) <(echo $_command_raw_) \
                | sed '/^,/d' | tail -n$N \
                | awk -F"," -v red=$COLOR1 -v green=$COLOR2 -v nocolor=$NOCOLOR_ -v pwd=$PWD\
                '{
                    if ($4>0){for(i=2;i<=NF;++i){printf("%s%s%s ",red, $i, nocolor)}printf("\n")}
                    else if ($1==pwd){for(i=2;i<=NF;++i){printf("%s%s%s ", green, $i, nocolor)}printf("\n")}
                    else{for(i=2;i<=NF;++i){printf("%s ", $i)}printf("\n")}
                }'
}
if [ -t 1 ]; then  # Script stdout is not piped -> colored output
    format_out $RED $GREEN $CYAN $NOCOLOR
else  # Script stdout is piped -> no colors
    format_out '' '' '' ''
fi
