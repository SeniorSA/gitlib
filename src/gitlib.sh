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

GL_DEFAULT_TASK_PREFIX=""
GL_LOGLEVEL=2 #INFO

# - Commands
# --------------------

gcommit() {
	branch=$(_get_current_git_branch);
	args=${@##-*}
	
	if [ -z "$branch" ]; then
        _log err "Current directory is not a git repository"
    	return "1"

    elif [ -z "$args" ]; then
        _log err "Please, insert a message to confirm the commit"
		return "1"

    else
		auto_push=false
		stagged_only=false

		let "OPTIND = 1";
		while getopts "ps" opcao
		do
			case "$opcao" in
				"s") stagged_only=true ;;
				"p") auto_push=true ;;
				"?") _log warn "Unknown option \"$OPTARG\"" ;;
				":") _log err "Arguments not specified for option \"$OPTARG\"" ;;
			esac
		done

		if ! _do_commit "$args" $stagged_only; then
			return "1"
		fi

		if [ "$auto_push" = true ]; then
			gpush "$branch"
		fi
		
	fi
	
	return "0"
}

gpull() {
	if [ $# -eq 1 ]; then
		branch="$1"
	else
		branch=$(_get_current_git_branch)
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
		branch=$(_get_current_git_branch)
	fi
	
	_log debug "Pushing to branch $branch"
	_log debug "git push origin $branch"
	
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		git push origin "$branch"
	fi
}

# -l: choose branch to checkout
gout() {
	branch_to_checkout=""

	let "OPTIND = 1";
	while getopts "l" opcao
	do
		case "$opcao" in
			"l") _choose_branch branch_to_checkout ;;
		esac
	done

	if [ $# -eq 1 ]; then
		if [ -z "$branch_to_checkout" ]; then
			branch_to_checkout="$1"
		fi

        _log info "Switching current branch to $branch_to_checkout"
        _log debug "git checkout $branch_to_checkout"
		if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
			git checkout "$branch_to_checkout"
		fi
        
	elif [ $# -eq 2 ]; then
        _log info "Switching current branch to $2"
        _log debug "git checkout $1 $2"
		if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
			git checkout "$1" "$2"
		fi
        
	else
		_log err "Branch name not specified"
	fi
}

# -l: choose branch to merge
gmerge() {
	current_branch=$(_get_current_git_branch)
	branch_to_merge=""

	if [ -z "$current_branch" ]; then
        _log err "Current directory is not a git repository"
	fi

	let "OPTIND = 1";
	while getopts "l" opcao
	do
		case "$opcao" in
			"l") _choose_branch branch_to_merge ;;
		esac
	done

	if [[ -z "$branch_to_merge" && $# -eq 1 && "$1" != "-l" ]]; then
		branch_to_merge="$1"
	fi

	if [ -z "$branch_to_merge" ]; then
		_log err "Branch to merge not specified"
		return 1;
	fi

	_log info "Step 1: Pulling from current branch..."
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		gpull
	fi
	
	_log info "Step 2: Merging $branch_to_merge -> $current_branch"
	_log debug "git merge $branch_to_merge"
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		git merge "$branch_to_merge"
	fi
}

gstatus() {
    _log debug "git status"
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		git status
	fi
}

glog() {
	all_authors=false
	
	let "OPTIND = 1";
	while getopts "a" opcao
	do
		case "$opcao" in
			"a") all_authors=true ;;
		esac
	done

	git_username=""
	if [ "$all_authors" = false ]; then
		git_username="$(git config user.name)"
	fi

	date_format="%d/%m/%Y-%H:%M:%S"
	log_format="%C(yellow)%h%x20%Cgreen%an%Creset%x20%ad%x20%n%s%n"

	_log debug "git log --author=\"$git_username\" --pretty=format:\"$log_format\" --date=format:\"$date_format\""
	if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
		git log --author="$git_username" --pretty=format:"$log_format" --date=format:"$date_format"
	fi
}

gbranch() {
	delete_local=false
	delete_remote=false

	let "OPTIND = 1";
	while getopts "dD" opcao
	do
		case "$opcao" in
			"d" )
				delete_local=true
				echo -e "Which branch do you want do delete ${GL_BOLD}LOCALLY${GL_NO_COLOR}?"
				_choose_branch selected_branch

				_log debug "git branch -d $selected_branch"
				if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
					git branch -d "$selected_branch"
				fi
				;;
			"D" )
				delete_remote=true
				echo -e "Which branch do you want do delete ${GL_BOLD}REMOTELY${GL_NO_COLOR}?"
				_choose_branch selected_branch

				if _yes_no "Are you sure you want to delete remote branch "$selected_branch"? This action cannot be undone."; then
					_log debug "git push origin --delete $selected_branch"
					if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
						git push origin --delete "$selected_branch"
					fi
				else
					_log warn "Remote branch deletion aborted."
				fi
				;;
			"?" ) _log warn "Unknown option \"$OPTARG\"" ;;
			":" ) _log err "Arguments not specified for option \"$OPTARG\"" ;;
		esac
	done

	if [ "$delete_local" = false ] && [ "$delete_remote" = false ]; then
		_log debug "git branch --list"
		git branch --list
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
			_log debug "git reset --hard HEAD"

			if [ "$GL_DEBUG_MODE_ENABLED" = false ]; then
				git checkout . 
				git reset .
				git reset --hard HEAD
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
        default-task-prefix )
			GL_DEFAULT_TASK_PREFIX=$2
            ;;

		loglevel )
            case $2 in
                err* )   let "GL_LOGLEVEL = 0" ;;
                war* )   let "GL_LOGLEVEL = 1" ;;
                inf* )   let "GL_LOGLEVEL = 2" ;;
                debug* ) let "GL_LOGLEVEL = 3" ;;
                *) _log err "Log level must be: error/err, warn/war, info/inf or debug."
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
