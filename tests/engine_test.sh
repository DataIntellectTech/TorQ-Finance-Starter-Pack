#!/bin/bash
# Tests for the Finance Starter Pack changes. Run from the Starter Pack directory:
#   ./engine_test.sh [q binary ...]     (default: q)  - each binary is used for the feed.q test
# Checks: (1) process.csv takes qcmd from ${QCMD}  (2) setenv.sh defaults QCMD to q and keeps an exported value
#         (3) torq.sh uses the overridden QCMD     (4) feed.q's piconst/normalrand load and run on each engine
cd "$(dirname "$0")/.." 2>/dev/null || true
[ -f appconfig/process.csv ] || { echo "run from (or place under) the Starter Pack directory"; exit 2; }
pass=0; fail=0
ok(){ if [ "$1" = 0 ]; then pass=$((pass+1)); echo "PASS  $2"; else fail=$((fail+1)); echo "FAIL  $2"; fi; }
 
# 1. every process line takes its qcmd from ${QCMD}
n=$(awk -F, 'NR>1 && NF>1 && $0 !~ /^#/' appconfig/process.csv | wc -l)
m=$(awk -F, 'NR>1 && NF>1 && $0 !~ /^#/ && $NF=="${QCMD}"' appconfig/process.csv | wc -l)
[ "$n" -gt 0 ] && [ "$n" = "$m" ]; ok $? "process.csv: qcmd is \${QCMD} on all $n process lines"
column=$(awk -F, 'NR==2 {print $NF}' appconfig/process.csv)                       # the qcmd of the first process
if command -v envsubst >/dev/null; then v=$(printf '%s' "$column" | QCMD=/opt/engine/q envsubst)   # what torq.sh does with it
else v=$(QCMD=/opt/engine/q bash -c 'eval echo "$1"' _ "$column"); fi                                 # (envsubst missing: the shell)
[ "$v" = "/opt/engine/q" ]; ok $? "process.csv: \${QCMD} expands to the exported value (got $v)"
 
# 2. setenv.sh: default q, exported value kept
qline=$(grep -E '^export QCMD=' setenv.sh | sed 's/[[:space:]]*#.*//')                                         # just that line: sourcing the whole setenv.sh also creates certs/ and downloads a certificate bundle
v=$(env -u QCMD bash -c "$qline; echo \$QCMD"); [ "$v" = "q" ]; ok $? "setenv.sh: QCMD defaults to q (got $v)"
v=$(QCMD=/opt/engine/l bash -c "$qline; echo \$QCMD"); [ "$v" = "/opt/engine/l" ]; ok $? "setenv.sh: an exported QCMD is kept (got $v)"
 
# 3. torq.sh start line uses the overridden QCMD (only if a TorQ deploy's torq.sh is reachable through setenv.sh)
if [ -n "$TORQSH" ] && [ -f "$TORQSH" ]; then
  line=$(QCMD=/opt/engine/l bash "$TORQSH" print discovery1 </dev/null 2>/dev/null | tail -1)
  case "$line" in *"/opt/engine/l "*) ok 0 "torq.sh: start line uses QCMD";; *) ok 1 "torq.sh: start line uses QCMD (got: ${line:0:80})";; esac
fi
 
# 4. feed.q: the renamed constant and normalrand run on each engine (pi is a reserved name on L)
src=$(grep -E '^(piconst|normalrand):' code/tick/feed.q)
! grep -qE '(^|[^a-zA-Z.])pi:' code/tick/feed.q; ok $? "feed.q: no assignment to pi"
to=$(command -v timeout || command -v gtimeout || true)                              # GNU timeout: not on macOS unless coreutils is installed
bins=("$@"); [ ${#bins[@]} -eq 0 ] && bins=(q)                                    # binaries may have spaces in their paths
tmpd=$(mktemp -d); tmpq="$tmpd/feed.q"                                              # a private file: runs at the same time do not collide
# 10000 samples: their mean is within 0.1 of 0 with certainty (10 standard deviations), so the check cannot fail by chance
printf '%s\nr:normalrand 10000;\n-1 $[(10000=count r) and (9h=type r) and (not any null r) and 0.1>abs avg r;"ok";"bad"];\nexit 0\n' "$src" > "$tmpq"
for q in "${bins[@]}"; do
  r=$(${to:+$to 20} "$q" "$tmpq" -q </dev/null 2>&1 | tail -1)
  [ "$r" = "ok" ]; ok $? "feed.q: piconst and normalrand run on $q (got: $r)"
done
rm -rf "$tmpd"
echo "$pass passed, $fail failed"; [ $fail = 0 ]
