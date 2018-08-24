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
# Coin related
declare -r CURRENT_PATH="$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
declare -r WALLET_DOWNLOAD_DIR="$HOME/magnet"
declare -r WALLET_DAEMON="magnetd"
declare -r WALLET_PORT=17177
declare -r WALLET_INSTALL_DIR="/usr/local/bin"
declare -r WALLET_DATA_DIR="$HOME/.magnet"
declare -r WALLET_DOWNLOAD_FILE="magnet_wallets.tar.gz"
declare -r WALLET_DOWNLOAD_URL="https://github.com/temp69/magInstall/releases/download/1/$WALLET_DOWNLOAD_FILE"
declare -r WALLET_BOOTSTRAP_FILE="bootstrap.zip"
declare -r WALLET_BOOTSTRAP_URL="https://magnetwork.io/Wallets/$WALLET_BOOTSTRAP_FILE"
declare -r WALLET_CONFIG_FILE="magnet.conf"
declare -r WALLET_MASTERNODE_FILE="masternode.conf"
declare -r WALLET_ADDNODES_FILE="https://github.com/temp69/magInstall/releases/download/1/addnodes.txt"
declare -r EXPLORER_URL1="http://35.202.4.153:3001"
declare -r EXPLORER_URL2="http://209.250.248.159:3001"
declare -r YIIMP_POOL_URL1="http://magnetpool.io"
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

# Get blockheight from YIIMP pool
# curl with timeout
function getBlockCountFromPool() {
        local pool_info=0;
        #local url="http://magnetpool.io/api/currencies";
        local url=$1"/api/currencies";
        pool_info=$(curl -s --connect-timeout 2 "$url");
        local pblock_count=$(parse_json "$pool_info" "height");
        echo $pblock_count;
}

# Get blockheight from explorer
# curl with timeout
function getBlockCountFromExplorer() {
	local blockCount=0;
	#local url="$EXPLORER_URL/api/getblockcount";
	local url=$1"/api/getblockcount";
	blockCount=$(curl -s --connect-timeout 2 "$url")
	echo $blockCount;
}

# Reports status of magnet wallet
function magnet_status() {
	local result="MAGNET WALLET: ";
	if [[ $(check_process) -eq 1 ]]; then
		local current_block=$(parse_json "$($WALLET_DAEMON getinfo)" "blocks")
		result=$result$FONT_BOLD$FG_GREEN"running... block: $current_block"$FGBG_NORMAL;
	else
		result=$result$FONT_BOLD$FG_RED"not running"$FGBG_NORMAL;
	fi
	echo "   $result"
	#loop
	#echo -ne "Current block: "`magnetd getinfo | grep blocks | awk '{print $3}' | cut -d ',' -f 1`'\r'
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
	#sudo apt-get -y upgrade
	sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
	echo " Done!";
}

# Installs needed libraries on ubunutu system
function install_libraries_ubunutu() {
	# Common packages
	sudo apt-get -yq install build-essential libtool automake autotools-dev autoconf pkg-config libssl-dev wget tar \
	libgmp3-dev libevent-dev bsdmainutils libboost-all-dev software-properties-common libminiupnpc-dev curl git unzip pwgen
	#sudo apt-get -yq install qtbase5-dev
	sudo add-apt-repository -yu ppa:bitcoin/bitcoin
	sudo apt-get -yq install libdb4.8-dev libdb4.8++-dev

	# Ubuntu 18.04 needs libssl 1.0.xx installed
	echo "$VERSION_ID";
	if [[ "${VERSION_ID}" == "18.04" ]] ; then
		sudo apt-get -yq install libssl1.0-dev
		sudo apt-mark hold libssl1.0-dev
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
        local dist_wallet="$HOME/magnet/magnet_wallets/"
        case "$VERSION_ID" in
                "16.04")        dist_wallet=$dist_wallet"ubuntu_16_04/$WALLET_DAEMON";
                                ;;
                "17.04")        dist_wallet=$dist_wallet"ubuntu_17_04/$WALLET_DAEMON";
                                ;;
                "17.10")        dist_wallet=$dist_wallet"ubuntu_17_10/$WALLET_DAEMON";
                                ;;
                "18.04")        dist_wallet=$dist_wallet"ubuntu_18_04/$WALLET_DAEMON";
                                ;;
                *)              echo "$VERSION_ID not found...";
                                ;;
        esac
        sudo cp $dist_wallet $WALLET_INSTALL_DIR
        if [ $? -eq 0 ]; then
                echo ${FONT_BOLD}${FG_WHITE};
                echo "Copied $FG_GREEN$WALLET_DAEMON$FG_WHITE from $FG_GREEN$dist_wallet$FG_WHITE to $FG_GREEN$WALLET_INSTALL_DIR";
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
	touch $WALLET_DATA_DIR/magnet.conf
	cat > $WALLET_DATA_DIR/magnet.conf <<- EOL
	rpcallowip=127.0.0.1
	rpcport=17179
	rpcuser=$RANDOM_RPC_USER
	rpcpassword=$RANDOM_RPC_PASS
	server=1
	daemon=1
	listen=1
	staking=0
	port=17177
	debug=all
	maxconnections=125
	addnode=45.76.81.227:17177
	addnode=104.207.151.96:17177
	addnode=45.32.140.188:17177
	addnode=108.61.209.211:17177
	addnode=107.191.62.63:17177
	addnode=45.32.48.202:17177
	addnode=108.61.176.156:17177
	addnode=45.77.7.202:17177
	addnode=45.76.130.131:17177
	addnode=45.77.138.103:17177
	addnode=104.238.188.10:17177
	addnode=45.77.232.192:17177
	addnode=209.250.239.217:17177
	addnode=209.222.30.95:17177
	addnode=104.238.165.132:17177
	addnode=108.61.208.135:17177
	addnode=144.202.71.114:17177
	addnode=45.63.42.106:17177
	addnode=209.250.242.7:17177
	addnode=207.246.124.100:17177
	addnode=45.76.83.24:17177
	addnode=207.246.117.153:17177
	addnode=45.77.163.102:17177
	addnode=45.63.111.17:17177
	addnode=104.238.137.11:17177
	addnode=140.82.35.120:17177
	addnode=104.156.231.73:17177
	addnode=45.32.132.121:17177
	addnode=45.32.132.201:17177
	addnode=144.202.101.179:17177
	addnode=144.202.90.252:17177
	addnode=45.76.241.191:17177
	addnode=144.202.91.240:17177
	addnode=45.76.244.72:17177
	addnode=144.202.81.254:17177
	addnode=45.63.37.72:17177
	addnode=104.238.153.185:17177
	addnode=45.77.214.85:17177
	addnode=45.77.208.101:17177
	addnode=144.202.87.162:17177
	addnode=217.163.23.170:17177
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
	find -maxdepth 1 ! -name magnet.conf ! -name masternode.conf ! -name wallet.dat ! -name backup ! -name . -exec rm -rv {} \;
	wget $WALLET_BOOTSTRAP_URL
	unzip $WALLET_BOOTSTRAP_FILE
	echo ${FONT_BOLD}${FG_WHITE};
	echo "All but those files were deleted:$FG_GREEN magnet.conf / masternode.conf / wallet.dat$FG_WHITE";
	echo "Redownloaded the$FG_GREEN bootstrap file!";
	update_addnodes;
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

# Asks for masternode privkey to be entered into magnet.conf
function masternode_entries() {
	#local NODEIP=$(curl -s4 api.ipify.org)
	local NODEIP=$(curl -s4 ipinfo.io/ip)
	local MNPRIVKEY="";
	#while [ -z "${MNPRIVKEY// }" ] && [[ $MNPRIVKEY =~ ^3[npo][1-9A-HJ-NP-Za-km-z]{49} ]]; do
	while [[ ! $MNPRIVKEY =~ ^3[npo][1-9A-HJ-NP-Za-km-z]{49} ]]; do
		echo ${FG_GREEN}"Enter your masternode private key:"${FG_WHITE};
		read MNPRIVKEY;
		if [[ ! $MNPRIVKEY =~ ^3[npo][1-9A-HJ-NP-Za-km-z]{49} ]]; then
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
	get_confirmation "Add those entries to ${FG_GREEN}magnet.conf${FG_WHITE}? [y/n]"
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
		echo "1) Restart this wallet now, so this configuration takes effect!"
		echo "2) Configure your coldwallet's masternode.conf file and restart coldwallet"
		echo "3) Unlock coldwallet and hit [Start]"${FG_WHITE}
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

# Automatic update function
function self_update() {
	local SCRIPT=$(readlink -f "$0")
	local SCRIPTNAME=$(basename "$0")
	local ARGS="$@"
	local BRANCH="master"

	echo $SCRIPT;
	echo $SCRIPTNAME;

	git fetch
	if [[ -n $(git diff --name-only origin/$BRANCH | grep $SCRIPTNAME) ]]; then
		get_confirmation "New script available, update it? [y/n]"
		if [ $? -eq 0 ]; then
                        git pull --force
			git checkout $BRANCH
			git pull --force
			exec "$SCRIPT" "$@"
			exit 1
                fi
	else
		echo "Script version checked, uptodate!!";
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

	1. UPDATE SYSTEM & INSTALL PACKAGES
	2. INSTALL|UPDATE|RESYNC MAGNET
	---------------------------
	3. START|STOP MAGNET WALLET
	4. MASTERNODE CONFIG
	--------------------
	7. EDIT magnet.conf
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
                        install_libraries_ubunutu;
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
                        fi
		fi
		;;
	3)	if [[ -r "$WALLET_INSTALL_DIR/$WALLET_DAEMON" ]]; then
                        if [[ $(check_process) -eq 1 ]]; then
                                echo -n ${FONT_BOLD}${FG_RED};
                                $WALLET_DAEMON stop;
                                sleep 1;
				echo -n ${FG_WHITE};
                        else
                                echo -n ${FONT_BOLD}${FG_GREEN};
                                $WALLET_DAEMON;
                                sleep 1;
				until [[ $($WALLET_DAEMON getinfo 2>/dev/null | grep \"version\" | wc -l) -eq 1 ]]; do
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
			echo "MAGNET daemon is running, stop it before editing magnet.conf file...."
			echo -n ${FG_WHITE};
		else
			nano "$WALLET_DATA_DIR/$WALLET_CONFIG_FILE";
		fi
		;;
	8)	if [[ $(check_process) -eq 1 ]]; then
                        mag_status_result=$($WALLET_DAEMON masternode status);
			mag_status_result=$mag_status_result$'\n\n'$($WALLET_DAEMON masternode debug);
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
			mag_status_result=$($WALLET_DAEMON getinfo);
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
                        echo $FG_WHITE"Explorer1 block height: $FG_GREEN$explorer_blocks";
                else
                        echo "Could not connect to $FG_RED$EXPLORER_URL1$FG_WHITE API!"
                fi
                explorer_blocks=$(getBlockCountFromExplorer $EXPLORER_URL2);
                if [[ $explorer_blocks -gt 0 ]]; then
                        echo $FG_WHITE"Explorer2 block height: $FG_GREEN$explorer_blocks";
                else
                        echo "Could not connect to $FG_RED$EXPLORER_URL2$FG_WHITE API!"
                fi
		pool_blocks=$(getBlockCountFromPool $YIIMP_POOL_URL1);
		if [[ $pool_blocks -gt 0 ]]; then
			echo $FG_WHITE"YIIMP pool block height: $FG_GREEN$pool_blocks";
		else
			echo "Could not connect to $FG_RED$YIIMP_POOL_URL1$FG_WHITE API!"
		fi
		echo ${FG_WHITE};
		;;
	0)	break
		;;
        v)      echo "CURRENT_PATH: "$CURRENT_PATH;
                echo "WALLET_DOWNLOAD_DIR: "$WALLET_DOWNLOAD_DIR
                echo "WALLET_DAEMON: "$WALLET_DAEMON
                echo "WALLET_INSTALL_DIR: "$WALLET_INSTALL_DIR
                echo "WALLET_DOWNLOAD_FILE: "$WALLET_DOWNLOAD_FILE
                echo "WALLET_DOWNLOAD_URL: "$WALLET_DOWNLOAD_URL
                echo "WALLET_BOOTSTRAP_FILE: "$WALLET_BOOTSTRAP_FILE
                echo "WALLET_BOOTSTRAP_URL: "$WALLET_BOOTSTRAP_URL
		echo "WALLET_ADDNODES_FILE: "$WALLET_ADDNODES_FILE
                echo "EXPLORER_URL1: "$EXPLORER_URL1
		echo "EXPLORER_URL2: "$EXPLORER_URL2
		echo "YIIMP_POOL_URL1: "$YIIMP_POOL_URL1
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
