#lua-resty-couchdb
Lua resty minimal couchdb client using nginx proxy ngx.location_capture

#Installation
```
#luarocks install lua-resty-couchdb
```

#Usage
```
local couch   = require 'couchdb'
local config  = {
  username: 'admin',
  password: 'somepassword'
}

local couchdb = couch:new(config)
-- set database to use
couchdb:database('_users')
local res = couchdb:put(id, data)

```

### API
Please refer to the CouchDB API documentation at [docs.couchdb.org](http://docs.couchdb.org/en/1.6.1/http-api.html) for available
REST API.

#### configuration
This api should be called first to set the correct database parameter
before calling any database action method.
- host eg: https://192.168.1.5:5472
- username string
- password string


#### database(url)
Database name to query to
- database name eg: booking


#### get(id)
Get database value
- id document id
- return lua table

#### put(id, data)
Insert data to database
- id document id
- data *(table)* data to save

#### post(id, data)
Insert data to database
- id document id
- data *(table)* data to save


#### delete(id)
Delete data from database
- id document id

#### save(id, data)
Update existing data. This api will automatically get the latest rev to use for updating the data.
- id document id
- data *(table)* to save


#### view(design_name, view_name, opts)
Query rows of data using views
- design_name *(string)* couchdb design name
- view_name *(string)* couchdb view name
- opts *(table)* options parameter as [documented here](http://docs.couchdb.org/en/1.6.1/api/ddoc/views.html)



## Reference
- [CouchDB API](http://docs.couchdb.org/en/1.6.1/http-api.html)
- [CouchDB View Options](http://docs.couchdb.org/en/1.6.1/api/ddoc/views.html)
- [Request documentation](https://github.com/request/request)
