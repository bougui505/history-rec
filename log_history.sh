#!/usr/bin/env zsh
# -*- coding: UTF8 -*-

# Author: Guillaume Bouvier -- guillaume.bouvier@pasteur.fr
# https://research.pasteur.fr/en/member/guillaume-bouvier/
# 2020-11-03 23:16:07 (UTC+0100)
set -e  # exit on error
set -o noclobber  # prevent overwritting redirection

GREEN="\033[32m"
RED="\033[31m"
NOCOLOR="\033[0m"

DIRSCRIPT="$(dirname "$(readlink -f "$0")")"
TAGSYMBOL="⬤"
HISTORYDB="$(pwd)/.history.dir.rec"
HISTORYPATHS="$HOME/historypaths.list"

if (test ! -f $HISTORYPATHS); then
    touch $HISTORYPATHS
fi
grep -qxF "$HISTORYDB" $HISTORYPATHS || echo "$HISTORYDB" >> $HISTORYPATHS

if [ ! -f $HISTORYDB ]; then
    touch $HISTORYDB
fi

HISTORYLABELFILE="$HOME/.history_label"

_COMMAND_=$1
_RETURN_VAL_=$2
_PWD_=$3
_DATE_=$4
_ELAPSED_=$5  # elapsed command time in ms
_LOAD_=$6  # difference of load average
LABEL=$7

if [[ ! -z $_COMMAND_ && ! -z $_ELAPSED_ ]]; then  # Check that $_COMMAND_ is not empty
    COMMANDFMT=$(echo $_COMMAND_ | sed "s/'/\\\'/g")
    SEX="command = '$COMMANDFMT' && pwd = '$PWD' && label = '$LABEL'"
    # Check if command is tagged
    TAG=$(recsel -e $SEX $HISTORYDB | recsel -R "tag")
    if [[ -z $TAG && TAG != $TAGSYMBOL ]]; then
        TAG=" "
    fi
    # Check if command is commented
    COMMENT=$(recsel -e $SEX $HISTORYDB | recsel -R "comment")
    if [[ -z $COMMENT ]]; then
        COMMENT=" "
    fi
    # Delete duplicates
    if (test ! -z "$(recinf $HISTORYDB)"); then  # the history rec file is not empty
        recdel \
               --force \
               -e $SEX \
                $HISTORYDB
    fi
    LOAD_AVERAGE=$(awk '{print $1,$2,$3}' /proc/loadavg)
    # Store data
    recins \
           -f id -v $(date +%s%N)\
           -f command -v $COMMANDFMT \
           -f command_raw -v $_COMMAND_ \
           -f return_val -v $_RETURN_VAL_ \
           -f pwd -v $_PWD_ \
           -f date -v $_DATE_ \
           -f tag -v $TAG \
           -f comment -v $COMMENT \
           -f elapsed -v $_ELAPSED_ \
           -f load_average -v "$(echo $LOAD_AVERAGE | awk '{print $1}')" \
           -f load_average -v "$(echo $LOAD_AVERAGE | awk '{print $2}')" \
           -f load_average -v "$(echo $LOAD_AVERAGE | awk '{print $3}')" \
           -f load -v "$_LOAD_" \
           -f label -v "$LABEL" \
	    $HISTORYDB
    # Clean carriage returns special characters
    sed -i 's/\\n/; /g' $HISTORYDB
fi
