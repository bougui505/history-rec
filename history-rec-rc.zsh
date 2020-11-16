function preexec() {
  timer=$(($(date +%s%0N)/1000000))
}

function precmd() {
  exit_status=$?
  hr -
  if [ $timer ]; then
    now=$(($(date +%s%0N)/1000000))
    elapsed=$(($now-$timer))
    export RPROMPT="%F{cyan}${elapsed}ms %{$reset_color%}"
    unset timer
  fi
  # Parenthesis required to avoid Done message of background process
  (log_history "$(fc -ln 0 | tail -1)" $exit_status $PWD $(date -Is) $elapsed &)
}