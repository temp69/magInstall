#!/bin/bash
###################################################
# MAGNET a menu driven install/update/config script
# author: 	temp@magnetwork.io
# version:	v=0.2b, 01-2019
# wallet: 	mag 1.0.0
declare -r SCRIPT_VERSION="0.2b"
####################################################

#################  DECLARED VARIABLES #############################
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
# Coin related
declare -r CURRENT_PATH="$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
declare -r WALLET_DOWNLOAD_DIR="$HOME/magnet"
declare -r WALLET_DAEMON="magd"
declare -r WALLET_CLI="mag-cli"
declare -r WALLET_PORT=17172
declare -r WALLET_INSTALL_DIR="/usr/local/bin"
declare -r WALLET_DATA_DIR="$HOME/.mag"
declare -r WALLET_DOWNLOAD_URL=$(curl -s https://api.github.com/repos/magnetwork/mag/releases/latest | grep browser_download_url | grep -e "x86_64-linux" | cut -d '"' -f 4)
declare -r WALLET_DOWNLOAD_FILE=$(echo $WALLET_DOWNLOAD_URL | cut -d '/' -f 9)
declare -r WALLET_BOOTSTRAP_URL=$(curl -s https://api.github.com/repos/magnetwork/mag/releases/latest | grep browser_download_url | grep -e "bootstrap" | cut -d '"' -f 4)
declare -r WALLET_BOOTSTRAP_FILE=$(echo $WALLET_BOOTSTRAP_URL | cut -d '/' -f 9)
declare -r WALLET_CONFIG_FILE="mag.conf"
declare -r WALLET_MASTERNODE_FILE="masternode.conf"
declare -r WALLET_ADDNODES_FILE="https://github.com/temp69/magInstall/releases/download/1/addnodes.txt"
declare -r EXPLORER_URL1="http://95.216.209.225"
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
   ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝ $SCRIPT_VERSION

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
	#local url="$EXPLORER_URL/api/getblockcount";
	local url=$1"/api/getblockcount";
	blockCount=$(curl -s --max-time 5 --connect-timeout 2 "$url")
	echo $blockCount;
}

# Reports status of magnet wallet
function magnet_status() {
	local result="MAGNET WALLET: ";
	if [[ $(check_process) -eq 1 ]]; then
		local current_block=$(parse_json "$($WALLET_CLI getinfo)" "blocks")
		result=$result$FONT_BOLD$FG_GREEN"running...block: $current_block"$FGBG_NORMAL;
		if [[ $($WALLET_CLI mnsync status 2>/dev/null | grep '\"IsBlockchainSynced\": true') ]]; then
			result=$result$FONT_BOLD$FG_GREEN" [synchronized]"$FGBG_NORMAL;
		else
			result=$result$FONT_BOLD$FG_RED" [still synchronizing]"$FGBG_NORMAL;
		fi
	else
		result=$result$FONT_BOLD$FG_RED"not running"$FGBG_NORMAL;
	fi
	echo "   $result"
	#loop
	#echo -ne "Current block: "`mag-cli getinfo | grep blocks | awk '{print $2}' | cut -d ',' -f 1`'\r'
}

# Checks distribution, returns 1 if we good and has global variables filled with info.
# Allowed: Ubunutu: 16.04 / 17.04 / 17.10 / 18.04
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
			echo "$FG_GREEN$NAME $VERSION_ID found..";
		fi
		return 1;
	fi
}

# Updates the ubunutu system
function update_ubuntusystem() {
	sudo apt-get -y update
	#sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
	sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
	sudo DEBIAN_FRONTEND=noninteractive apt-get -y install zip unzip curl pwgen
	sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove
	echo "Done!";
	if [[ -f /var/run/reboot-required ]]; then
		get_confirmation "${FONT_BOLD}${FG_RED}Some updates require a reboot, want todo it? [y/n]${FGBG_NORMAL}"
		if [ $? -eq 0 ]; then
			## check for wallet running
			if [[ $(check_process) -eq 1 ]]; then
                                 $WALLET_CLI stop;
				 sleep 2
                        fi
			sudo reboot;
			exit 0;
		fi
	fi
}

# Creates a swap space
function prepare_swap() {
	if free | awk '/^Swap:/ {exit !$2}'; then
		echo "Swap exists"
	else
		sudo dd if=/dev/zero of=/swapfile count=2048 bs=1M
		sudo chmod 600 /swapfile
		sudo mkswap /swapfile
		sudo swapon /swapfile
		sudo echo "/swapfile none swap sw 0 0" >> /etc/fstab
		sudo echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf
		sudo echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf
		echo "Swap with 2GB created"
	fi
}

# call with a prompt string or use a default
function get_confirmation() {
        read -r -p "${1:-Are you sure? [y/N]} " response
        case "$response" in
                [yY])
                        true
                        ;;
                *)
                        false
                        ;;
        esac
}

# Delete everything from the wallet directory and redownload/install wallet.
function update_wallets() {
        # if directory exists we delete it first
        if [ -d "$WALLET_DOWNLOAD_DIR" ]; then
                rm -rfv $WALLET_DOWNLOAD_DIR;
        fi
        mkdir -p $WALLET_DOWNLOAD_DIR;
        cd $WALLET_DOWNLOAD_DIR;
        wget $WALLET_DOWNLOAD_URL;
        tar -xvzf $WALLET_DOWNLOAD_FILE;
	local dist_wallet_daemon=$(find -name $WALLET_DAEMON);
	local dist_wallet_cli=$(find -name $WALLET_CLI);
        sudo cp $dist_wallet_daemon $dist_wallet_cli $WALLET_INSTALL_DIR
        if [ $? -eq 0 ]; then
                echo ${FONT_BOLD}${FG_WHITE};
                echo "Copied $FG_GREEN$dist_wallet_daemon & $dist_wallet_cli$FG_WHITE to $FG_GREEN$WALLET_INSTALL_DIR";
                echo ${FG_WHITE};
        fi
}

# Initial or updated download the wallets
function download_wallet_files() {
        if [[ -r "$WALLET_DOWNLOAD_DIR/$WALLET_DOWNLOAD_FILE" ]]; then
                echo $FONT_BOLD"The wallet download directory already exists $FG_RED$WALLET_DOWNLOAD_DIR$FG_WHITE";
                get_confirmation "Do you want to reinstall/update the wallet!? [y/n]"
                if [ $? -eq 0 ]; then
                        echo ${FGBG_NORMAL}${FG_GREEN};
                        update_wallets;
                fi
        else
                echo ${FGBG_NORMAL}${FG_GREEN};
                update_wallets;
        fi
}

# Create a fresh magnet.conf file in datadirectory
function fresh_magnet_conf() {
	mkdir -p $WALLET_DATA_DIR
	cd $WALLET_DATA_DIR
	wget $WALLET_BOOTSTRAP_URL
	unzip $WALLET_BOOTSTRAP_FILE
	RANDOM_RPC_USER=$(pwgen 8 1)
	RANDOM_RPC_PASS=$(pwgen 20 1)
	touch $WALLET_DATA_DIR/$WALLET_CONFIG_FILE
	cat > $WALLET_DATA_DIR/$WALLET_CONFIG_FILE <<- EOL
	rpcallowip=127.0.0.1
	rpcport=17103
	rpcuser=$RANDOM_RPC_USER
	rpcpassword=$RANDOM_RPC_PASS
	server=1
	daemon=1
	listen=1
	port=17172
	debug=all
	maxconnections=60
	addnode=207.148.28.61:17172
	addnode=45.32.199.183:17172
	addnode=35.190.191.73:17172
	addnode=66.42.84.233:17172
	addnode=207.148.7.57:17172
	addnode=45.77.200.138:17172
	addnode=104.238.145.183:17172
	addnode=95.179.199.60:17172
	addnode=149.28.247.127:17172
	EOL
}

# Updates addnodes
function update_addnodes() {
	local NODES=$(wget $WALLET_ADDNODES_FILE -qO -);
	if [[ "${NODES}" =~ ^addnode=[\d\.]+* ]]; then
		#echo "$NODES";
		local FILE=$WALLET_DATA_DIR"/"$WALLET_CONFIG_FILE;
		# Remove all addnode entries
		sed -i '/addnode/d' $FILE;
		# Add all addnode entries
		cat >> $FILE <<- EOF
		${NODES}
		EOF
		echo ${FONT_BOLD}${FG_WHITE};
		echo "Updated addnodes in $FG_GREEN$WALLET_CONFIG_FILE$FG_WHITE as well!";
        fi
}

# Resyncs the blockchain
function resync_blockchain() {
	echo ${FGBG_NORMAL}${FG_GREEN};
	cd $WALLET_DATA_DIR
	#rm -rfv !("magnet.conf"|"masternode.conf"|"wallet.dat")
	find -maxdepth 1 ! -name mag.conf ! -name masternode.conf ! -name wallet.dat ! -name backup ! -name . -exec rm -rv {} \;
	wget $WALLET_BOOTSTRAP_URL
	unzip $WALLET_BOOTSTRAP_FILE
	echo ${FONT_BOLD}${FG_WHITE};
	echo "All but those files were deleted:$FG_GREEN mag.conf / masternode.conf / wallet.dat$FG_WHITE";
	echo "Redownloaded the$FG_GREEN bootstrap file!";
	#update_addnodes;
}

# Initializes the datadirectory
function prepare_datadir() {
	# No datadirectory -> fresh installation needed
	if [ ! -d "$WALLET_DATA_DIR" ]; then
		echo ${FG_WHITE}"Fresh Installation";
		echo ${FGBG_NORMAL}${FG_GREEN};
		fresh_magnet_conf;
		echo -n ${FONT_BOLD}${FG_WHITE}
	else
		echo ${FONT_BOLD}${FG_RED}"There is already a data-directory present"${FG_WHITE};
		get_confirmation "Do you want to resync the blockchain? [y/n]"
		if [ $? -eq 0 ]; then
			resync_blockchain;
		fi
	fi
}

# Asks for masternode privkey to be entered into mag.conf
function masternode_entries() {
	#local NODEIP=$(curl -s4 api.ipify.org)
	local NODEIP=$(curl -s4 ipinfo.io/ip)
	local MNPRIVKEY="";
	#while [ -z "${MNPRIVKEY// }" ] && [[ $MNPRIVKEY =~ ^3[npo][1-9A-HJ-NP-Za-km-z]{49} ]]; do
	while [[ ! $MNPRIVKEY =~ ^5[mn][1-9A-HJ-NP-Za-km-z]{49} ]]; do
		echo ${FG_GREEN}"Enter your masternode private key:"${FG_WHITE};
		read MNPRIVKEY;
		if [[ ! $MNPRIVKEY =~ ^5[mn][1-9A-HJ-NP-Za-km-z]{49} ]]; then
			echo ${FG_WHITE}"Key: "${FG_RED}$MNPRIVKEY${FG_WHITE}" is not valid!"
		fi
	done
	local MNADDR=$NODEIP:$WALLET_PORT;
	echo ${FGBG_NORMAL}${FG_GREEN};
	echo "externalip="$NODEIP;
	echo "masternode=1";
	echo "masternodeaddr="$MNADDR;
	echo "masternodeprivkey="$MNPRIVKEY;
	echo ${FONT_BOLD}${FG_WHITE};
	get_confirmation "Add those entries to ${FG_GREEN}mag.conf${FG_WHITE}? [y/n]"
	if [ $? -eq 0 ]; then
		# Remove all old masternode entries
		sed -i '/masternode/d' $FILE;
		sed -i '/externalip/d' $FILE;
		# Add entries
		cat >> $FILE <<- EOF
		externalip=$NODEIP
		masternode=1
		masternodeaddr=$MNADDR
		masternodeprivkey=$MNPRIVKEY
		EOF
		echo ${FONT_BOLD}${FG_GREEN};
		echo "1) Restart this wallet now, so the configuration takes effect!"
		echo "2) Configure your controller wallet's masternode.conf file and restart coldwallet"
		echo "3) Unlock controller wallet and hit [Start]"${FG_WHITE}
	fi
}

# Main masternode function
function config_masternode() {
	local STRING="masternode=1";
	local FILE=$WALLET_DATA_DIR"/"$WALLET_CONFIG_FILE;
	if [ ! -z $(grep "$STRING" "$FILE") ]; then
 		# Masternode entries already found
		get_confirmation "Masternode entries found, overwrite them? [y/n]"
		if [ $? -eq 0 ]; then
			masternode_entries;
		fi
	else
		# Fresh masternode entries needed.
		masternode_entries;
	fi
}

# Checks if there is a new version of the script
function checkForUpdatedScript(){
	local SCRIPTNAME=$(basename "$0")
	local BRANCH="master"

	git fetch
	if [[ -n $(git diff --name-only origin/$BRANCH | grep $SCRIPTNAME) ]]; then
		echo ${FONT_BOLD}${FG_WHITE}${BG_BLUE};
		echo "New magInstall script available press ${FG_RED}<v>${FG_WHITE} in the menu to update!";
		echo ${FGBG_NORMAL};
		read -p "Press <ENTER> to continoue"
	fi
}

# Automatic update function
function self_update() {
	local SCRIPT=$(readlink -f "$0")
	local SCRIPTNAME=$(basename "$0")
	local ARGS="$@"
	local BRANCH="master"

	echo "Script is in: "$SCRIPT;
	echo "Scriptname to check: "$SCRIPTNAME;
	echo "Branch: "$BRANCH;
	echo ${FGBG_NORMAL}${FG_GREEN};

	git fetch
	if [[ -n $(git diff --name-only origin/$BRANCH | grep $SCRIPTNAME) ]]; then
		echo ${FONT_BOLD}${FG_WHITE};
		get_confirmation "New script available, update it? [y/n]"
		if [ $? -eq 0 ]; then
                        git pull --force
			git checkout $BRANCH
			git pull --force
			exec "$SCRIPT" "$@"
			exit 1
                fi
	else
		echo -n ${FONT_BOLD}${FG_WHITE};
		echo "Script version checked, uptodate!!";
	fi
}

# Adds a job to crontab to restart wallet 
function magnetAutostartOnReboot() {
	## find entry in cronttab
	## no entry found, add it
	local cronCommand="/usr/local/bin/$WALLET_DAEMON";
	local cronJob="@reboot $cronCommand";
	( sudo crontab -l | grep -v -F "$cronCommand" ; echo "$cronJob" ) | ( sudo crontab - )
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
# Check for new script
clear
checkForUpdatedScript
# Save screen
tput smcup

#if [[ $EUID -ne 0 ]]; then
#   echo "This script must be run as root" 1>&2
#   exit 1
#fi

# Display menu until selection == 0
while [[ $REPLY != 0 ]]; do
	clear
	show_magnet_banner
	magnet_status
	echo -n ${FONT_BOLD}${FG_WHITE}
	cat <<- _EOF_

	1. UPDATE SYSTEM
	2. INSTALL|UPDATE|RESYNC MAGNET
	---------------------------
	3. START|STOP MAGNET WALLET
	4. MASTERNODE CONFIG
	--------------------
	7. EDIT mag.conf
	8. MASTERNODE STATUS
	9. WALLET STATUS
	0. Quit

	_EOF_
	read -p "Enter selection [0-9] > " selection

	# Clear area beneath menu
	tput cup 12 0
	echo -n ${FGBG_NORMAL}
	tput ed
	tput cup 13 0

	# Act on selection
	case $selection in
        1)      echo "Updating system"
                #infinity_loop &
                #PID=$!
                # --- do something here ---
                #kill $PID; trap 'kill $PID' SIGTERM
                check_distribution;
                exit_status=$?
                if [[ "$exit_status" -eq 1 ]]; then
                        update_ubuntusystem;
                        echo -n ${FG_WHITE};
                fi
                ;;
	2)	check_distribution;
		exit_status=$?
		if [[ "$exit_status" -eq 1 ]]; then
			if [[ $(check_process) -eq 1 ]]; then 
                                echo -n ${FONT_BOLD}${FG_RED};
                                echo "MAGNET daemon is running, stop it before updating...."
                                echo -n ${FG_WHITE};
                        else
                                echo "INSTALLING";
                                prepare_swap;
                                download_wallet_files;
				prepare_datadir;
				magnetAutostartOnReboot;
                        fi
		fi
		;;
	3)	if [[ -r "$WALLET_INSTALL_DIR/$WALLET_DAEMON" ]]; then
                        if [[ $(check_process) -eq 1 ]]; then
                                echo -n ${FONT_BOLD}${FG_RED};
                                $WALLET_CLI stop;
                                sleep 1;
				until [[ ! $(/usr/bin/pgrep -x "magd") > /dev/null ]]; do
					echo -n .;
					sleep 1;
				done
				echo -n ${FG_WHITE};
                        else
                                echo -n ${FONT_BOLD}${FG_GREEN};
                                $WALLET_DAEMON;
                                sleep 1;
				until [[ $($WALLET_CLI getinfo 2>/dev/null | grep \"version\" | wc -l) -eq 1 ]]; do
					echo -n .;
					sleep 1;
				done
				echo -n ${FG_WHITE};
                        fi
                else
                        echo "Could not locate $FG_RED$FONT_BOLD$WALLET_DAEMON$FGBG_NORMAL at $FG_RED$FONT_BOLD$WALLET_INSTALL_DIR$FGBG_NORMAL";
			# TBD -> check if wallet is running regardless, from old setup instructions and ask if we should kill it with fire
                fi
		;;
	4)	check_distribution;
                exit_status=$?
		if [[ "$exit_status" -eq 1 ]]; then
			if [[ -r "$WALLET_DATA_DIR/$WALLET_CONFIG_FILE" ]]; then
				echo ${FONT_BOLD}${FG_GREEN};
				echo "Its suggested to proceed only after your wallet's blockchain";
				echo "is fully synchronized. You can check with option (9)";
				echo -n ${FG_WHITE};
				get_confirmation "Do you want to proceed? [y/n]"
				if [ $? -eq 0 ]; then
					config_masternode;
				fi
			else
				echo ${FONT_BOLD}${FG_WHITE}"Could not locate $FG_RED$WALLET_DATA_DIR/$WALLET_CONFIG_FILE$FGBG_NORMAL, install the wallet first";
			fi
		fi
		;;
	7)	if [[ $(check_process) -eq 1 ]]; then
			echo -n ${FONT_BOLD}${FG_RED};
			echo "MAGNET daemon is running, stop it before editing mag.conf file...."
			echo -n ${FG_WHITE};
		else
			nano "$WALLET_DATA_DIR/$WALLET_CONFIG_FILE";
		fi
		;;
	8)	if [[ $(check_process) -eq 1 ]]; then
                        mag_status_result=$($WALLET_CLI masternode status 2>&1);
			mag_status_result=$mag_status_result$'\n\n'$($WALLET_CLI masternode debug 2>&1);
                        echo -n ${FONT_BOLD}${FG_GREEN};
                        echo "$mag_status_result";
                        echo -n ${FG_WHITE};
                else
                        echo -n ${FONT_BOLD}${FG_RED};
                        echo "Magnet wallet not running...."
                        echo -n ${FG_WHITE};
                fi
		;;
	9)	if [[ $(check_process) -eq 1 ]]; then
			mag_status_result=$($WALLET_CLI getinfo);
			echo -n ${FONT_BOLD}${FG_GREEN};
			echo "$mag_status_result";
			echo -n ${FG_WHITE};
		else
			echo -n ${FONT_BOLD}${FG_RED};
			echo "Magnet wallet not running...."
			echo -n ${FG_WHITE};
		fi
		explorer_blocks=$(getBlockCountFromExplorer $EXPLORER_URL1);
                if [[ $explorer_blocks -gt 0 ]]; then
			echo "";
                        echo $FG_WHITE"Explorer block height: $FG_GREEN$explorer_blocks";
                else
                        echo "Could not connect to $FG_RED$EXPLORER_URL1$FG_WHITE API!"
                fi
		echo ${FG_WHITE};
		;;
	0)	break
		;;
        v)      echo "CURRENT_PATH: "$CURRENT_PATH;
                echo "WALLET_DOWNLOAD_DIR: "$WALLET_DOWNLOAD_DIR
                echo "WALLET_DAEMON: "$WALLET_DAEMON
		echo "WALLET_CLI: "$WALLET_CLI
                echo "WALLET_INSTALL_DIR: "$WALLET_INSTALL_DIR
                echo "WALLET_DOWNLOAD_FILE: "$WALLET_DOWNLOAD_FILE
                echo "WALLET_DOWNLOAD_URL: "$WALLET_DOWNLOAD_URL
                echo "WALLET_BOOTSTRAP_FILE: "$WALLET_BOOTSTRAP_FILE
                echo "WALLET_BOOTSTRAP_URL: "$WALLET_BOOTSTRAP_URL
		#echo "WALLET_ADDNODES_FILE: "$WALLET_ADDNODES_FILE
                echo "EXPLORER_URL1: "$EXPLORER_URL1
		echo ""
		self_update;
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
