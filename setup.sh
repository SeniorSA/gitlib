#!/usr/bin/sh
#
# --------------------------------------------------------------------------------
# - 
# - GITLIB
# - Library of utility functions and standardizing for daily/commonly used
# - GIT commands
# - Version: 1.0
# - 
# - Author: Luiz Felipe Nazari
# -        luiz.nazari.42@gmail.com
# - All rights reserved.
# - 
# --------------------------------------------------------------------------------

# ------------------------------
# - Instalation
# ------------------------------

# Include the installation file within your ~/.bash_profile or ~/.bashrc file
# source <path_to_gitlib>/install.sh

# You can also add configuration commands, such as:
# gconfig loglevel debug

# - Sources
# --------------------

GL_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$GL_SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    GL_SOURCE="$(readlink "$GL_SOURCE")"
done
GL_SOURCE_DIR="$( dirname "$GL_SOURCE" )/src"

if [ -d "$GL_SOURCE_DIR" ]; then
	source $GL_SOURCE_DIR/gitlib-utils.sh
	source $GL_SOURCE_DIR/gitlib.sh
	source $GL_SOURCE_DIR/gitlib-help.sh
else
	echo "[ERROR] GitLib could not be loaded: Unable to locate source directory: \"$GL_SOURCE_DIR\""
fi

# Further configurations are not necessary
# For more information see the README.md
