#!/usr/bin/env zsh
# -*- coding: UTF8 -*-

# Author: Guillaume Bouvier -- guillaume.bouvier@pasteur.fr
# https://research.pasteur.fr/en/member/guillaume-bouvier/
# 2020-12-04 09:29:03 (UTC+0100)
set -e  # exit on error
set -o pipefail  # exit when a process in the pipe failsi
set -o noclobber  # prevent overwritting redirection

IDS=$(tsp | grep 'log_history' | awk '{print $1}')
for ID in $(echo $IDS); do
    STATUS=$(tsp -s $ID)
    if [[ $STATUS == 'finished' ]]; then
        tsp -r $ID
    fi
done
