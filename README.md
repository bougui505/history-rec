# Store shell history in a recfile using recutils
(See: https://www.gnu.org/software/recutils/)

## Install:
Link `log_history.sh` and `recent.sh` somewhere in your `$PATH`:

```bash
cd ~/bin
ln -s /path/to/history-rec/log_history.sh log_history
ln -s /path/to/history-rec/recent.sh recent
```

For zsh add this to your precmd:

```bash
function preexec() {
    timer=$(($(date +%s%0N)/1000000))
}
function precmd() {
    exit_status=$?
    if [ $timer ]; then                                      
        now=$(($(date +%s%0N)/1000000))                        
        elapsed=$(($now-$timer))                                                                 
        unset timer                                            
    fi                                                       
    log_history "$(fc -ln 0 | tail -1)" $exit_status $PWD $(date -Is) $elapsed
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
    -e, --expression=RECORD_EXPR filter using the given expression
        (See: https://www.gnu.org/software/recutils/manual/SEX-Operators.html#SEX-Operators).
        Current filters:
        - Before a given date:
            - "date<<'2020-11-04T22:53'"
        - After a given date:
            - "date>>'2020-11-04T22:53'"
    -y, --yank=INT display and copy to clipboard the command entry with the given ID. (requires xclip)
    -t, --tag=INT tag the given entry given by ID using this symbol: ⬤
    -u, --untag=INT untag the given entry given by ID
    -p, --pin display only tagged entries
```
