# TorQ-IEX

An example production ready market data capture system, using randomly generated financial data along with live market data from the IEX. This is installed on top of the base TorQ package, and includes a version of [kdb+tick](http://code.kx.com/wsvn/code/kx/kdb+tick). The live market data from the IEX is sent to the ``trade_iex`` and ``quote_iex`` tables within the RDB.

### Example-Usage

When the IEX feed is launched in TorQ, ``appconfig/settings/iexfeed.q`` is ran, followed by ``code/iexfeed/iex.q`` and finally ``code/processes/iexfeed.q``. ``appconfig/settings/iexfeed.q`` can be used to change default variables within the ``.iex`` namespace. These default values are set in ``code/iexfeed/iex.q``, if no values have been assigned in ``appconfig/settings/iexfeed.q``.  The .iex variables that can be changed are:  

* ``.iex.main_url``
  * Used to decide which API to request data from
  * Default value is ``"https://api.iextrading.com"``
* ``.iex.quote_suffix``
  * Default value is ``{[sym] "/1.0/stock/",sym,"/quote"}``
* ``.iex.trade_suffix``
  * Default value is ``{[sym] "/1.0/tops/last?symbols=",sym}``
* ``.iex.syms``
  * This decides the instruments to collect data for
  * Default value is `` `CAT`DOG``
* ``.iex.reqtype``
  * This decides the request type to make. Trade data, quote data or both can be requested
  * Default value is `` `both``
  * This can be changed to either `` `quote`` or `` `trade``
* ``.iex.upd``
  * This is called when either a trade or quote request is made
  * It is called with two arguements. The first is the table name, either `` `trade`` or `` `quote``, and the second is the corresponding table
  * The default value is ``{[t;x] .iex.callbackhandle(.iex.callback;t; value flip x)}``
* ``.iex.callback``
  * This is called within the default ``.iex.upd`` function
  * The default value is ``.u.upd``
  * If the ``.iex.upd`` function is unchanged, the ``.iex.callback`` function is executed within a port decided by ``.iex.callbackhandle``
  * ``.iex.callbackhandle`` is set in ``code/processes/iexfeed.q``. The discovery service is used to open an asynchronous connection to the tickerplant

#### .iex.init

If you wish to use the standalone ``code/iexfeed/iex.q`` script then the ``.iex.init`` function can be called to change the default vaariables described above. This should only be used if not using the TorQ framework. 

When using ``code/iexfeed/iex.q`` outside of the TorQ framework the port in which the ``.iex.callback`` function will be executed in is not set. Thus the ``.iex.init`` function can be used to set two further variables:

* ``.iex.callbackconnection``
  * These are the server details ``.iex.callback`` function will be executed in
  * If not supplied during the init call the message callback will be executed locally `` ` ``
  * If ``.iex.callbackconnection`` is supplied a connection handle will be opened and all updates will be sent asynchronously 
* ``.iex.callbackhandle``
  * This can also be changed to decide which server the ``.iex.callback`` function will be executed in, using the handle to the server itself
  * Default value is ``0i``
  * If both ``.iex.callbackconnection`` and ``.iex.callbackhandle`` are set using ``.iex.init``, ``.iex.callbackhandle`` has precidence
  * Messages should be sent asynchronously

#### Example Function Call

``.iex.init`` should be called with a dictionary. The keys of the dictionary should be the names of the variables or functions that are being set. The values associated with these keys should be the new variable values. An example of using ``.iex.init`` can be seen below.

```
.iex.init (`syms`callbackhandle`callback`reqtype)!(`cat;5i;".u.upd";`both)
```

### Raw JSON Data

The following data is an example of trade and quote data that can be pulled down with the json requests inside the iex.q file.

##### Raw Trade Data

Taken from: [most recent Apple trade data](https://api.iextrading.com/1.0/tops/last?symbols=AAPL)

` [{"symbol":"AAPL","price":178.675,"size":100,"time":1516723026747}] `

##### Raw Quote Data

Taken from: [most recent Apple quote data](https://api.iextrading.com/1.0/stock/aapl/quote)

` {"symbol":"AAPL","companyName":"Apple Inc.","primaryExchange":"Nasdaq Global Select","sector":"Technology","calculationPrice":"tops","open":177.28,"openTime":1516717800670,"close":177,"closeTime":1516654800146,"high":178.54,"low":176.83,"latestPrice":178.66,"latestSource":"IEX real time price","latestTime":"10:55:27 AM","latestUpdate":1516722927880,"latestVolume":8796961,"iexRealtimePrice":178.66,"iexRealtimeSize":100,"iexLastUpdated":1516722927880,"delayedPrice":178.15,"delayedPriceTime":1516722031057,"previousClose":177,"change":1.66,"changePercent":0.00938,"iexMarketPercent":0.02402,"iexVolume":211303,"avgTotalVolume":25616973,"iexBidPrice":173.39,"iexBidSize":100,"iexAskPrice":179.4,"iexAskSize":200,"marketCap":908853424960,"peRatio":19.42,"week52High":180.1,"week52Low":119.5,"ytdChange":0.027516544757924123} `

