.PHONY: build release install clean docker-image

build:
	mush build

release:
	mush build --release

install:
	mush install --path .

clean:
	rm -rf target/

docker-image:
	docker build -t xgit/git-runtime .
