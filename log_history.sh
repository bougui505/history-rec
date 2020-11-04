#!/usr/bin/env zsh
# -*- coding: UTF8 -*-

# Author: Guillaume Bouvier -- guillaume.bouvier@pasteur.fr
# https://research.pasteur.fr/en/member/guillaume-bouvier/
# 2020-11-03 23:16:07 (UTC+0100)
set -e  # exit on error
set -o pipefail  # exit when a process in the pipe failsi
set -o noclobber  # prevent overwritting redirection

DIRSCRIPT="$(dirname "$(readlink -f "$0")")"
if [ ! -f $HOME/.history.rec ]; then
    cp $DIRSCRIPT/history.rec.template $HOME/.history.rec
fi

HISTORYDB=$HOME/.history.rec

_COMMAND_=$1
_RETURN_VAL_=$2
_PWD_=$3
_DATE_=$4

if [ ! -z $_COMMAND_ ]; then  # Check that $_COMMAND_ is not empty
    COMMANDFMT=$(echo $_COMMAND_ | sed "s/'/\\\'/g")
    # Delete duplicates
    recdel -t history \
           -e "command = '$COMMANDFMT' && pwd = '$PWD'" \
            $HISTORYDB
    # Store data
    recins -t history \
           -f command -v $COMMANDFMT \
           -f return_val -v $_RETURN_VAL_ \
           -f pwd -v $_PWD_ \
           -f date -v $_DATE_ \
	    $HISTORYDB
fi
