VizSum - Data Vizualisation Script 
==================================

Example-Usage 
=============

Functions 
=========

The vizSum script is an rdb-like process capturing and analysing data from the tickerplant. It contains a number of functions, which can be called from DataWatch, which calculate various metrics. Below you can find a list of functions which are available within vizSum: 
* Last10TQ – returns the last 10 lines of a user specified table 
* Occurences – returns the count by sym within an user specified timeframe 
* srcQuoteUpd – returns srcquote table together with 3 more columns: spread, midsize, midprice 
* clienttradeUpd – returns the clienttrade table with two additional columns: volatility and volume 
* buySellPressure – returns a table showing the number of buy orders as percentage of total order for each sym 

Example Function Call 
=====================


