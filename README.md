# MAGNET

## magnet install/update/config script

A menu driven bash script to handle the magnet wallet on the VPS.

### Install git if needed
`sudo apt-get install git`

### Download the install script
`git clone https://github.com/temp69/magInstall`

### Move into the directory and execute the script
`cd magInstall`\
`./magInstall.sh`

![magnet script](https://user-images.githubusercontent.com/36497576/44104149-6122f798-9fee-11e8-9035-cd85b818dc43.png)

## INFO

- **INSTALL|UPDATE|RESYNC MAGNET**

This will install / update the magnet wallet or resync your local blockchain.\
On resync it keeps the necessary files (magnet.conf | masternode.conf | wallet.dat)

- **UPDATE SYSTEM & INSTALL PACKAGES**

Keeps your system up-to-date and installs the required packages to start the wallet.\
Use this first on a fresh VPS

- **START|STOP MAGNET WALLET**

You can start and stop your magnet wallet.\
Info: When starting the wallet, it might not be able to connect to the wallet instantly and show error!

- **MASTERNODE CONFIG**

Adds the necessary entries to the config file on your VPS

- **MASTERNODE STATUS**

Shows information about your masternode status on the VPS

- **WALLET STATUS**

Will give you information of your wallet and the explorers, to check how the sync is going.

- **Quit**

Ends the script

Hint: Use **ENTER** twice to refresh the status information!

## TODO

- MASTERNODE STATUS & DEBUG INFO
- COMPATIBILITY WITH OLD SETUP INSTRUCTIONS
- REFACTOR SOME FUNCTIONS
