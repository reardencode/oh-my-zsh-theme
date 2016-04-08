#!/usr/bin/env zsh

setopt promptsubst

zmodload zsh/datetime
autoload -U add-zsh-hook

PROMPT_SUCCESS_COLOR=$FG[077]
PROMPT_FAILURE_COLOR=$FG[124]
PROMPT_VCS_INFO_COLOR=$FG[242]
PROMPT_PROMPT=$FG[117]
GIT_DIRTY_COLOR=$FG[133]
GIT_CLEAN_COLOR=$FG[118]
GIT_PROMPT_INFO=$FG[012]

local rc_hostname
if [[ -n $SSH_CONNECTION ]]; then
    rc_hostname="${SHORT_HOST}:"
fi

function save_begin_time {
    begin_time=$EPOCHREALTIME
}
add-zsh-hook preexec save_begin_time

function calculate_elapsed {
    if [[ -n "$begin_time" ]]; then
        local end_time=$EPOCHREALTIME
        local elapsed_time=$((${end_time}-${begin_time}))
        unset begin_time
        if (($elapsed_time < .005)); then
            return
        fi
        integer elapsed_seconds=$elapsed_time
        integer elapsed_millis=$(((${elapsed_time}-${elapsed_seconds})*1000+.5))
        elapsed="P"
        if (($elapsed_seconds > 86400)); then
            integer days=$(($elapsed_seconds/86400))
            elapsed+="${days}D"
            elapsed_seconds=$(($elapsed_seconds%86400))
        fi
        elapsed+="T"
        if (($elapsed_seconds > 3600)); then
            integer hours=$(($elapsed_seconds/3600))
            elapsed+="${hours}H"
            elapsed_seconds=$(($elapsed_seconds%3600))
        fi
        if (($elapsed_seconds > 60)); then
            integer minutes=$(($elapsed_seconds/60))
            elapsed+="${minutes}M"
            elapsed_seconds=$(($elapsed_seconds%60))
        fi
        if (($elapsed_seconds > 0)) || (($elapsed_millis > 0)); then
            elapsed+="${elapsed_seconds}"
            if (($elapsed_time < 60)) && (($elapsed_millis > 5)); then
                elapsed_millis=$(($elapsed_millis+1000))
                elapsed+=".${elapsed_millis#1}"
            fi
            elapsed+="S"
        fi
        elapsed+=" "
    else
        unset elapsed
    fi
}
add-zsh-hook precmd calculate_elapsed

function calculate_git_prompt {
    unset git_prompt
    local dir=$PWD
    while [[ -d $dir ]]; do
        if [[ -d ${dir}/.git ]]; then
            git_prompt=" %{$GIT_PROMPT_INFO%}$(git_prompt_info)%{$GIT_DIRTY_COLOR%}$(git_prompt_status)%{$reset_color%}"
            break
        fi
        dir=${dir}/..
    done
}
add-zsh-hook precmd calculate_git_prompt

local prompt_color="%(!.$PROMPT_FAILURE_COLOR.$PROMPT_PROMPT)"
local last_command_output="%(?.$PROMPT_SUCCESS_COLOR.$PROMPT_FAILURE_COLOR)"

PROMPT="%* \$elapsed%{$last_command_output%}%?%{$reset_color%} %{$prompt_color%}ᐅ%{$reset_color%} "
RPROMPT="%{$PROMPT_SUCCESS_COLOR%}$rc_hostname%(7/,%-4/...%2/,%~)%{$reset_color%}\$git_prompt"

ZSH_THEME_GIT_PROMPT_PREFIX="("
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$GIT_PROMPT_INFO%})"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$GIT_DIRTY_COLOR%}✘"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$GIT_CLEAN_COLOR%}✔"

ZSH_THEME_GIT_PROMPT_ADDED="%{$FG[082]%}+%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$FG[166]%}∆%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DELETED="%{$FG[160]%}x%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$FG[220]%}⇄%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_AHEAD="%{$FG[160]%}➚%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$FG[160]%}➘%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$FG[082]%}≠%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$FG[190]%}⁈%{$reset_color%}"
