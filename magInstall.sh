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

# Check if wallet is running
function check_process() {
	local check_command=$(ps ax | grep -v grep | grep $WALLET_DAEMON | wc -l)
	if [[ $check_command -eq 0 ]]; then
		echo 0
	else
		echo 1
	fi
}

# Parse JSON eg.: getinfo and get value for key
# parameters $1 = json string / $2 = key
function parse_json() {
	local json="$1";
	local key="$2";
	local result=$(<<<"$1" awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/\042'$2'\042/){print $(i+1)}}}' | tr -d '"' | sed -e 's/^[[:space:]]*//')
	echo $result
}

# Get blockheight from explorer
# curl with timeout
function getBlockCountFromExplorer() {
	local blockCount=0;
	local url="http://209.250.248.159:3001/api/getblockcount";
	blockCount=$(curl -s --connect-timeout 2 "$url")
        echo $blockCount;
}

# Reports status of magnet wallet
function magnet_status() {
	local width height result
	local result="MAGNET WALLET: ";

	width=$(tput cols)
	height=$(tput lines)
	if [[ $(check_process) -eq 1 ]]; then
		local current_block=$(parse_json "$($WALLET_DAEMON getinfo)" "blocks")
		result=$result$FONT_BOLD$FG_GREEN"running... block: $current_block"$FGBG_NORMAL;
	else
		result=$result$FONT_BOLD$FG_RED"not running"$FGBG_NORMAL;
	fi
	#tput cup $((height - 2)) 0
	echo "   $result"
}

# Checks distribution, returns 1 if we good and has global variables filled with info.
function check_distribution() {
	# check for distro
	if [[ -r /etc/os-release ]]; then
		. /etc/os-release
		if [[ "${NAME,,}" != "ubuntu" ]] ; then
			echo "$NAME is not supported!";
			return 0;
		fi
		if [[ "${VERSION_ID}" != "16.04" ]] && [[ "${VERSION_ID}" != "17.04" ]] && \
		   [[ "${VERSION_ID}" != "17.10" ]] && [[ "${VERSION_ID}" != "18.04" ]]; then
			echo "$NAME $VERSION_ID is not supported!";
			return 0;
		else
			echo -n "$FG_GREEN$NAME $VERSION_ID found..";
		fi
		return 1;
	fi
}

# Updates the ubunutu system
function update_ubuntusystem() {
	sudo apt-get -y update
        sudo apt-get -y upgrade
	echo " Done!";
}

# Installs needed libraries on ubunutu system
function install_libraries_ubunutu() {
	# Common packages
	sudo apt-get -yq install build-essential libtool automake autotools-dev autoconf pkg-config libssl-dev \
	libgmp3-dev libevent-dev bsdmainutils libboost-all-dev software-properties-common libminiupnpc-dev curl git unzip pwgen
	sudo add-apt-repository -yu ppa:bitcoin/bitcoin
	sudo apt-get -yq install libdb4.8-dev libdb4.8++-dev

	# Ubuntu 18.04 needs libssl 1.0.xx installed
	echo "$VERSION_ID";
	if [[ "${VERSION_ID}" == "18.04" ]] ; then
		sudo apt-get -yq install libssl1.0-dev
		sudo apt-mark hold libssl1.0-dev
	fi
}

# Yes its an infinity loop
function infinity_loop() {
        while true;
        do
                echo -n .;
                sleep 1;
        done
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
	2. UPDATE SYSTEM / INSTALL PACKAGES
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
	1)	check_distribution;
		exit_status=$?
		if [[ "$exit_status" -eq 1 ]]; then
			echo "INSTALLING";
		fi
		;;
	2)	echo -n "Updating system"
		#infinity_loop &
		#PID=$!
		# --- do something here ---
		#kill $PID; trap 'kill $PID' SIGTERM
		check_distribution;
		exit_status=$?
		if [[ "$exit_status" -eq 1 ]]; then
                        update_ubuntusystem;
			install_libraries_ubunutu;
                fi
		;;
	3)	echo "(3) Comming soon.."
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
