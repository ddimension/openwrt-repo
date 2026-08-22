# apman

The OpenWrt package. The agent it installs — the ubus↔MQTT bridge, the collectd
plugin, the on-AP RADIUS server and their documentation — lives in
[ddimension/apman-agent](https://github.com/ddimension/apman-agent); this
Makefile pins a commit of it.

To ship a change to the agent, work there and run `contrib/release.sh`. It
commits, pushes, computes the tarball hash OpenWrt will verify, writes commit
and hash into this Makefile, bumps the version and can roll the result onto a
development access point in the same run. Editing `PKG_SOURCE_VERSION` here by
hand means computing `PKG_MIRROR_HASH` by hand as well — the script exists so
that the two cannot drift apart.
