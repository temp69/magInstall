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

![magnet menu](https://user-images.githubusercontent.com/36497576/44571713-d884c600-a781-11e8-8fc4-428232e8d206.png)

## INFO

- **UPDATE SYSTEM & INSTALL PACKAGES**

Keeps your system up-to-date and installs the required packages to start the wallet.\
You can even do this from time to time to ensure that everything on your VPS stays uptodate.
```diff
**Use this first on a fresh VPS**
```

- **INSTALL|UPDATE|RESYNC MAGNET**

This will install / update the magnet wallet or resync your local blockchain.\
On resync it keeps the necessary files (magnet.conf | masternode.conf | wallet.dat) on the VPS\
and will even try to update addnodes.

- **START|STOP MAGNET WALLET**

You can start and stop your magnet wallet.

- **MASTERNODE CONFIG**

Adds the necessary entries to the config file on your VPS.\
You need to provide a valid `masternode genkey`.

- **EDIT magnet.conf**

Let's you edit the `magnet.conf` file manually

- **MASTERNODE STATUS**

Shows information about your masternode status on the VPS\
`masternode status` and `debug` is executed and shown.

- **WALLET STATUS**

Will give you information of your wallet and the explorers, to check how the sync is going.\
`getinfo` is executed and it queries explorer's / pool to show block height

- **Quit**

Ends the script

Hint: Use **ENTER** twice to refresh the info in the banner!

## TODO

- SELF UPDATE FUNCTION (beta) use "v" in menu
- MAKE BLOCK HEIGHT INFO INTERACTIVE???
- REFACTOR SOME FUNCTIONS
