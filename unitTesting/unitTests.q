//DEFAULT VALUES
def:.Q.def[`stackID`user`pass`testCSV`testData!(9000;`admin;`admin;`:utests/1iexfeed.csv;`:testData/)].Q.opt[.z.x] 

//LOADING Q-SCRIPTS
system"l TorQ/tests/k4unit.q"; 

//UTILITIES
//get the right port to open handle 
getP:{[proc] 
     $[`rdb~proc;string[def[`stackID]+2];::]
     $[`feed~proc;string[def[`stackID]+14];::]
     $[`iex~proc;string[def[`stackID]+19];::]
     $[`vtwap~proc;string[def[`stackID]+21];::]};  

//creating path for opening handle 
path:{`$"::",getP[x],":",string[def[`user]],":",string[def[`pass]]};  

//function that checks operating system
//can be ammended to use different system commands for different opSystems
opSystem:{[command]$[`l64~.z.o; $[`list~command;show system"ls";::];"nyi"]};

//timer.remove function does nothing if the feed is already removed from the table
stFeed:{x(".timer.remove[first exec id from .timer.timer where {[x](`",string[y],"`)~x}'[funcparam]]")}; 

//check if csv file or directory 
loadTest:{$[string[def[`testCSV]]like"*.csv";@[KUltf;hsym def[`testCSV];{-2"ERROR: "x}];@[KUltd;hsym def[`testCSV];{-2"ERROR: ",x}]]}; 

//openning handle to process
opHandle:{[pTO]@[hopen;path[pTO];{-2"ERROR: ",x}]}; //open handle to IEX feed 

loadFl:{load hsym `$string[def[`testData]],x}';  
//MAIN
init:{
       -1"LOADING TESTS... ";
       loadTest[];
       -1"LOADING TEST DATA... ";
       loadFl[system"ls testData/"]; /- this needs changed maybe a different function that adds the testData/
       // .vtwap.data:vtwap;
       -1"OPENING HANDLES...";
       dH::()!(); 
       dH[`rdb]::opHandle[`rdb];
       dH[`iex]::opHandle[`iex]; 
       dH[`feed]::opHandle[`feed];
       dH[`vtwap]::opHandle[`vtwap]; 
       -1"STOPPING FEEDS..."; 
       stFeed[dH[`iex];`.iex.timer]; 
       stFeed[dH[`feed];`feed];
       -1"RUNNING TESTS...";
       KUrt[];  
     }; 

 //EXECUTE
init 0
 


