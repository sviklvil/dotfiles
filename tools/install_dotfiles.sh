#!/bin/sh

set_colors() {
	# Use colors, but only if connected to a terminal, and that terminal supports them.
	if which tput >/dev/null 2>&1; then
		ncolors=$(tput colors)
	fi
	if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
		RED="$(tput setaf 1)"
		GREEN="$(tput setaf 2)"
		YELLOW="$(tput setaf 3)"
		BLUE="$(tput setaf 4)"
		BOLD="$(tput bold)"
		NORMAL="$(tput sgr0)"
	else
		RED=""
		GREEN=""
		YELLOW=""
		BLUE=""
		BOLD=""
		NORMAL=""
	fi
}

# Check if all tools needed for this script are installed.
check_requirements() {
	local status=0

	if ! which git >/dev/null 2>&1; then
		echo "${RED}Error: git is not installed!${NORMAL}"
		status=1
	elif [ "`uname -o`" = "Cygwin" ]; then
		# The Windows (MSYS) Git is not compatible with normal use on cygwin
		if git --version | grep msysgit > /dev/null; then
			echo "${RED}Error: Windows/MSYS Git is not supported on Cygwin${NORMAL}"
			echo "${RED}Error: Make sure the Cygwin git package is installed and is first on the path${NORMAL}"
			status=1
		fi
	fi

	return $status
}

bootstrap() {
	mkdir -p ~/bin ~/.src

	if [ -d ~/.src/vcsh && -d ~/.src/vcsh/.git ]; then
		git -C ~/.src/vcsh pull
	else
		git clone https://github.com/RichiH/vcsh.git ~/.src/vcsh
	fi
	VCSH=~/.src/vcsh/vcsh

	if [ -d ~/.src/myrepos && -d ~/.src/myrepos/.git ]; then
		git -C ~/.src/myrepos pull
	else
		git clone https://github.com/joeyh/myrepos.git ~/.src/myrepos
	fi
	MR=~/.src/myrepos/mr
}

main() {
	set_colors
	# Only enable exit-on-error after the non-critical colorization stuff,
	# which may fail on systems lacking tput or terminfo (in Cygwin provided by ncurses package)
	set -e
	check_requirements || exit $?
	bootstrap || exit $?

	$VCSH clone https://github.com/sviklvil/dotfiles.git
	if [ $? = 10 ]; then
		$VCSH dotfiles pull
	fi

	if [ "`uname -o`" = "Cygwin" ]; then
		$VCSH clone https://github.com/sviklvil/dotfiles_cygwin.git
		if [ $? = 10 ]; then
			$VCSH dotfiles_cygwin pull
		fi
	elif [ "`uname -o`" = "GNU/Linux" ]; then
		# http://www.freedesktop.org/software/systemd/man/os-release.html
		if [ -f "/etc/os-release" ]; then
			. "/etc/os-release"
		elif [ -f "/usr/lib/os-release" ]; then
			. "/usr/lib/os-release"
		fi
		if [ -n "$ID" && "$ID" = "gentoo" ]; then
			$VCSH clone https://github.com/sviklvil/dotfiles_gentoo.git
			if [ $? = 10 ]; then
				$VCSH dotfiles_gentoo pull
			fi
		fi
	fi
	# At this stage we also get all mrconfig files (from dotfiles* repos) so we can just rely on "mr checkout"
	$MR checkout
	echo "${GREEN}All dotfiles* and dependant upstream repos checked out.${NORMAL}"
}

main
