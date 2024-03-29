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
  resize > /dev/null  # To resize the layout of the terminal
  exit_status=$?
  if [[ -f $HISTORYLABELFILE ]]; then
      LABEL=$(cat $HISTORYLABELFILE)
  fi
  hr -  # for an horizontal ruler at the end of the command output display
  if [ $timer ]; then
    now=$(($(date +%s%0N)/1000000))
    elapsed=$(($now-$timer))
    export RPROMPT="%F{red}$LABEL %{$reset_color%}%F{cyan}${elapsed}ms %{$reset_color%}"
    unset timer
  fi
  load_average_1=$(awk '{print $1}' /proc/loadavg)
  delta_load=$(( load_average_1-load_average_0 ))
  # Parenthesis required to avoid Done message of background process
  tsp log_history "$(fc -ln 0 | tail -1)" $exit_status $PWD $(date -Is) $elapsed $delta_load $LABEL > /dev/null
  find $NQDIR -type f -mmin +15 -exec rm -f {} \;  # Delete old queued items
}
