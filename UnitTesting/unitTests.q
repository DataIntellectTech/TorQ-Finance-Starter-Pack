//DEFAULT VALUES
def:.Q.def[`stackID`user`pass`testCSV!(9000;`admin;`admin;`:utests/1iexfeed.csv)].Q.opt[.z.x] 

//LOADING Q-SCRIPTS
\l k4unit.q

//UTILITIES
//get the right port to open handle 
getP:{[proc] 
     $[`rdb~proc;string[def[`stackID]+2];::]
     $[`feed~proc;string[def[`stackID]+14];::]
     $[`iex~proc;string[def[`stackID]+19];::]};  

//creating path for opening handle 
path:{`$"::",getP[x],":",string[def[`user]],":",string[def[`pass]]};  

//function that checks operating system
//can be ammended to use different system commands for different opSystems
opSystem:{[command]$[`l64~.z.o; $[`list~command;show system"ls";::];"nyi"]};

//timer.remove function does nothing if the feed is already removed from the table
stFeed:{x(".timer.remove[first exec id from .timer.timer where {[x](`",string[y],"`)~x}'[funcparam]]")}; 

//check if csv file or directory 
loadTest:{$["csv"~-3#string[def[`testCSV]];@[KUltf;hsym def[`testCSV];{-2"ERROR: "x}];@[KUltd;hsym def[`testCSV];{-2"ERROR: ",x}]]}; 

//openning handle to process
opHandle:{[pTO]@[hopen;path[pTO];{-2"ERROR: ",x}]}; //open handle to IEX feed 

//MAIN
init:{
       -1"LOADING TESTS... ";
       loadTest[];
       dH::()!();
       -1"OPENING HANDLES..."; 
       dH[`rdb]::opHandle[`rdb];
       dH[`iex]::opHandle[`iex]; 
       dH[`feed]::opHandle[`feed];
       -1"STOPING FEEDS..."; 
       stFeed[dH[`iex];`.iex.timer]; 
       stFeed[dH[`feed];`feed];
       -1"RUNNING TESTS...";
       KUrt[];  
     }; 

 //EXECUTE
init 0
 


