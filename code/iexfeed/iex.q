\d .iex

mainurl:@[value;`mainurl;"https://api.iextrading.com"];
convertepoch:@[value;`convertepoch;{{"p"$1970.01.01D+1000000j*x}}];
reqtype:@[value;`reqtype;`both];
syms:@[value;`syms;`CAT`DOG];
callback:@[value;`callback;".u.upd"];
callbackhandle:@[value;`callbackhandle;0i];
callbackconnection:@[value;`callbackconnection;`];
quotesuffix:@[value;`quotesuffix;{{[sym] "/1.0/stock/",sym,"/quote"}}];
tradesuffix:@[value;`tradesuffix;{{[sym]"/1.0/tops/last?symbols=",sym}}];
upd:@[value;`upd;{{[t;x].iex.callbackhandle(.iex.callback;t; value flip x)}}];
timerperiod:@[value;`timerperiod;0D00:00:02.000];
lvcq:@[value;`lvcq;1!flip `sym`bid`ask`bsize`asize`mode`ex`srctime!()];
lvct:@[value;`lvct;1!flip`sym`price`size`stop`cond`ex`srctime!()];
qcols:@[value;`qcols;`bid`ask`bsize`asize`mode`ex];
nullq:@[value;`nullq;qcols!(0f;0f;0i;0i;" ";" ")];
tcols:@[value;`tcols;`price`size`stop`cond`ex];
nullt:@[value;`nullt;tcols!(0f;0i;"B"$();" ";" ")];

init:{[x]
  if[`mainurl in key x;.iex.mainurl:x`main_url];
  if[`quotesuffix in key x;.iex.quotesuffix:x`quotesuffix];
  if[`tradesuffix in key x;.iex.tradesuffix:x`tradesuffix];
  if[`syms in key x;.iex.syms:upper x`syms];
  if[`reqtype in key x;.iex.reqtype:x`reqtype];
  if[`callbackconnection in key x;.iex.callbackhandle:neg hopen .iex.callbackconnection:x`callbackconnection];
  if[`callbackhandle in key x;.iex.callbackhandle:x`callbackhandle];
  if[`callback in key x;.iex.callback:$[.iex.callbackhandle=0;string @[value;x`callback;{[x;y]x set{[t;x]x}}[x`callback]];x`callback]];
  if[`upd in key x;.iex.upd:x`upd];
  .iex.timer:$[not .iex.reqtype in key .iex.timer_dict;'`timer;.iex.timer_dict .iex.reqtype];
 };

getdata:{[main_url;suffix].Q.hg`$mainurl,suffix};

getlasttrade:{
  tab:{[syms]
    / This function can run for multiple securities.
    syms:$[1<count x;","sv;]x:string upper syms,();
    / Construct the GET request
    / Parse json response and put into table. Trade data from https://iextrading.com/developer/
    data:.j.k .iex.getdata[.iex.mainurl;.iex.tradesuffix syms];
    :createtable[`.iex.dtrd;data];
   }[.iex.syms];
  tab:checkdup[;;`.iex.lvct;tcols;nullt]/[0#tab;tab];
  if[count tab;.iex.upd[`trade_iex;tab]];
 };

getquote:{
  tab:raze{[sym]
    suffix:.iex.quotesuffix string upper sym;
    / Parse json response and put into table
    data:enlist .j.k .iex.getdata[.iex.mainurl;suffix];
    :createtable[`.iex.dqte;data];
   }'[.iex.syms,()];
  / Check for duplicate data
  tab:checkdup[;;`.iex.lvcq;qcols;nullq]/[0#tab;tab];
  if[count tab;.iex.upd[`quote_iex;tab]];
 };

timerboth:{.iex.getlasttrade[];.iex.getquote[]};
timerdict:`trade`quote`both!(.iex.getlasttrade;.iex.getquote;timerboth);

timer:{
  if[not .iex.reqtype in key .iex.timerdict;
    .lg.e[`iextimer;"failed to run iex timer function: timer request type not valid: ",string .iex.reqtype];
    :();
    ];
  .iex.timerdict[.iex.reqtype][]; 
 };

checkdup:{[x;y;lvc;c;n]
  / Checks for duplicates and nulls
  i:any(n;c#value[lvc]y`sym)~\:c#y;
  if[not i;lvc upsert y;x,:y];
  :x;
 };

createtable:{[x;data]update .iex.convertepoch[srctime]from x[`ncol]xcol flip x[`typ]$x[`ocol]#flip data};

loadcsv:{("SSC";enlist",")0:x};

dtrd:@[loadcsv;first hsym .proc.getconfigfile"trade_iex.csv";{.lg.e[`iexloadcsv;"Failed to load config file: ",x]}];
dqte:@[loadcsv;first hsym .proc.getconfigfile"quote_iex.csv";{.lg.e[`iexloadcsv;"Failed to load config file: ",x]}];


\d . 
