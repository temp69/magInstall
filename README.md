# MAGNET

## magnet install/update/config script

### Install git if needed
`apt-get install git`

### Download the install script
`git clone https://github.com/temp69/magInstall`

### Move into the directory and execute the script
`cd magInstall`\
`./magInstall`

![magnet script](https://user-images.githubusercontent.com/36497576/44104149-6122f798-9fee-11e8-9035-cd85b818dc43.png)

## INFO

- (1) INSTALL|UPDATE|RESYNC MAGNET

This will install / update the magnet wallet or resync your local blockchain.\
On resync it keeps the necessary files (magnet.conf | masternode.conf | wallet.dat)

- (2) UPDATE SYSTEM & INSTALL PACKAGES

Keeps your system up-to-date and installs the required packages to start the wallet.\
Hint: Use this first on a fresh VPS

- (3) START|STOP MAGNET WALLET

You can start and stop your magnet wallet.\
Info: When starting the wallet, it might not be able to connect to the wallet instantly and show error!

- (9) STATUS INFORMATION

Will give you information of your wallet and the explorers, to check how the sync is going.

- (q) Quit

Ends the script

## TODO

- Masternode configuration

