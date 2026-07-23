
apman = require "apman"

collectd.register_read(apman.getCollectdStats)
