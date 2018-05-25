hdbfuncpath:getenv[`KDBCODE],"/hdb/hdbstandard.q";
symdatapath:getenv[`TORQAPPHOME],"/unitTesting/data/symbackup";
wdbh:hsym`$":"sv(enlist":";string 5+"I"$getenv[`KDBBASEPORT];"unittests";"pass");
hdbpath:symdatapath,"/database";
sympath:hdbpath,"/sym";
temppath:hdbpath,"/tempsym";

