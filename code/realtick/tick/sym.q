// internal tables
// with `time` and `sym` columns added by RT client for compatibility
(`$"_prtnEnd")set ([] time:"n"$(); sym:`$(); signal:`$(); endTS:"p"$(); opts:());
(`$"_reload")set ([] time:"n"$(); sym:`$(); mount:`$(); params:(); asm:`$())
(`$"_heartbeats")set ([] time:"n"$(); sym:`$(); foo:"j"$())

quote:([]time:`timespan$();sym:`symbol$();bid:`float$();ask:`float$();bsize:`int$();asize:`int$())
trade:([]time:`timespan$();sym:`symbol$();price:`float$();size:`int$())
