/ Default config for surveillance process

\d .surv

cfg.rdbtypes:@[value;`cfg.rdbtypes;`rdb]

/ Volume spike
cfg.vol.lookback:@[value;`cfg.vol.lookback;0D00:05]
cfg.vol.multiplier:@[value;`cfg.vol.multiplier;3.0]
cfg.vol.interval:@[value;`cfg.vol.interval;0D00:00:10]

/ Price deviation (trade vs prevailing quote)
cfg.pxdev.lookback:@[value;`cfg.pxdev.lookback;0D00:05]
cfg.pxdev.threshold:@[value;`cfg.pxdev.threshold;0.02]
cfg.pxdev.interval:@[value;`cfg.pxdev.interval;0D00:00:10]

/ Quote stuffing
cfg.qs.lookback:@[value;`cfg.qs.lookback;0D00:00:05]
cfg.qs.countthreshold:@[value;`cfg.qs.countthreshold;50]
cfg.qs.minpricemove:@[value;`cfg.qs.minpricemove;0.5]
cfg.qs.interval:@[value;`cfg.qs.interval;0D00:00:05]

\d .
