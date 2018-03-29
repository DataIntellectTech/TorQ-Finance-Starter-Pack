hdbfuncpath:getenv[`KDBCODE],"/hdb/hdbstandard.q";
datapath:getenv[`KDBTORQFSP],"/unitTesting/data/symbackup";
wdbh:hsym`$":"sv(enlist":";string 5+"I"$getenv[`KDBBASEPORT];"unittest";"pass");
hdbpath:datapath,"/database";
sympath:hdbpath,"/sym";
temppath:hdbpath,"/tempsym";

