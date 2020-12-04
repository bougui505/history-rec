export NQDIR="$HOME/.log_history_queue"

function preexec() {
  timer=$(($(date +%s%0N)/1000000))
  load_average_0=$(awk '{print $1}' /proc/loadavg)
  HISTORYLABELFILE="$HOME/.history_label"
  if [[ -f $HISTORYLABELFILE ]]; then
      LABEL=$(cat $HISTORYLABELFILE)
  else
      LABEL="default"
  fi
}

function precmd() {
  exit_status=$?
  if [[ -f $HISTORYLABELFILE ]]; then
      LABEL=$(cat $HISTORYLABELFILE)
  fi
  hr -
  if [ $timer ]; then
    now=$(($(date +%s%0N)/1000000))
    elapsed=$(($now-$timer))
    export RPROMPT="%F{red}$LABEL %{$reset_color%}%F{cyan}${elapsed}ms %{$reset_color%}"
    unset timer
  fi
  load_average_1=$(awk '{print $1}' /proc/loadavg)
  delta_load=$(( load_average_1-load_average_0 ))
  # Parenthesis required to avoid Done message of background process
  nq -q log_history "$(fc -ln 0 | tail -1)" $exit_status $PWD $(date -Is) $elapsed $delta_load $LABEL
  find $NQDIR -type f -mmin +15 -exec rm -f {} \;  # Delete old queued items
}
