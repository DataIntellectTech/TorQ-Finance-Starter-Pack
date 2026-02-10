# TorQ-Finance-Starter-Pack
An example production ready market data capture system, using randomly generated financial data.

## Set Up

Assuming that the community edition of [KDB-X](https://code.kx.com/kdb-x/get_started/kdb-x-install.html) is already set up and available from the command prompt as q, then:

1.  Download the install script in the directory where you want the TorQ to be installed using:

    `wget https://raw.githubusercontent.com/DataIntellectTech/TorQ-Finance-Starter-Pack/master/installlatest.sh`
    
2. Run the appropriate starts script: start_torq_demo.bat for Windows, start_torq_demo_mac.sh for macOS, and torq.sh in the bin directory with the command line argument start all for Linux.

For more information on how to configure and get started, go to [this site](https://dataintellecttech.github.io/TorQ-Finance-Starter-Pack/).  You will need to make some modifications if you wish to send emails from the system.

## Community License Limits

Due to connection limits enforced in the KDB-X [community edition license](https://code.kx.com/kdb-x/releases/release-notes-latest.html#2-qlim-resource-limits), by default the following processes have been turned off in this pack:

- reporter
- monitor
- file alerter
- data quality

If the fully-licensed KDB-X is installed, the demo may be run with all processes included (see below).

### Fully-Licensed Setup

1. Stop all processes
2. In the `TorQApp/latest/appconfig/` directory, replace `process.csv` contents with `processfull.csv`
3. Restart all processes

## Updating the Documentation with Mkdocs

To make changes to the documentation website you must simply use this command while in the branch you have made the changes on:

`mkdocs gh-deploy`

You will be prompted to enter a username and password, after this the site should have been updated. You can test the site locally if you want using mkdocs. First use the command:

`mkdocs build`

Then:

`mkdocs serve -a YourIp:Port`

Head to the address it gives you to check if your changes have worked. More information about using mkdocs can be found [here](http://www.mkdocs.org/)

## Release Notes
- **1.11.0, Mar 2021**
  * Make dummy feed more random
  * Use waiting connections in subscribers
  * Bug fixes
- **1.10.0, Dec 2020**
  * Updated documentation
  * Segmented Tickerplant added
- **1.9.1, Oct 2020**
  * Updated documentation
  * installlatest.sh script added
- **1.9.0, Sept 2020**
  * Inclusive language
  * A Fix for CTP in start .stop script and other minor fixes
  * Addition of the pcap decoder
  * New setenv enviornment variables and code structure for install script 
- **1.8.0, May 2020**
  * Add Data Quality System configuration files.
  * Add DataDog configuration files.
  * Minor fixes.
- **1.7.0, Dec 2018**
  * Added Basic configuration for integration of Monit for monitoring TorQ.
  * TORQHOME variable changed from relative path to absolute path in setenv.sh.
  * QCON flag added so that ./torq.sh qcon <processname> <username>:<password> will connect to the process without need for port to be entered manually.
  * Default RDB Timeout changed to 180 seconds.
- **1.6.0, May 2018**:
  * Update process.csv for start stop script (torq.sh) in TorQ. All the process configuration is now at one place in $KDBAPPCONFIG/process.csv.
  * Tested with kdb+ 3.6 and TorQ 3.3.0
- **1.5.0, January 2018**:
  * Added IEX feed
  * Added usage file for IEX functions
- **1.4.0, December 2017**:
  * Rationalised connections
  * Added metrics engine
  * Added vwap subscriber process
  * Added version dependency requirements
- **1.3.0, November 2016**:
  * REQUIRES TORQ 2.7.0
  * Removed kdb+ tick code
  * Moved KDBBASEPORT assignment to setenv.sh
  * Feed process uses timer library
- **1.2.1, September 2016**:
  * REQUIRES TORQ 2.6.2
  * added broadcast functionality to u.q
  * added sortworker functionality
- **1.2.0, April 2016**:
  * REQUIRES TORQ 2.5.0
  * Removed u.q
  * Moved all config directory into appconfig
- **1.1.0, October 2015**:
  * REQUIRES TORQ 2.2.0
  * Added compatibility with $KDBAPPCONFIG in TorQ 2.2.0 Release
- **1.0.1, July 2015**:
  * Added Chained Tickerplant process
