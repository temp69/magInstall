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

![magnet script](https://user-images.githubusercontent.com/36497576/44196590-a1d4fd00-a13c-11e8-92d8-307d7a668687.png)

## INFO

- **INSTALL|UPDATE|RESYNC MAGNET**

This will install / update the magnet wallet or resync your local blockchain.\
On resync it keeps the necessary files (magnet.conf | masternode.conf | wallet.dat)

- **UPDATE SYSTEM & INSTALL PACKAGES**

Keeps your system up-to-date and installs the required packages to start the wallet.\
**Use this first on a fresh VPS**

- **START|STOP MAGNET WALLET**

You can start and stop your magnet wallet.\

- **MASTERNODE CONFIG**

Adds the necessary entries to the config file on your VPS

- **EDIT magnet.conf**

Let's you edit the `magnet.conf` file manually\
Watch out modifieing RPC information while wallet is running!!

- **MASTERNODE STATUS**

Shows information about your masternode status on the VPS

- **WALLET STATUS**

Will give you information of your wallet and the explorers, to check how the sync is going.

- **Quit**

Ends the script

Hint: Use **ENTER** twice to refresh the info in the banner!

## TODO

- UPDATE ADDNODES WHEN UPDATING WALLET
- REFACTOR SOME FUNCTIONS
