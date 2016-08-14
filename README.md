#lua-resty-couchdb
Lua resty minimal couchdb client

#Installation
```
#luarocks install lua-resty-couchdb
```

#Usage
```
local couch = require 'couchdb'
couchdb:database('_users')
local res = couchdb.put(id, data)
```

### API
All method is basically a very light [request](https://www.npmjs.com/package/request) abstraction and every call will
return the same request object. All method from [request](https://www.npmjs.com/package/request) module is available.
Please refer the CouchDB API documentation at [docs.couchdb.org](http://docs.couchdb.org/en/1.6.1/http-api.html) for available
REST API.

#### configuration
```javascript
const couchdb = require('couchdb-request')(opts)
```
This api should be called first to set the correct database parameter
before calling any database action method.
- opts full url sytax eg: https://admin:password@localhost:5984


#### database(url)
Database name to query to
- database name eg: booking


#### get(id, [callback])
Get database value
- id document id
- callback *(optional)* function to execute after request complete


#### put(id, data, [callback])
Insert data to database
- id document id
- data *(json)* object data to save
- callback *(optional)* function to execute after request complete

#### post(id, data, [callback])
Insert data to database
- id document id
- data *(json)* object data to save
- callback *(optional)* function to execute after request complete


#### del(id, callback)
Delete data from database
- id document id
- data *(json)* object to save 
- callback function to execute after request complete

#### save(id, data, callback)
Update existing data. This api will automatically get the latest rev to use for updating the data.
- id document id
- data *(json)* object to save
- callback function to execute after request complete


#### view(design, opts, [callback])
Query rows of data using views
- id view id
- opts *(json)* options parameter as [documented here](http://docs.couchdb.org/en/1.6.1/api/ddoc/views.html)
- callback *(optional)* function to execute after request complete

  host: 'https://202.48.84.8:5472',
  username: 'admin',
  password: 'somepassword'
})


