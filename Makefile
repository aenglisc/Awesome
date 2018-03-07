install:
	mix deps.get
	cd assets && npm install

clean:
	rm -rf _build
	rm -rf assets/node_modules
	rm -rf deps
	rm -rf priv/static
	rm -rf rel

start:
	mix phx.server

build:
	cd assets && node_modules/brunch/bin/brunch build --production
	mix phx.digest
	mix release.init
	MIX_ENV=prod mix release --env=prod

start-prod-build:
	MY_HOSTNAME=example.com MY_COOKIE=secret REPLACE_OS_VARS=true MY_NODE_NAME=awesome@127.0.0.1 PORT=4000 _build/prod/rel/awesome/bin/awesome foreground

deploy:
	git -c http.extraheader="GIGALIXIR-HOT: true" push gigalixir master