#!/usr/bin/env bash
#
# --------------------------------------------------------------------------------
# - 
# - GITLIB
# - Library of utility functions and standardizing for daily/commonly used
# - GIT commands
# - Version: 1.1-SENIOR
# - 
# - Author: Luiz Felipe Nazari
# -         luiz.nazari.42@gmail.com
# -         luiz.nazari@senior.com.br
# - All rights reserved.
# - 
# --------------------------------------------------------------------------------

# ------------------------------
# - Utility
# ------------------------------

# - Constants
# --------------------

GL_NO_COLOR="\033[0m"
GL_RED="\033[0;31m"
GL_GREEN="\033[0;32m"
GL_CYAN="\033[0;36m"
GL_YELLOW="\033[1;33m"

# - General functions
# --------------------

_log() {
    case $1 in
		err* )   str="ERROR"; level=0; logColor=$GL_RED; shift ;;
		war* )   str="WARN "; level=1; logColor=$GL_YELLOW; shift ;;
		inf* )   str="INFO "; level=2; logColor=$GL_GREEN; shift ;;
		debug* ) str="DEBUG"; level=3; logColor=$GL_CYAN; shift ;;
        *)       str=" G L "; level=0; logColor=$GL_NO_COLOR ;;
    esac
    
    if [ $GL_LOGLEVEL -ge $level ]; then
        echo -e "[$str] $logColor$@$GL_NO_COLOR"
    fi
}

_getopts() {
    echo "$@" | sed -E 's/(^|[[:space:]])[[:alpha:]]+//g'
}

# Returns the current branch name. e.g.: master
_get_curr_branch() {
	git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

_hasUnpushedCommitsFor() {
    [[ -n "$(git diff origin/HEAD..$1)" ]] && return 0 || return 1
}

_hasUnpushedCommits() {
    branch="$(_get_curr_branch)"
    return $(_hasUnpushedCommitsFor $branch)
}

# args:
# 	$1 - the text to be trimmed
_trim() {
    local text="$*"
    # remove leading whitespace characters
    text="${text#"${text%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    text="${text%"${text##*[![:space:]]}"}"   
    echo -n "$text"
}

# - Functions
# --------------------

# args:
# 	$1 - commit's message
_do_commit() {
	if [[ -z "$GL_TASK_PREFIX" ]]; then
		_log err "Task prefix not specified! Use 'gconfig task-prefix <prefix>' to configure."
		return "1"
	fi

	aborted=false
	commit_message=""

	# Auxiliar funcions are declared internally due to "returned values" and "echo" calls.
	# If functions are called inside a command substituion, echoed messages cannot be seen.

	_format_commit_message() {
		commit_refs=""
		commit_prefix=""

		_request_commit_prefix() {
			prefixes=(FIX FEAT TEST REFACTOR DOC REVERT)

			_select_option \
				"FIX - Correções." \
				"FEAT - Novas implementações (funcionalidades, telas, etc.)." \
				"TEST - Alterações referentes a testes (adicionar testes, corrigir antigos, refatorá-los, etc.)." \
				"REFACTOR - Refatoração de código existente (melhorar performance de um método, retirar duplicação de código, etc.)." \
				"DOC - Correção ou implementação de documentação." \
				"REVERT - Reverter algum commit anterior."

			selectedOption=$?
			commit_prefix="${prefixes[selectedOption]}"
		}

		_request_task_number() {
			task=""
			branch=$(_get_curr_branch);

			if [[ $branch == *b_task_* ]]; then
				task="${1#*b_task_}"
			fi

			if [ -z "$task" ]; then
			
				continue_msg="Continue? (y/n/comma separated task numbers)"
				echo "The task number could not be determined. $continue_msg"
				while true; do
					read -p "> " response

					if [[ $response =~ ^[YySs]$ ]]; then
						task=0
						break

					elif [[ $response =~ ^[Nn]$ ]]; then
						_log warn "Commit aborted"
						aborted=true
						return "1"

					elif [[ $response =~ ^[[:digit:][:space:],]{1,}$ ]]; then
						task="$response"
						break
					fi

					echo $continue_msg
				done
				
			fi

			commit_refs=$(_format_tasks_message "$task")
		}

		_request_commit_hash() {
			hash=""
			continue_msg="Continue? (n/commit hash)"
			echo "Insert the commit hash (SHA1 ID). $continue_msg"

			while true; do
				read -p "> " response

				if [[ -z $response ]]; then
					continue
				
				elif [[ $response =~ ^[Nn]$ ]]; then
					_log warn "Commit aborted"
					aborted=true
					return "1"
					
				else
					hash=$response
					break
				fi

				echo $continue_msg
			done

			commit_refs="$hash"
		}

		_request_commit_prefix
		if [[ "$commit_prefix" = "REVERT" ]]; then
			_request_commit_hash
		else
			_request_task_number
		fi

		commit_message="[$commit_prefix][$commit_refs]: $1"
	}

	# Commit logic:

	# Outputs to 'commit_message'
	_format_commit_message "$1"

	if [ "$aborted" = true ]; then
		return "1"
	fi

	_log debug "Commiting all files"
	_log debug "git add ."
	_log debug "git commit -m \"$commit_message\""
	
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		git add .
		git commit -m "$commit_message"
	fi
	
	#Returns the exit status of "git commit"
	return "$?"
}

# args:
# 	$1 - comma separated string containing the task numbers
_format_tasks_message() {
	IFS=',' read -ra taskNumbers <<< "$1"
	tasks_message=""

	for taskNumber in "${taskNumbers[@]}"; do
		tasks_message+="#$GL_TASK_PREFIX-$(_trim $taskNumber) "
	done

	expr "$(_trim $tasks_message)"
}