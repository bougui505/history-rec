#!/usr/bin/env zsh
# -*- coding: UTF8 -*-

# Author: Guillaume Bouvier -- guillaume.bouvier@pasteur.fr
# https://research.pasteur.fr/en/member/guillaume-bouvier/
# 2020-11-04 11:27:11 (UTC+0100)
set -e  # exit on error
set -o pipefail  # exit when a process in the pipe failsi
set -o noclobber  # prevent overwritting redirection

func runcmd() {
    OUTPUT=$(eval $1)
    echo "\`\`\`"
    echo "$ $1\n"
    echo "$OUTPUT"
    echo "\`\`\`"
}

cat << EOF
# Store shell history in a recfile using recutils
(See: https://www.gnu.org/software/recutils/)

## Install:
Link \`log_history.sh\` and \`recent.sh\` somewhere in your \`$PATH\`:

\`\`\`bash
cd ~/bin
ln -s /path/to/history-rec/log_history.sh log_history
ln -s /path/to/history-rec/recent.sh recent
\`\`\`

For zsh add this to your precmd:

\`\`\`bash
function precmd() {
    exit_status=$?
    log_history "$(fc -ln 0 | tail -1)" $exit_status $PWD $(date -Is)
}
\`\`\`

Optionally add the following alias:

\`\`\`bash
alias r='recent'
\`\`\`

## Usage:
EOF

runcmd "recent -h"
