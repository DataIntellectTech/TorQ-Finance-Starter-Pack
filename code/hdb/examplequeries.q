/- HDB query for counting by sym
countbysym:{[startdate;enddate]
 select sum size, tradecount:count i by sym from trade where date within (startdate;enddate)}

/- time bucketted count
hloc:{[startdate;enddate;bucket]
 select high:max price, low:min price, open:first price,close:last price,totalsize:sum `long$size, vwap:size wavg price
 by sym, bucket xbar time
 from trade
 where date within (startdate;enddate)}
