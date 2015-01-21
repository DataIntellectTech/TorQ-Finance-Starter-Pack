/- RDB query for counting by sym
/- if not today, return an empty table
countbysym:{[startdate;enddate]
 $[.z.d within (startdate;enddate);
	select sum size, tradecount:count i by sym from trade;
	([sym:`symbol$()] size:`long$(); tradecount:`long$())]}

/- time bucketted count
hloc:{[startdate;enddate;bucket]
 $[.z.d within (startdate;enddate);
	select high:max price, low:min price, open:first price,close:last price,totalsize:sum `long$size, vwap:size wavg price
	by sym, bucket xbar time
	from trade;
	([sym:`symbol$();time:`timestamp$()] high:`float$();low:`float$();open:`float$();close:`float$();totalsize:`long$();vwap:`float$())]}
