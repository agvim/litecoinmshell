# litecoinmshell: a basic bash shell to start and control litecoin miners

## WTF is this?

A linux command line script to ease the startup and control of litecoin miners.

## Usage:

1. Copy the mshell.cfg.sample into mshell.cfg and modify it to configure the
shell.

2. Copy the miners.cfg.sample and modify it to configure the miners.

3. Run mshell.sh

The shell help provides a list of available commands. To see the help use "h" or
"help".

## Getting started in litecoin mining

You need a litecoin wallet. Download the litecoin client in [the litecoin
website](http://litecoin.org) to generate one.

Create an account in a litecoin mining guild, configure your litecoin wallet and
register a worker name and a password.

Install the mining script taking into consideration that:

* If you want to mine with an ATI card, use cgminer

* If you want to mine with an NVIDIA card, use cudaminer

* If you want to mine with the CPU use cpuminer

Updated recommendations about which miners to choose can be found in
[this hardware performance comparison](https://github.com/litecoin-project/litecoin/wiki/Mining-hardware-comparison)

Most guilds use the stratum protocol to distribute mining blocks.
cgminer has support for the protocol, but cudaminer and cpuminer need to use a
proxy.

The recommended proxy is [bandroix
stratum mining proxy](https://github.com/bandroidx/stratum-mining-proxy),
a stratum-mining-proxy fork that supports the litecoin scrypt algorythm.
Download it and follow the installation instructions.

Use mshell.sh to control the miners :)

## Notes

The miners configured to autostart and the proxy (if configured) are started
with minimum system priority in order to have a responsive system.

The miners and proxy logs are saved in files in the configured log directory.

The configuration files are sourced and interpreted in bash with eval.
Double check your configuration before running the script (See [eval security
issues](http://mywiki.wooledge.org/BashFAQ/048))

Donations accepted at:
Lg7koco9qapQK8Z9ieg1g6g7qSSS2zVP5Z
