#!/usr/bin/env xonsh

@events.on_pre_prompt
def helloworld():
    """
    Like precmd for xonsh shell
    See: https://xon.sh/events.html
    See: https://xon.sh/tutorial_events.html
    """
    lasthistory = __xonsh__.history[-1]
    cmd = lasthistory.cmd.strip()
    exitstatus = lasthistory.rtn
    elapsed = (lasthistory.ts[1] - lasthistory.ts[0]) * 1000
    timestamp = $(date -Is)
    log_history @(cmd.strip()) @(exitstatus) $PWD @(timestamp.strip()) @(elapsed) 0 default
