#!/usr/bin/env zsh
# -*- coding: UTF8 -*-

# Author: Guillaume Bouvier -- guillaume.bouvier@pasteur.fr
# https://research.pasteur.fr/en/member/guillaume-bouvier/
# 2020-11-03 23:16:07 (UTC+0100)
set -e  # exit on error
set -o noclobber  # prevent overwritting redirection

DIRSCRIPT="$(dirname "$(readlink -f "$0")")"
TAGSYMBOL="⬤"
if [ ! -f $HOME/.history.rec ]; then
    cp $DIRSCRIPT/history.rec.template $HOME/.history.rec
fi

HISTORYDB=$HOME/.history.rec

_COMMAND_=$1
_RETURN_VAL_=$2
_PWD_=$3
_DATE_=$4
_ELAPSED_=$5  # elapsed command time in ms

if [[ ! -z $_COMMAND_ && ! -z $_ELAPSED_ ]]; then  # Check that $_COMMAND_ is not empty
    COMMANDFMT=$(echo $_COMMAND_ | sed "s/'/\\\'/g")
    SEX="command = '$COMMANDFMT' && pwd = '$PWD'"
    # Check if command is tagged
    TAG=$(recsel -t history -e $SEX $HISTORYDB | recsel -R "tag")
    if [[ -z $TAG && TAG != $TAGSYMBOL ]]; then
        TAG=" "
    fi
    # Delete duplicates
    recdel -t history \
           --force \
           -e $SEX \
            $HISTORYDB
    LOAD_AVERAGE=$(awk '{print $1,$2,$3}' /proc/loadavg)
    # Store data
    recins -t history \
           -f command -v $COMMANDFMT \
           -f command_raw -v $_COMMAND_ \
           -f return_val -v $_RETURN_VAL_ \
           -f pwd -v $_PWD_ \
           -f date -v $_DATE_ \
           -f tag -v $TAG \
           -f elapsed -v $_ELAPSED_ \
           -f load_average -v "$(echo $LOAD_AVERAGE | awk '{print $1}')" \
           -f load_average -v "$(echo $LOAD_AVERAGE | awk '{print $2}')" \
           -f load_average -v "$(echo $LOAD_AVERAGE | awk '{print $3}')" \
	    $HISTORYDB
    # Clean carriage returns special characters
    sed -i 's/\\n/; /g' $HISTORYDB
fi
