install:
	mix deps.get
	cd assets && npm install

clean:
	rm -rf _build
	rm -rf assets/node_modules
	rm -rf deps
	rm -rf priv/static

start:
	mix phx.server