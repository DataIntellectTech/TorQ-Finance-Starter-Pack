//cmd line params 
//pdir directory which contains par.tx
//hdbdir directory you want to migrate
//ptype partition type you want, sym or date

system"l ",first .proc.params.hdbdir; 
.mig.partitions:.Q.PV;
.mig.segments:read0 ` sv hsym[`$first .proc.params.pdir],`par.txt;
.mig.partype:.Q.pf;
.mig.h:count .mig.segments;

.mig.dtd:{ 
  d:.mig.segments[mod[;.mig.h].mig.partitions],'"/",'string .mig.partitions;
  s:{last":"vs string x} each` sv'.mig.o[`hdbdir],'`$string .mig.partitions;
  .os.ren'[s;d];
 }

.mig.savebysym:{[tab;dir;sim];
  (` sv hsym[`$dir],tab,`)set .Q.en[hsym`$first .proc.params.pdir] delete sym from select from tab where sym=sim;
 }

.mig.sbysym:{
  syms:asc first value flip select distinct sym from last .Q.pt;
  d:.mig.segments[{floor[26%x]*til x}[.mig.h]bin .Q.A?first each string syms],'"/",'string syms; 
  .mig.savebysym'[;d;syms]'[.Q.pt];
 }

.mig.savebydate:{[tab;dir;dt];
  (` sv hsym[`$dir],tab,`)set .Q.en[hsym`$first .proc.params.pdir] delete date from select from tab where date=dt;
 }

.mig.sbydate:{
  dts:asc first value flip select distinct date from last .Q.pt;
  d:.mig.segments[mod[dts;.mig.h]],'"/",'string dts;
  .mig.savebysym'[;d;dts]'[.Q.pt];
 }

$[all`date=(.mig.partype;`$first .proc.params.ptype);.mig.dtd[];`sym~`$first .proc.params.ptype;.mig.sbysym[];`date~`$first .proc.params.ptype;.mig.sbydate[];exit 0];
.os.ren . ,\:[;"/sym"]first each (.proc.params.hdbdir;.proc.params.pdir);  //move sym file

