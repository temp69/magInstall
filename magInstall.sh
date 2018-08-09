#!/bin/bash

# MAGNET a menu driven install/update/config script
# temp@magnetwork.io
# v=0.1b, 08-2018

#################  DECALRED VARIABLES #############################
# Font & color
declare -r BG_BLUE="$(tput setab 4)"
declare -r BG_BLACK="$(tput setab 0)"
declare -r FG_GREEN="$(tput setaf 2)"
declare -r FG_WHITE="$(tput setaf 7)"
declare -r FG_CYAN="$(tput setaf 6)"
declare -r FG_YELLOW="$(tput setaf 3)"
declare -r FG_RED="$(tput setaf 1)"
declare -r FGBG_NORMAL="$(tput sgr0)"
declare -r FONT_BOLD="$(tput bold)"
declare -r FONT_BLINK="$(tput blink)"
# Wallet related
declare -r CURRENT_PATH="$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
declare -r WALLET_DOWNLOAD_DIR="$HOME/magnet"
declare -r WALLET_DAEMON="magnetd"
declare -r WALLET_INSTALL_DIR="/usr/local/bin"
declare -r WALLET_DATA_DIR="$HOME/.magnet"
declare -r WALLET_DOWNLOAD_FILE="magnet-qt-LINUX.tar.gz"
declare -r WALLET_DOWNLOAD_URL="https://magnetwork.io/Wallets/$WALLET_DOWNLOAD_FILE"
declare -r WALLET_BOOTSTRAP_FILE="bootstrap.zip"
declare -r WALLET_BOOTSTRAP_URL="https://magnetwork.io/Wallets/$WALLET_BOOTSTRAP_FILE"
###################################################################

#################  HELPER FUNCTIONS ###############################
# Show a magnet banner
function show_magnet_banner() {
	echo ${FONT_BOLD}${FG_YELLOW}
	cat <<- _EOF_

   ███╗   ███╗ █████╗  ██████╗ ███╗   ██╗███████╗████████╗
   ████╗ ████║██╔══██╗██╔════╝ ████╗  ██║██╔════╝╚══██╔══╝
   ██╔████╔██║███████║██║  ███╗██╔██╗ ██║█████╗     ██║
   ██║╚██╔╝██║██╔══██║██║   ██║██║╚██╗██║██╔══╝     ██║
   ██║ ╚═╝ ██║██║  ██║╚██████╔╝██║ ╚████║███████╗   ██║
   ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝

	_EOF_
	echo "$FGBG_NORMAL$FG_CYAN   MAGNET installation/update/config script"
	echo "$FGBG_NORMAL   email: temp@magnetwork.io"
}

# Check if magnet wallet is running
function check_process() {
	local check_command=$(ps ax | grep -v grep | grep $WALLET_DAEMON | wc -l)
	if [[ $check_command -eq 0 ]]; then
		echo 0
	else
		echo 1
	fi
}

# Parse JSON
function parse_json() {
	local json="$1";
	local key="$2";
	local result=$(<<<"$1" awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/\042'$2'\042/){print $(i+1)}}}' | tr -d '"' | sed -e 's/^[[:space:]]*//')
	echo $result
}

# Get blockheight from explorer
function getBlockCountFromExplorer() {
	local blockCount=0;
	local url="http://209.250.248.159:3001/api/getblockcount";
	blockCount=$(curl -s --connect-timeout 2 "$url")
        echo $blockCount;
}

# Reports status of magnet wallet
function magnet_status() {
	local width height result
	local result="MAGNET STATUS: ";

	width=$(tput cols)
	height=$(tput lines)
	if [[ $(check_process) -eq 1 ]]; then
		local current_block=$(parse_json "$($WALLET_DAEMON getinfo)" "blocks")
		result=$result$FG_GREEN"running... block: $current_block"$FGBG_NORMAL;
	else
		result=$result$FG_RED"not running"$FGBG_NORMAL;
	fi
	#tput cup $((height - 2)) 0
	echo "   $result"
}
###################################################################

################### MAIN ENTRY POINT ##############################
# Save screen
tput smcup

# Display menu until selection == 0
while [[ $REPLY != 0 ]]; do
	clear
	show_magnet_banner
	magnet_status
	echo -n ${FONT_BOLD}${FG_WHITE}
	cat <<- _EOF_

	1. INSTALL MAGNET WALLET
	2. XXXXXXXXXXXXXXXXX
	3. XXXXXXXXXXXXXXXXX
	8. EXPLORER BLOCKS
	9. MAGNET GETINFO
	0. Quit

	_EOF_
	read -p "Enter selection [0-3] > " selection

	# Clear area beneath menu
	tput cup 12 0
	echo -n ${FGBG_NORMAL}
	tput ed
	tput cup 13 0

	# Act on selection
	case $selection in
	1)	echo $CURRENT_PATH
		echo $WALLET_DOWNLOAD_URL
		echo $WALLET_DATA_DIR
		;;
	2)	df -h
		;;
	3)	if [[ $(id -u) -eq 0 ]]; then
			echo "Home Space Utilization (All Users)"
			du -sh /home/* 2> /dev/null
		else
			echo "Home Space Utilization ($USER)"
			du -s $HOME/* 2> /dev/null | sort -nr
		fi
		;;
	8)	explorer_blocks=$(getBlockCountFromExplorer);
		if [[ $explorer_blocks -gt 0 ]]; then
			echo "Explorer block heigth: $FG_GREEN$explorer_blocks$FGBG_NORMAL";
		else
			echo "Could not connect to explorer API!"
		fi
		;;
	9)	if [[ $(check_process) -eq 1 ]]; then
			mag_status_result=$($WALLET_DAEMON getinfo);
			echo "$mag_status_result";
		else
			echo "MAGNET daemon not running...."
		fi
		;;
	0)	break
		;;
	*)	echo "Invalid entry."
		;;
	esac
	printf "\nPress any key to continue."
	read -n 1
done

# Restore screen
tput rmcup
echo "Program terminated."
