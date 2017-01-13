# TorQ-Finance-Starter-Pack
An example production ready market data capture system, using randomly generated financial data.  This is installed on top of the base TorQ package, and includes a version of [kdb+tick](http://code.kx.com/wsvn/code/kx/kdb+tick).

## Set Up 

Assuming that the [free 32 bit version of kdb+](http://kx.com/software-download.php) is already set up and available from the command prompt as q, then:

1. Download a zip of the latest version of [TorQ](https://github.com/AquaQAnalytics/TorQ/archive/master.zip)
2. Download a zip of [this starter pack](https://github.com/AquaQAnalytics/TorQ-Finance-Starter-Pack/archive/master.zip)
3. Unzip TorQ
4. Unzip the starter pack over the top (this will replace some files)
5. Run the appropriate starts script: start_torq_demo.bat for Windows, start_torq_demo.sh for Linux and start_torq_demo_osx.sh for Mac OS X. 

For more information on how to configure and get started, go to [this site](https://aquaqanalytics.github.io/TorQ-Finance-Starter-Pack/).  You will need to make some modifications if you wish to send emails from the system. 

## Updating the Documentation with Mkdocs

To make changes to the documentation website you must simply use this command while in the branch you have made the changes on:

`mkdocs gh-deploy`

You will be prompted to enter a username and password, after this the site should have been updated. You can test the site locally if you want using mkdocs. First use the command:

`mkdocs build`

Then:

`mkdocs serve -a YourIp:Port`

Head to the address it gives you to check if your changes have worked. More information about using mkdocs can be found [here](http://www.mkdocs.org/)

## Release Notes

- **1.0.1, July 2015**:
  * Added Chained Tickerplant process

- **1.1.0, October 2015**:
  * REQUIRES TORQ 2.2.0
  * Added compatibility with $KDBAPPCONFIG in TorQ 2.2.0 Release
- **1.2.0, April 2016**:
  * REQUIRES TORQ 2.5.0
  * Removed u.q
  * Moved all config directory into appconfig
- **1.2.1, September 2016**:
  * REQUIRES TORQ 2.6.2
  * added broadcast functionality to u.q
  * added sortslave functionality
- **1.3.0, November 2016**:
  * REQUIRES TORQ 2.7.0
  * Removed kdb+ tick code
  * Moved KDBBASEPORT assignment to setenv.sh
  * Feed process uses timer library
