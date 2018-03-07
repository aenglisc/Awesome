install:
	mix deps.get
	cd assets && npm install

clean:
	rm -rf _build
	rm -rf assets/node_modules
	rm -rf deps
	rm -rf priv/static
	rm -rf rel

build:
	cd assets && node_modules/brunch/bin/brunch build --production
	mix phx.digest
	mix release.init
	MIX_ENV=prod mix release --env=prod

start:
	mix phx.server