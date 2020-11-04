# Store shell history in a recfile using recutils
(See: https://www.gnu.org/software/recutils/)

## Install:
Link `log_history.sh` and `recent.sh` somewhere in your `/home/bougui/.local/bin:/home/bougui/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/snap/bin:/home/bougui/bin:/home/bougui/.gem/ruby/2.1.0/bin:/home/bougui/source/UCSF_DOCK/dock6/bin:/home/bougui/source/node.js/node-v10.15.3-linux-x64/bin:/snap/bin:/home/bougui/.local/bin:/home/bougui/.fzf/bin:/home/bougui/go/bin`:

```bash
cd ~/bin
ln -s /path/to/history-rec/log_history.sh log_history
ln -s /path/to/history-rec/recent.sh recent
```

For zsh add this to your precmd:

```bash
function precmd() {
    exit_status=0
    log_history ""  /home/bougui/source/history-rec 2020-11-04T11:47:11+01:00
}
```

Optionally add the following alias:

```bash
alias r='recent'
```

## Usage:
```
$ recent -h

Print recent history
    -h, --help print this help message and exit
    -n, --number=NUM number of entries to print
    -s, --search=STR string to search for command field
    -w, --cwd=STR print only entries for the Current Working Directory
```
