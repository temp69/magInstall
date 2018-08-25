# MAGNET

## magInstall

> **magInstall** is a menu driven script which can be used to control
your `magnetd` wallet on a linux VPS.

![magnet menu](https://user-images.githubusercontent.com/36497576/44571713-d884c600-a781-11e8-8fc4-428232e8d206.png)

## Features

- Updates your VPS operating system
- Installs all needed libraries
- Automated wallet installation
- Wallet upgrade functionality
- Wallet resync functionality
- Updating addnodes
- Start / Stop the wallet
- Masternode configuration
- Manually editing `magnet.conf`
- Masternode status info
- Wallet status info
- Blockheight information
- BETA: Script self update function

> A control center for your magnet wallet

## Installation

### Install git if needed
`sudo apt-get install git`

### Download the install script
`git clone https://github.com/temp69/magInstall`

### Move into the directory and execute the script
`cd magInstall`\
`./magInstall.sh`

## Usage

- **UPDATE SYSTEM & INSTALL PACKAGES**

Keeps your system up-to-date and installs the required packages to start the wallet.\
You can even do this from time to time to ensure that everything on your VPS stays uptodate.
```diff
- **Use this first on a fresh VPS**
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

## Compatibility

- Ubuntu 16.04
- Ubuntu 17.04
- Ubuntu 17.10
- Ubuntu 18.04

- DigitalOcean
- Vultr

## TODO

- SELF UPDATE FUNCTION (beta) use "v" in menu
- MAKE BLOCK HEIGHT INFO INTERACTIVE???
- REFACTOR SOME FUNCTIONS
