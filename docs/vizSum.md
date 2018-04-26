VizSum - Data Vizualisation Script 
==================================

Example-Usage 
=============

Functions 
=========

The vizSum script is an rdb-like process capturing and analysing data from the tickerplant. It contains a number of functions, which can be called from DataWatch, which calculate various metrics. Below you can find a list of functions which are available within vizSum: 

1.  last10TQ – returns the last 10 lines of a user specified table 
2.  occurences – returns the count by sym within an user specified timeframe 
3.  srcQuoteUpd – returns srcquote table together with 3 more columns: spread, midsize, midprice 
4.  clienttradeUpd – returns the clienttrade table with two additional columns: volatility and volume 
5.  buySellPressure – returns a table showing the number of buy orders as percentage of total order for each sym 

Example Function Call 
=====================


