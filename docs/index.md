TorQ Demo Pack
==============

The purpose of the TorQ Demo Pack is to set up an example TorQ
installation and to show how applications can be built and deployed on
top of the TorQ framework. The example installation contains all the key
features of a production data capture installation, including
persistence and resilience. The demo pack includes:

-   a dummy data feed

-   a resilient kdb+ stack to persist data to disk and to allow querying
    across real time data and historic data

-   basic monitoring with notifications via email

-   automated report generation

Once started, TorQ will generate dummy data and push it into an
in-memory real-time database. It will persist this data to disk every
day at midnight. The system will operate 24\*7 and remove old files over
time.

Further information about each feature can be found in the [TorQ
Manual](https://aquaqanalytics.github.io/TorQ/).

*email:* <support@dataintellect.com>

*web:* [www.dataintellect.com](http://www.dataintellect.com)
