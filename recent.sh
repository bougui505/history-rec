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
    -n, --number NUM number of entries to print
    -s, --search STR string to search for command field
    -w, --cwd STR print only entries for the Current Working Directory
    -e, --expression RECORD_EXPR filter using the given expression
        (See: https://www.gnu.org/software/recutils/manual/SEX-Operators.html#SEX-Operators).
        Current filters:
        - Before a given date:
            - "date<<'2020-11-04T22:53'"
        - After a given date:
            - "date>>'2020-11-04T22:53'"
    -y, --yank INT display and copy to clipboard the command entry with the given ID. (requires xclip)
    -t, --tag INT tag the given entry given by ID. Use -p to display only tagged entries
    -c, --comment INT open vim editor to comment the entry given by ID
    -u, --untag INT untag the given entry given by ID
    -p, --pin display only tagged entries
    -d, --duration INT display commands that ran for longer than duration given in seconds
    -r, --renumber renumber the ids of the database
    -f, --full INT display the full entry given by id
    -l, --label STR label all the commands stored from now to the history with the given label
    -ul, --unlabel disable the current labelling
    -ll, --list-labels list all the labels stored in the history file
    -pl, --pin-label list only entries of the current active label
    --rsync HOST rsync the history recfile from the given HOST and exit
    --host HOST use the history recfile from the given HOST
    --raw output raw recfile format
    --modif FILE find the potential commands that modify the given FILE by searching commands that ran around the modification time of the file
    --access FILE find the potential commands that access the given FILE by searching commands that ran around the access time of the file
EOF
}

HISTORYRECFILE="$HOME/.history.rec"
HISTORYLABELFILE="$HOME/.history_label"

if [[ -f $HISTORYLABELFILE ]]; then
    LOADEDLABEL=$(cat $HISTORYLABELFILE)
else
    LOADEDLABEL="default"
fi

RED="\033[31m"
GREEN="\033[32m"
CYAN="\033[36m"
NOCOLOR="\033[0m"

N=20
CWD=0
RENUMBER=0
UNLABEL=0
LISTLABELS=0
RAW=0
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -n|--number) N="$2"; shift ;;
        -s|--search) SEARCH="$2" ; shift ;;
        -w|--cwd) CWD=1 ;;
        -e|--expression) EXPRESSION="$2"; shift ;;
        -y|--yank) YANK="$2"; shift ;;
        -t|--tag) TAG="$2"; shift ;;
        -c|--comment) COMMENT="$2"; shift ;;
        -u|--untag) UNTAG="$2"; shift ;;
        -p|--pin) EXPRESSION="tag='$TAGSYMBOL'" ;;
        -d|--duration) DURATION="$2"; EXPRESSION="elapsed>='$(( $DURATION*1000 ))'"; shift ;;
        -r|--renumber) RENUMBER=1 ;;
        -f|--full) FULL="$2"; shift ;;
        -l|--label) LABEL="$2"; shift ;;
        -ul|--unlabel) UNLABEL=1 ;;
        -ll|--list-labels) LISTLABELS=1 ;;
        -pl|--pin-label) EXPRESSION="label='$LOADEDLABEL'" ;;
        --rsync) RSYNC="$2"; shift ;;
        --host) _HOST_="$2"; shift ;;
        --raw) RAW=1 ;;
        --modif) MODIF="$2"; shift ;;
        --access) ACCESS="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
    shift
done

if [[ ! -z $RSYNC ]]; then
    rsync -a -zz --update --progress -h $RSYNC:.history.rec $HOME/.history-$RSYNC.rec
    exit 0
fi

if [[ ! -z $_HOST_ ]]; then
    RSYNCFILE="$HOME/.history-$_HOST_.rec"
    if [[ -f $RSYNCFILE ]]; then
        HISTORYRECFILE=$RSYNCFILE
    else
        echo "$RED$RSYNCFILE not found. Please make sure to rsync the file first (see: --rsync option)"
        exit 1
    fi
fi

if [[ ! -z $LABEL ]]; then
    if [[ -f $HISTORYLABELFILE ]]; then
        CURRENTLABEL=$(cat $HISTORYLABELFILE)
        echo "${RED}Cannot create new label $LABEL as $CURRENTLABEL already active${NOCOLOR}"
        exit 1
    else
        echo $LABEL > $HISTORYLABELFILE
        exit 0
    fi
fi

if [[ $UNLABEL -eq 1 ]]; then
    rm $HISTORYLABELFILE
    exit 0
fi

if [[ $LISTLABELS -eq 1 ]]; then
    recsel -C -P label $HISTORYRECFILE | sort -u
    exit 0
fi

if [[ ! -z $FULL ]]; then
    recsel -e "id='$FULL'" $HISTORYRECFILE
    exit 0
fi

if [ $RENUMBER -eq 1 ]; then
    sed -i '/^id: /d' $HISTORYRECFILE \
        && recfix --auto $HISTORYRECFILE
    exit 0
fi

ROWS="pwd,id,date,return_val,command_raw,elapsed,tag"


function quicksearch () {
    # Search for a word in the database
    recsel -e "command_raw~'.*$SEARCH.*'"
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
    cat $HISTORYRECFILE | recsel -e "id=$YANK" | recsel -R 'command_raw'
}
function filter_file_modif () {
    # Try to find a command that modify the given file by searching history by time
    INFILE=$1
    STATUS=$2  # Modify or Access
    MODIFTIME=$(stat $INFILE | tail -n 4 | grep "^$STATUS" | recsel -P "$STATUS")
    DATELOW=$(date -d "$MODIFTIME" +%Y-%m-%dT%H:%M)
    DATEUP=$(date -d "$MODIFTIME + 1 minute" +%Y-%m-%dT%H:%M)
    EXPRESSION="date>>'$DATELOW' && date<<'$DATEUP' && return_val=0"
    echo $EXPRESSION
}

if [ ! -z $MODIF ]; then
    EXPRESSION=$(filter_file_modif $MODIF Modify)
    CWD=1
fi

if [ ! -z $ACCESS ]; then
    EXPRESSION=$(filter_file_modif $ACCESS Access)
    CWD=1
fi

if [ ! -z $YANK ]; then
    OUTCMD=$(command_raw)
    echo $OUTCMD
    echo $OUTCMD | tr -d '\n' | xclip
    exit 0
fi


if [ ! -z $TAG ]; then
    recset -t history -e "id=$TAG" -f tag -s $TAGSYMBOL $HISTORYRECFILE
    exit 0
fi

if [ ! -z $UNTAG ]; then
    recset -t history -e "id=$UNTAG" -f tag -s " " $HISTORYRECFILE
    exit 0
fi


if [ ! -z $COMMENT ]; then
    COMMENTTMPFILE="/dev/shm/history_comment"
    recsel -e "id=$COMMENT" -P "comment" $HISTORYRECFILE > $COMMENTTMPFILE
    vim $COMMENTTMPFILE
    INPUTCOMMENT=$(cat $COMMENTTMPFILE)
    if [[ -z $INPUTCOMMENT ]]; then
        INPUTCOMMENT=" "
    fi
    recset -t history -e "id=$COMMENT" -f comment -S $INPUTCOMMENT $HISTORYRECFILE
    rm $COMMENTTMPFILE
    exit 0
fi


OUT=$(cat $HISTORYRECFILE)
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
    echo "id             date        exit code  ${COLOR3}duration${NOCOLOR_}   command"
    _elapsed_formatted=$(echo $_elapsed_ | awk -v cyan=$COLOR3 -v nocolor=$NOCOLOR_ '{x=$1/1000; s=x%60; x/=60; m=x%60; x/=60; h=x%60;
                                                                          if (int(h)>0 && int(m)>0){printf(cyan" %02d:%02d:%02d.%03d"nocolor"\n", h, m, s, $1%1000)}
                                                                          else if (int(m)>0){printf(cyan"    %02d:%02d.%03d"nocolor"\n", m, s, $1%1000)}
                                                                          else {printf(cyan"       %02d.%03d"nocolor"\n", s, $1%1000)}
                                                                          }')
    STARTROW=2
    paste -d"\t" <(echo $_pwd_) <(echo $_id_) <(echo $_date_) <(echo $_return_val_) \
                <(echo $_elapsed_formatted) <(echo $_command_raw_) \
                | sed '/^\t/d' | tail -n$N \
                | awk -F"\t" -v startrow=$STARTROW -v red=$COLOR1 -v green=$COLOR2 -v nocolor=$NOCOLOR_ -v pwd=$PWD\
                '{
                    if ($4>0){for(i=startrow;i<=NF;++i){printf("%s%s%s ",red, $i, nocolor)}printf("\n")}
                    else if ($1==pwd){for(i=startrow;i<=NF;++i){printf("%s%s%s ", green, $i, nocolor)}printf("\n")}
                    else{for(i=startrow;i<=NF;++i){printf("%s ", $i)}printf("\n")}
                }'
}
if [[ $RAW -eq 1 ]]; then
    echo $OUT
    exit 0
fi

if [ -t 1 ]; then  # Script stdout is not piped -> colored output
    format_out $RED $GREEN $CYAN $NOCOLOR
else  # Script stdout is piped -> no colors
    format_out '' '' '' ''
fi
