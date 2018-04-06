quote:([]time:`timestamp$(); sym:`g#`symbol$(); bid:`float$(); ask:`float$(); bsize:`long$(); asize:`long$(); mode:`char$(); ex:`char$())
trade:([]time:`timestamp$(); sym:`g#`symbol$(); price:`float$(); size:`int$(); stop:`boolean$(); cond:`char$(); ex:`char$())
quote_iex:([]time:`timestamp$(); sym:`g#`symbol$(); bid:`float$(); ask:`float$(); bsize:`long$(); asize:`long$(); mode:`char$(); ex:`char$(); srctime:`timestamp$())
trade_iex:([]time:`timestamp$(); sym:`g#`symbol$(); price:`float$(); size:`int$(); stop:`boolean$(); cond:`char$(); ex:`char$(); srctime:`timestamp$())
srcquote:([]time:`timestamp$(); sym:`g#`symbol$(); src:`symbol$(); bid:`float$(); ask:`float$(); bsize:`long$(); asize:`long$(); mode:`char$(); ex:`char$())
clienttrade:([]time:`timestamp$(); sym:`g#`symbol$(); price:`float$(); size:`int$();stop:`boolean$(); cond:`char$(); ex:`char$();side:`symbol$())
pnltab:([]time:`timestamp$();sym:`symbol$();price:`float$();size:`int$();side:`symbol$();position:`int$();dcost:`float$();src:`symbol$();bid:`float$();ask:`float$();pnl:`float$();r:`float$();totpnl:`float$())

