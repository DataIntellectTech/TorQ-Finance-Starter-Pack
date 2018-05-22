hdbfuncpath:getenv[`KDBCODE],"/hdb/hdbstandard.q";
symdatapath:getenv[`KDBTORQFSP],"/tests/data/symbackup";
// wdbh:hsym`$":"sv(enlist":";string 5+"I"$getenv[`KDBBASEPORT];"unittests";"pass");
hdbpath:symdatapath,"/database";
sympath:hdbpath,"/sym";
temppath:hdbpath,"/tempsym";

