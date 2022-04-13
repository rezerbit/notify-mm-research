up:
	cp -r volumes.seeds volumes
	docker-compose up -d

down:
	docker-compose down
	rm -fr volumes