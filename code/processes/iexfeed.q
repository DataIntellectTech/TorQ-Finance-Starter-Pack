.servers.startup[]
.iex.callbackhandle:neg .servers.gethandlebytype[`tickerplant;`any]
.timer.repeat[.proc.cp[];0Wp;.iex.timerperiod;(`.iex.timer;`);"Publish Feed"];
.timer.repeat[.proc.cp[];0Wp;0D00:00:01.000000000;(`.iex.checkTimer;`);"Restart Feed"];
