test:

	docker pull couchdb:3.0
	docker run -d --rm --name couchdb -e COUCHDB_USER=admin -e COUCHDB_PASSWORD=password couchdb:3.0
	docker build -t openresty .
	docker run -it --name openresty --link couchdb:openresty -v $(CURDIR):"/home/rogon/lua-resty-couchdb" openresty:latest /bin/bash
