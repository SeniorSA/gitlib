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
# - GitLib
# ------------------------------

# - Global Variables
# --------------------

GL_TASK_PREFIX=""
GL_LOGLEVEL=2 #INFO

# - Commands
# --------------------

gcommit() {
	branch=$(_get_curr_branch);
	args=${@##-*}
	
	if [ -z "$branch" ]; then
        _log err "Current directory is not a git repository"
    	return "1"

    elif [ -z "$args" ]; then
        _log err "Please, insert a message to confirm the commit"
		return "1"

    else
		if ! _do_commit "$args"; then
			return "1"
		fi
		
		let "OPTIND = 1";
		while getopts "p" opcao
		do
			case "$opcao" in
				"p") gpush "$branch" ;;
				"?") _log warn "Unknown option \"$OPTARG\"" ;;
				":") _log err "Arguments not specified for option \"$OPTARG\"" ;;
			esac
		done
		
	fi
	
	return "0"
}

gpull() {
	if [ $# -eq 1 ]; then
		branch="$1"
	else
		branch=$(_get_curr_branch)
	fi
	
    if [ $branch == "." ]; then
        _log debug "Pulling from origin"
        _log debug "git pull origin"

		if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
        	git pull origin
		fi
        
    else
        _log debug "Pulling from branch $branch"
        _log debug "git pull origin $branch"

		if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
        	git pull origin "$branch"
		fi
    fi
}

gpush() {
	if [ $# -eq 1 ]; then
		branch="$1"
	else
		branch=$(_get_curr_branch)
	fi
	
	_log debug "Pushing to branch $branch"
	_log debug "git push origin $branch"
	
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		git push origin "$branch"
	fi
}

gout() {
	if [ $# -eq 1 ]; then
        _log debug "Switching current branch to $1"
        _log debug "git checkout $1"
		if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
			git checkout "$1"
		fi
        
	elif [ $# -eq 2 ]; then
        _log debug "Switching current branch to $2"
        _log debug "git checkout $1 $2"
		if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
			git checkout "$1" "$2"
		fi
        
	else
		_log err "Branch name not specified"
	fi
}

gmerge() {
	branch=$(_get_curr_branch)
	
	if [ -z "$branch" ]; then
        _log err "Current directory is not a git repository"
		
	elif [[ $# -gt 0 && -n $1 ]]; then
		_log info "Step 1: Pulling from current branch..."
		if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
			gpull
		fi
		
		_log info "Step 2: Merging $1 -> $branch"
		_log debug "git merge $1"
		if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
			git merge "$1"
		fi
		
	else
		_log err "Branch name not specified"
	fi
}

gstatus() {
    _log debug "git status"
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		git status
	fi
}

# Undo all local commits and changes (stagged and unstagged). 
greset() {
	continue_msg="(y/n)"
	echo "Are you sure you want to discard all local stagged and unstagged changes? This action cannot be undone. $continue_msg"

	while true; do
		read -p "> " response

		if [[ $response =~ ^[YySs]$ ]]; then
			_log debug "git checkout ."
			_log debug "git reset ."
			_log debug "git reset --soft HEAD"

			if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
				git checkout . 
				git reset .
				git reset --soft HEAD
			fi
			break

		elif [[ $response =~ ^[Nn]$ ]]; then
			_log warn "Reset aborted"
			return "1"
		fi

		echo $continue_msg
	done
}

# - Configurations
# --------------------

gconfig() {
	 case $1 in
        task-prefix )
            if [ -z "$2" ]; then
              _log err "Task prefix not specified."
            else
                GL_TASK_PREFIX=$2
            fi
            ;;

		loglevel )
            case $2 in
                err* )   let "GL_LOGLEVEL = 0" ;;
                war* )   let "GL_LOGLEVEL = 1" ;;
                inf* )   let "GL_LOGLEVEL = 2" ;;
                debug* ) let "GL_LOGLEVEL = 3" ;;
                *) _log err "Log level must be: error, warn, info or debug."
            esac
            ;;

        debug-mode )
            if [[ "$2" = false ]] || [[ "$2" = true ]]; then
                GL_DEBUG_MODE_ENABLED=$2
            fi
            ;;
            
		*) _log err "Configuration \"$1\" not found" ;;
	esac
}
